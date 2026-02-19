#!/bin/bash
set -e

# 컨테이너 엔진 감지
if docker info >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
elif podman info >/dev/null 2>&1; then
    CONTAINER_ENGINE="podman"
else
    echo "오류: Docker 또는 Podman을 찾을 수 없습니다."
    exit 1
fi

# 1. 모든 네임스페이스 생성
namespaces=(
  "production-tier" "secure-db" "security-audit" "logging-namespace" 
  "critical-apps" "app-tier" "finance-batch" "multi-app" 
  "secure-compute" "storage-expansion" "app-stack" "hardened-app" 
  "deployment-strategy" "scaling-system" "batch-world"
)

for ns in "${namespaces[@]}"; do
  kubectl create ns $ns --dry-run=client -o yaml | kubectl apply -f -
done

# 2. 문제별 기초 리소스 생성
kubectl apply -f - <<EOF
# [Problem 8] Ingress 테스트용 서비스
apiVersion: v1
kind: Service
metadata:
  name: svc-1
  namespace: multi-app
spec:
  ports: [{port: 80}]
  selector: {app: svc-1}
---
apiVersion: v1
kind: Service
metadata:
  name: svc-2
  namespace: multi-app
spec:
  ports: [{port: 80}]
  selector: {app: svc-2}
---
# [Problem 10] PVC 확장 테스트용 리소스
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage-expansion
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
  namespace: storage-expansion
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
---
# [Problem 11] 트러블슈팅: 잘못된 ConfigMap 참조
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: app-stack
data:
  correct-key: "working"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  namespace: app-stack
spec:
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      containers:
      - name: web
        image: nginx
        env:
        - name: APP_CONFIG
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: wrong-key # 의도적인 오류
---
# [Problem 13] 블루-그린 배포
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-blue
  namespace: deployment-strategy
spec:
  replicas: 2
  selector:
    matchLabels: {app: my-app, version: blue}
  template:
    metadata:
      labels: {app: my-app, version: blue}
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-green
  namespace: deployment-strategy
spec:
  replicas: 2
  selector:
    matchLabels: {app: my-app, version: green}
  template:
    metadata:
      labels: {app: my-app, version: green}
    spec:
      containers:
      - name: nginx
        image: nginx:1.26
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: deployment-strategy
spec:
  selector: {app: my-app, version: blue}
  ports: [{port: 80}]
---
# [Problem 2] NetworkPolicy 테스트용 DB 파드 및 서비스
apiVersion: v1
kind: Pod
metadata:
  name: db-pod
  namespace: secure-db
  labels: {app: database}
spec:
  containers:
  - name: db
    image: busybox
    command: ["sh", "-c", "nc -lk -p 5432 -e echo 'DB Connection Successful'"]
---
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: secure-db
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: database
---
# [Problem 8] Ingress 테스트용 백엔드 파드
apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc-1-backend
  namespace: multi-app
spec:
  selector:
    matchLabels: {app: svc-1}
  template:
    metadata:
      labels: {app: svc-1}
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc-2-backend
  namespace: multi-app
spec:
  selector:
    matchLabels: {app: svc-2}
  template:
    metadata:
      labels: {app: svc-2}
    spec:
      containers:
      - name: nginx
        image: nginx
---
# [Problem 14] HPA 테스트용 Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: scaling-system
spec:
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
EOF

# [Problem 9] 노드 레이블링 및 테인팅 (전략: 첫 번째 워커 노드 선택)
WORKER_NODE=$(kubectl get nodes -l kubernetes.io/role!=control-plane -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$WORKER_NODE" ]; then
  kubectl label node $WORKER_NODE dedicated=secure --overwrite
  kubectl taint node $WORKER_NODE dedicated=secure:NoSchedule --overwrite
  echo "Node $WORKER_NODE 에 레이블과 테인트를 추가했습니다."
fi

echo "준비 완료: 모든 네임스페이스와 기초 리소스가 생성되었습니다."

#!/bin/bash

# 1. 모든 네임스페이스 생성
namespaces=(
  "production-webapp" "batch-processing" "ci-cd-pipeline" 
  "database-tier" "backend-tier" "secure-api" "hardened-apps" 
  "infra-monitoring" "migration-test" "resource-mgmt" "log-analysis" 
  "traffic-mgmt" "svc-discovery" "update-strategy" "storage-layer" 
  "availability-test" "config-db" "web-server-prod"
)

for ns in "${namespaces[@]}"; do
  kubectl create ns $ns --dry-run=client -o yaml | kubectl apply -f -
done

# 2. 문제별 기초 리소스 생성
kubectl apply -f - <<EOF
# [Problem 1] Canary Deployment 배경: v1 배포 및 서비스
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: production-webapp
spec:
  replicas: 9
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
        version: v1
    spec:
      containers:
      - name: nginx
        image: httpd:2.4
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: production-webapp
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 80
---
# [Problem 4] Network Policy 배경: DB 파드 및 제한 정책
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-access-policy
  namespace: database-tier
spec:
  podSelector:
    matchLabels:
      app: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: db-client
---
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: database-tier
  labels:
    app: database
spec:
  containers:
  - name: db
    image: redis
---
# [Problem 9] Resource Quota 설정
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-demo
  namespace: resource-mgmt
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
---
# [Problem 10] Multi-container Pod (Error 로그 발생기)
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
  namespace: log-analysis
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo 'App is running'; sleep 10; done"]
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "while true; do echo 'ERROR: Connection failed at \$(date)'; sleep 5; done"]
---
# [Problem 11] Ingress용 서비스 미리 생성
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: traffic-mgmt
spec:
  ports: [{port: 80}]
  selector: {app: api}
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: traffic-mgmt
spec:
  ports: [{port: 80}]
  selector: {app: web}
---
# [Problem 12] Label 불일치 상황 (Troubleshooting용)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deploy
  namespace: svc-discovery
spec:
  selector:
    matchLabels:
      app: backend-v1
  template:
    metadata:
      labels:
        app: backend-v1
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: svc-discovery
spec:
  selector:
    app: frontend-v1 # 의도적인 불일치
  ports:
  - port: 80
---
# [Problem 13] 롤링 업데이트용 구버전 Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  namespace: update-strategy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
EOF

# [Problem 3] Dockerfile 생성
cat <<EOF > Dockerfile
FROM alpine
ARG VERSION
ENV APP_VERSION=\$VERSION
RUN echo "Building version \$APP_VERSION"
EOF

# [Problem 8] 구형 API 버전 파일 생성
cat <<EOF > old-deploy.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: old-app
  namespace: migration-test
spec:
  template:
    metadata:
      labels:
        app: old-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
EOF

# [Problem 14, 15, 16] PVC, ReadinessProbe, ConfigMap 문제 해결을 위한 기초 리소스
kubectl apply -f - <<EOF
# [Problem 14] PVC 연결을 위한 Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-app
  namespace: storage-layer
spec:
  selector:
    matchLabels:
      app: storage
  template:
    metadata:
      labels:
        app: storage
    spec:
      containers:
      - name: nginx
        image: nginx
---
# [Problem 15] Readiness Probe 설정을 위한 Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ready-check-app
  namespace: availability-test
spec:
  selector:
    matchLabels:
      app: ready-check
  template:
    metadata:
      labels:
        app: ready-check
    spec:
      containers:
      - name: web
        image: nginx
---
# [Problem 16] ConfigMap 마운트를 위한 Pod
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: config-db
spec:
  containers:
  - name: db-app
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
EOF

echo "준비 완료: 모든 네임스페이스와 기초 리소스가 생성되었습니다."

# Problem 8: API Version Upgrade (Create old-deploy.yaml)
# Overwriting any previous old-deploy.yaml
cat <<YAML > old-deploy.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: old-app
  namespace: migration-test
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: old-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
YAML
echo "Created old-deploy.yaml for Problem 8"

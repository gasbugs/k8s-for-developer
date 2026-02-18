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

# 1.1 로컬 레지스트리 구성 (Problem 3용)
if [ $(docker ps -q -f name=ckad-registry | wc -l) -eq 0 ]; then
  if [ $(docker ps -aq -f name=ckad-registry | wc -l) -eq 1 ]; then
    docker rm -f ckad-registry
  fi
  docker run -d --name ckad-registry -p 5000:5000 registry:2
  echo "로컬 레지스트리(ckad-registry)가 시작되었습니다."
else
  echo "로컬 레지스트리(ckad-registry)가 이미 실행 중입니다."
fi

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
    - namespaceSelector: {}
      podSelector:
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
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: database-tier
spec:
  selector:
    app: database
  ports:
  - port: 6379
    targetPort: 6379
---
# [Problem 9] Resource Quota 설정
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-demo
  namespace: resource-mgmt
spec:
  hard:
    requests.cpu: "0.2"
    requests.memory: 200Mi
    limits.cpu: "0.5"
    limits.memory: 500Mi
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
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: traffic-mgmt
spec:
  ports: [{port: 80}]
  selector: {app: api}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-app
  namespace: traffic-mgmt
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginx
        command: ["/bin/sh", "-c", "mkdir -p /usr/share/nginx/html/api && echo 'API Backend' > /usr/share/nginx/html/api/index.html && nginx -g 'daemon off;'"]
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: traffic-mgmt
spec:
  replicas: 1
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
        image: nginx
        command: ["/bin/sh", "-c", "echo 'Web Backend' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
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
        command: ["/bin/sh", "-c", "echo 'Backend Connected' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
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
RUN echo \$VERSION > /version
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
        command: ["/bin/sh", "-c", "sed -i 's/80;/8080;/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
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
---
# [Problem 4] Network Policy 테스트용 Pod (backend-tier)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: backend-tier
spec:
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api-server
        image: nginx
---
# [Problem 5] Secret 환경변수 주입용 Deployment (secure-api)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: secure-api
spec:
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api-server
        image: nginx
---
# [Problem 6] Security Context 설정을 위한 Pod (hardened-apps)
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: hardened-apps
spec:
  containers:
  - name: web-app
    image: nginx
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

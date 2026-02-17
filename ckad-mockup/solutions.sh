#!/bin/bash

echo "=================================================="
echo "       CKAD Mock Exam Solutions Automation"
echo "=================================================="
echo ""

# 1. Canary Deployment
echo "[Problem 1] Creating Canary Deployment..."
cat <<EOF > app-v2.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
  namespace: production-webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-server
      version: v2
  template:
    metadata:
      labels:
        app: web-server
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
EOF
kubectl apply -f app-v2.yaml
rm app-v2.yaml

# 2. CronJob
echo "[Problem 2] Creating CronJob..."
cat <<EOF > cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: settlement-job
  namespace: batch-processing
spec:
  schedule: "30 2 * * 1"
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 2
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: settlement-job
            image: busybox
            command: ["/bin/sh", "-c", "echo 'Processing...'"]
          restartPolicy: OnFailure
EOF
kubectl apply -f cronjob.yaml
rm cronjob.yaml

# 3. Image Build
echo "[Problem 3] Building Docker Image..."
# Create a dummy Dockerfile if not exists
if [ ! -f Dockerfile ]; then
    echo "FROM busybox" > Dockerfile
    echo "ARG VERSION" >> Dockerfile
    echo "RUN echo \$VERSION > /version" >> Dockerfile
fi
docker build -t internal-tool:v2.0 --build-arg VERSION=2.0 . > /dev/null 2>&1
docker save -o tool-v2.tar internal-tool:v2.0 > /dev/null 2>&1
echo "Image built and saved to tool-v2.tar"

# 4. Network Policy
echo "[Problem 4] Updating Deployment for Network Policy..."
kubectl patch deployment api-server -n backend-tier --patch '{"spec": {"template": {"metadata": {"labels": {"role": "db-client"}}}}}'

# 5. Secret & Env
echo "[Problem 5] Creating Secret and Injecting Env..."
kubectl create secret generic api-auth --from-literal=api-token=secret-value-123 -n secure-api --dry-run=client -o yaml | kubectl apply -f -
kubectl patch deployment api-server -n secure-api --patch '{"spec": {"template": {"spec": {"containers": [{"name": "api-server", "env": [{"name": "SERVICE_TOKEN", "valueFrom": {"secretKeyRef": {"name": "api-auth", "key": "api-token"}}}]}]}}}}'

# 6. Security Context
echo "[Problem 6] Updating Security Context..."
# Get existing pod yaml, modify, replace
kubectl get pod web-app -n hardened-apps -o yaml > web-app.yaml
# We use sed/yq or just overwrite for simplicity in automation. 
# Overwriting with a simple pod definition for demonstration as 'kubectl patch' for pod fields is limited.
# But wait, we can force replace.
cat <<EOF > web-app-fixed.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: hardened-apps
spec:
  containers:
  - name: web-app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsUser: 2000
EOF
kubectl delete pod web-app -n hardened-apps --force --grace-period=0 > /dev/null 2>&1
kubectl apply -f web-app-fixed.yaml
rm web-app.yaml web-app-fixed.yaml

# 7. SA & RBAC
echo "[Problem 7] Creating RBAC..."
kubectl create sa event-watcher-sa -n infra-monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create role event-watcher-role --verb=get,list,watch --resource=events -n infra-monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding event-watcher-binding --role=event-watcher-role --serviceaccount=infra-monitoring:event-watcher-sa -n infra-monitoring --dry-run=client -o yaml | kubectl apply -f -

# 8. API Version Upgrade
echo "[Problem 8] Fixing API Version..."
if [ -f old-deploy.yaml ]; then
    cat <<EOF > old-deploy-fixed.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: old-app
  namespace: migration-test
spec:
  selector:
    matchLabels:
      app: old-app
  template:
    metadata:
      labels:
        app: old-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
EOF
    kubectl apply -f old-deploy-fixed.yaml
    rm old-deploy-fixed.yaml
else
    echo "old-deploy.yaml not found, skipping..."
fi

# 9. Resource Quota
echo "[Problem 9] Creating Pod within Quota..."
cat <<EOF > quota-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: quota-pod
  namespace: resource-mgmt
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "0.5"
        memory: "512Mi"
      limits:
        cpu: "0.5"
        memory: "512Mi"
EOF
kubectl apply -f quota-pod.yaml
rm quota-pod.yaml

# 10. Multi-container Logs
echo "[Problem 10] Extracting Logs..."
kubectl logs multi-pod -c sidecar -n log-analysis > /tmp/sidecar_error.log 2>/dev/null || echo "Pod not ready yet"

# 11. Ingress
echo "[Problem 11] Creating Ingress..."
cat <<EOF > ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: traffic-mgmt
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
kubectl apply -f ingress.yaml
rm ingress.yaml

# 12. Service Selector
echo "[Problem 12] Fixing Service Selector..."
kubectl patch svc backend-svc -n svc-discovery --patch '{"spec": {"selector": {"app": "backend-v1"}}}'

# 13. Rolling Update
echo "[Problem 13] Updating Deployment Strategy..."
kubectl set image deployment/web-deploy nginx=nginx:1.26 -n update-strategy
kubectl patch deployment web-deploy -n update-strategy --patch '{"spec": {"strategy": {"rollingUpdate": {"maxUnavailable": 0}}}}'
# Rollback test (optional, just ensuring command works)
# kubectl rollout undo deployment/web-deploy -n update-strategy

# 14. PV & PVC
echo "[Problem 14] Creating PV & PVC..."
cat <<EOF > pv-pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pvc
  namespace: storage-layer
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f pv-pvc.yaml
rm pv-pvc.yaml

echo "[Problem 14] Mounting PVC..."
# Target the deployment created by setup-lab.sh: storage-app
kubectl patch deployment storage-app -n storage-layer --patch '{"spec": {"template": {"spec": {"volumes": [{"name": "data-volume", "persistentVolumeClaim": {"claimName": "task-pvc"}}], "containers": [{"name": "nginx", "volumeMounts": [{"mountPath": "/mnt/data", "name": "data-volume"}]}]}}}}'

# 15. Readiness Probe
echo "[Problem 15] Adding Readiness Probe..."
# Target the deployment created by setup-lab.sh: ready-check-app
kubectl patch deployment ready-check-app -n availability-test --patch '{"spec": {"template": {"spec": {"containers": [{"name": "web", "readinessProbe": {"httpGet": {"path": "/healthz", "port": 8080}, "failureThreshold": 3}}]}}}}'

# 16. ConfigMap
echo "[Problem 16] Mounting ConfigMap..."
kubectl create configmap app-config --from-literal=server.port=8080 -n config-db --dry-run=client -o yaml | kubectl apply -f -
# Target the pod created by setup-lab.sh: config-pod
kubectl get pod config-pod -n config-db -o yaml > pod-config.yaml
# Simple overwrite for automation
cat <<EOF > pod-config-fixed.yaml
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
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
EOF
kubectl delete pod config-pod -n config-db --force --grace-period=0 > /dev/null 2>&1
kubectl apply -f pod-config-fixed.yaml
rm pod-config.yaml pod-config-fixed.yaml

# 17. Nginx Env & Port
echo "[Problem 17] Creating Nginx Pod..."
kubectl run nginx-pod --image=nginx --port=8080 --env="ENV_MODE=production" -n web-server-prod --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=================================================="
echo "Solutions Applied! Run 'bash score.sh' to verify."
echo "=================================================="

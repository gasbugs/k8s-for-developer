# **쿠버네티스 실무 실습 - 고급 과정 솔루션 (ckad-mockup-2)**

### **1. 무중단 롤링 업데이트 및 롤백 (Rolling Update & Rollback)**

```bash
# 1. Deployment 생성 및 업데이트 전략 설정
kubectl create deploy advanced-web -n production-tier --image=nginx:1.20 --replicas=5

# 롤링 업데이트 설정 수정
kubectl patch deploy advanced-web -n production-tier -p '{"spec": {"strategy": {"rollingUpdate": {"maxSurge": 1, "maxUnavailable": 0}}}}'

# 2. 이미지 업데이트
kubectl set image deployment/advanced-web nginx=nginx:1.26 -n production-tier

# 3. 상태 확인 및 롤백
kubectl rollout status deployment/advanced-web -n production-tier
kubectl rollout history deployment/advanced-web -n production-tier
kubectl rollout undo deployment/advanced-web -n production-tier
```

### **2. 엄격한 네트워크 보안 정책 (Isolated Network Policy)**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: strict-db-policy
  namespace: secure-db
spec:
  podSelector: {} # 모든 파드 선택
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api-backend
    ports:
    - protocol: TCP
      port: 5432
  egress: [] # 모든 트래픽 차단 (Egress 필드가 존재하지만 비어있음)
```

### **3. 복합 리소스 권한 제어 (RBAC Role & Binding)**

```bash
# 1. SA 생성
kubectl create sa audit-viewer-sa -n security-audit

# 2. Role 생성 (ConfigMaps, Secrets 모두 포함)
kubectl create role audit-viewer-role -n security-audit --verb=get,list --resource=configmaps,secrets

# 3. RoleBinding 생성
kubectl create rolebinding audit-viewer-binding -n security-audit --role=audit-viewer-role --serviceaccount=security-audit:audit-viewer-sa
```

### **4. 복합 컨테이너 파드 및 공유 볼륨 (Multi-Container & Shared Volume)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-handler
  namespace: logging-namespace
spec:
  containers:
  - name: app-container
    image: busybox
    command: ["sh", "-c", "while true; do echo $(date) >> /var/log/app.log; sleep 5; done"]
    volumeMounts:
    - name: log-vol
      mountPath: /var/log
  - name: adapter-container
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/app.log"]
    volumeMounts:
    - name: log-vol
      mountPath: /var/log
  volumes:
  - name: log-vol
    emptyDir: {}
```

### **5. 리소스 제한 및 우선순위 관리 (Resource Quota & Priority)**

```bash
# 1. ResourceQuota 생성
kubectl create resourcequota cpu-limit-quota -n critical-apps --hard=limits.cpu=1000m

# 2. 파드 생성
kubectl run critical-pod -n critical-apps --image=nginx --requests=cpu=200m --limits=cpu=500m
```

### **6. Readiness & Liveness Probe 복합 설정**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-check-app
  namespace: app-tier
spec:
  selector:
    matchLabels: {app: health-check}
  template:
    metadata:
      labels: {app: health-check}
    spec:
      containers:
      - name: nginx
        image: nginx
        ports: [{containerPort: 8080}]
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 5
          failureThreshold: 3
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
          failureThreshold: 3
```

### **7. 크론잡 동시성 제어 및 재시도 제한 (CronJob)**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-cronjob
  namespace: finance-batch
spec:
  schedule: "0 * * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      backoffLimit: 3
      template:
        spec:
          containers:
          - name: busybox
            image: busybox
            command: ["sh", "-c", "echo Backup started; sleep 30"]
          restartPolicy: OnFailure
```

### **8. 인그레스 경로 재작성 및 멀티 서비스 (Ingress)**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: multi-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: traefik
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: svc-1
            port: {number: 80}
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: svc-2
            port: {number: 80}
```

### **9. 노드 어피니티 및 테인트 수용 (Node Affinity & Tolerations)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-workload
  namespace: secure-compute
spec:
  containers:
  - name: nginx
    image: nginx
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: dedicated
            operator: In
            values: ["secure"]
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "secure"
    effect: "NoSchedule"
```

### **10. PVC 동적 프로비저닝 및 볼륨 확장 (PVC Expansion)**

```bash
# PVC 용량 수정
kubectl patch pvc data-pvc -n storage-expansion -p '{"spec": {"resources": {"requests": {"storage": "100Mi"}}}}'
```

### **11. 트러블슈팅: 잘못된 컨피그맵 참조 수정**

```bash
# 1. 원인 진단
kubectl describe pod -n app-stack -l app=web
# 2. Deployment 수정 (env 필드의 key를 correct-key로 변경)
kubectl edit deploy web-deploy -n app-stack
```

### **12. 보안 강화: 읽기 전용 파일시스템 적용 (ReadOnlyRootFilesystem)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readonly-pod
  namespace: hardened-app
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: cache-vol
      mountPath: /var/cache/nginx
  volumes:
  - name: cache-vol
    emptyDir: {}
```

### **13. 블루-그린 배포 수동 전환 (Blue-Green Switch)**

```bash
# 서비스 셀렉터 업데이트
kubectl patch svc my-service -n deployment-strategy -p '{"spec": {"selector": {"version": "green"}}}'
```

### **14. HPA를 이용한 자동 스케일링 (Horizontal Pod Autoscaler)**

```bash
kubectl autoscale deployment web-app -n scaling-system --cpu-percent=50 --min=2 --max=10
```

### **15. 병렬 잡 수행 및 완료 보장 (Parallel Jobs)**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processor
  namespace: batch-world
spec:
  completions: 10
  parallelism: 3
  template:
    spec:
      containers:
      - name: busybox
        image: busybox
        command: ["sh", "-c", "echo Processing node; sleep 5"]
      restartPolicy: Never
```
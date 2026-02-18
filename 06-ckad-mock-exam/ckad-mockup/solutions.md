# **쿠버네티스 & 컨테이너 실무 실습 17제 풀이 (Solutions)**

이 문서는 `problems.md`에 제시된 문제들에 대한 예시 풀이를 제공합니다. 실제 시험 환경이나 클러스터 설정에 따라 세부 내용은 달라질 수 있습니다.

> **💡 팁:** 시험에서는 `kubectl` 명령어를 통해 뼈대를 생성하고(`--dry-run=client -o yaml`), 부족한 부분은 **Kubernetes 공식 문서**에서 검색하여 보완하는 방식이 가장 효율적입니다. 아래 풀이는 공식 문서를 활용하는 방법에 중점을 둡니다.

---

### **1. 카나리 배포 (Canary Deployment) 수행 🐤**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `Deployment`
    - 문서: [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
    - 예제 YAML을 복사하여 `app-v2.yaml` 파일을 생성합니다.

2.  `app-v2.yaml` 수정:
    - `replicas`를 `1`로 설정.
    - `selector.matchLabels`와 `template.metadata.labels`에 `app: web-server`, `version: v2` 추가.
    - `image`를 `nginx:1.25`로 변경.

    **최종 YAML 예시:**
    ```yaml
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
    ```

3.  적용:
    ```bash
    kubectl apply -f app-v2.yaml
    ```

**검증 (Validation):**
```bash
# 엔드포인트에 v2 파드가 포함되었는지 확인
kubectl get ep my-app-service -n production-webapp

# 트래픽 분산 확인 (Apache/v1과 Nginx/v2가 번갈아 응답하는지 확인)
# app-v1 파드 중 하나를 빌려 테스트 수행
kubectl exec -n production-webapp deployment/app-v1 -- /bin/sh -c 'for i in $(seq 1 20); do curl -sI http://my-app-service | grep Server; done'
```

---

### **2. 크론잡 (CronJob) 고급 설정 ⏰**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `CronJob`
    - 문서: [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
    - 예제 YAML 복사하여 `cronjob.yaml` 생성.

2.  `cronjob.yaml` 수정:
    - `metadata.name`: `settlement-job`, `metadata.namespace`: `batch-processing`
    - `spec.schedule`: `"30 2 * * 1"`
    - `spec.successfulJobsHistoryLimit`: `5`
    - `spec.failedJobsHistoryLimit`: `2`
    - `spec` 내부 `containers` 수정: `image: busybox`, `command: ["/bin/sh", "-c", "echo 'Processing...'"]`

    **최종 YAML 예시:**
    ```yaml
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
    ```

3.  적용:
    ```bash
    kubectl apply -f cronjob.yaml
    ```

**검증 (Validation):**
```bash
kubectl describe cronjob settlement-job -n batch-processing | grep -E "Schedule|History Limit"
```

---

### **3. 이미지 빌드 및 아카이브 (Docker/Podman) 🐳**

**솔루션:**

*이 문제는 Kubernetes 리소스가 아닌 컨테이너 툴(Docker/Podman) 사용 능력을 평가합니다.*

1.  명령어 실행 (Docker 또는 Podman 사용):
    ```bash
    # 환경에 따라 docker 또는 podman 명령어를 사용하세요.
    ENGINE="docker" # 또는 "podman"
    
    # 빌드
    $ENGINE build -t internal-tool:v2.0 --build-arg VERSION=2.0 .
    
    # 로컬 레지스트리용 태그 설정
    $ENGINE tag internal-tool:v2.0 localhost:5000/internal-tool:v2.0
    
    # 푸시
    $ENGINE push localhost:5000/internal-tool:v2.0

    # 이미지 아카이브 저장
    $ENGINE save -o tool-v2.tar internal-tool:v2.0
    ```

**검증 (Validation):**
```bash
# 레지스트리 API를 통한 이미지 및 태그 확인
curl -s http://localhost:5000/v2/internal-tool/tags/list

# tar 파일 생성 확인
ls -lh tool-v2.tar

# 이미지 내부 버전 확인
$ENGINE run --rm internal-tool:v2.0 cat /version
```

---

### **4. 네트워크 정책 (Network Policy) 해결 🛡️**

**솔루션:**

1.  Kubernetes 공식 문서 검색 (개념 확인):
    - 검색어: `NetworkPolicy`
    - 문서: [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
    - `podSelector`와 `ingress` 규칙 파악.

2.  Deployment 수정:
    ```bash
    kubectl edit deployment api-server -n backend-tier
    ```
    - `spec.template.metadata.labels`에 `role: db-client` 추가.

    **YAML 변경 부분:**
    ```yaml
    spec:
      template:
        metadata:
          labels:
            app: api-server
            role: db-client # 추가
    ```

**검증 (Validation):**
```bash
# 레이블 확인
kubectl get pods -n backend-tier --show-labels | grep db-client

# 실제 통신 확인 (database-tier의 database 서비스로 연결 테스트)
kubectl exec -n backend-tier deployment/api-server -- /usr/bin/bash -c 'timeout 2 bash -c "true > /dev/tcp/database.database-tier.svc.cluster.local/6379"' && echo "Connectivity Success"
```

---

### **5. 시크릿(Secret) 생성 및 환경 변수 주입 🔐**

**솔루션:**

1.  Secret 생성 (Imperative):
    ```bash
    kubectl create secret generic api-auth --from-literal=api-token=secret-value-123 -n secure-api
    ```

2.  Deployment 수정:
    ```bash
    kubectl edit deployment api-server -n secure-api
    ```
    - `spec.template.spec.containers[].env` 추가.

    **YAML 변경 부분:**
    ```yaml
    env:
      - name: SERVICE_TOKEN
        valueFrom:
          secretKeyRef:
            name: api-auth
            key: api-token
    ```

**검증 (Validation):**
```bash
kubectl exec -n secure-api deploy/api-server -- env | grep SERVICE_TOKEN
```

---

### **6. 보안 문맥 (Security Context) 강화 🔒**

**솔루션:**

1.  파드 YAML 수정:
    - 현재 파드 설정 저장: `kubectl get pod web-app -n hardened-apps -o yaml > web-app.yaml`
    - 파드 삭제: `kubectl delete pod web-app -n hardened-apps`
    - `web-app.yaml` 수정 (`securityContext` 필드 추가).

    **YAML 변경 부분:**
    ```yaml
    spec:
      containers:
      - name: web-app
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 2000
    ```

2.  적용:
    ```bash
    kubectl apply -f web-app.yaml
    ```

**검증 (Validation):**
```bash
kubectl get pod web-app -n hardened-apps -o jsonpath='{.spec.containers[0].securityContext}'
```

---

### **7. SA 및 RBAC 권한 할당 👤**

**솔루션:**

1.  리소스 생성 (Imperative):
    ```bash
    # ServiceAccount
    kubectl create sa event-watcher-sa -n infra-monitoring
    
    # Role
    kubectl create role event-watcher-role --verb=get,list,watch --resource=events -n infra-monitoring
    
    # RoleBinding
    kubectl create rolebinding event-watcher-binding --role=event-watcher-role --serviceaccount=infra-monitoring:event-watcher-sa -n infra-monitoring
    ```

    **참고: YAML로 생성 시 예시:**
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      namespace: infra-monitoring
      name: event-watcher-role
    rules:
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["get", "list", "watch"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: event-watcher-binding
      namespace: infra-monitoring
    subjects:
    - kind: ServiceAccount
      name: event-watcher-sa
      namespace: infra-monitoring
    roleRef:
      kind: Role
      name: event-watcher-role
      apiGroup: rbac.authorization.k8s.io
    ```

**검증 (Validation):**
```bash
kubectl auth can-i list events --as=system:serviceaccount:infra-monitoring:event-watcher-sa -n infra-monitoring
```

---

### **8. API 버전 업그레이드 (Deprecation) ⚠️**

**솔루션:**

1.  `old-deploy.yaml` 수정:
    - `apiVersion`을 `apps/v1`으로 변경.
    - `selector` 필드 추가.

    **YAML 변경 부분:**
    ```yaml
    apiVersion: apps/v1 # 수정
    kind: Deployment
    metadata:
      name: old-app
      namespace: migration-test
    spec:
      selector: # 추가
        matchLabels:
          app: old-app
      template:
        metadata:
          labels:
            app: old-app
    ```

2.  적용:
    ```bash
    kubectl apply -f old-deploy.yaml
    ```

**검증 (Validation):**
```bash
kubectl get deploy old-app -n migration-test
```

---

### **9. 리소스 쿼터(ResourceQuota) 관리 📊**

**솔루션:**

1.  ResourceQuota 확인:
    ```bash
    kubectl describe resourcequota mem-cpu-demo -n resource-mgmt
    ```
    - 출력 내용 중 `Requests`와 `Limits` 항목의 `Hard` 값을 확인합니다. (예: `requests.cpu: 0.2`, `requests.memory: 200Mi`, `limits.cpu: 0.5`, `limits.memory: 500Mi`)

2.  파드 YAML 작성 (`pod.yaml`):
    - 확인한 쿼터 값에 맞춰 (또는 그 이내로) 리소스를 설정합니다.

    **YAML 예시:**
    ```yaml
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
            cpu: "0.2"
            memory: "200Mi"
          limits:
            cpu: "0.5"
            memory: "500Mi"
    ```

3.  적용:
    ```bash
    kubectl apply -f pod.yaml
    ```

**검증 (Validation):**
```bash
# 파드 상태 및 리소스 설정 확인
kubectl describe pod quota-pod -n resource-mgmt
```

---

### **10. 멀티 컨테이너 로그 진단 📋**

**솔루션:**

1.  명령어 실행:
    ```bash
    kubectl logs multi-pod -c sidecar -n log-analysis > /tmp/sidecar_error.log
    ```

**검증 (Validation):**
```bash
cat /tmp/sidecar_error.log
```

---

### **11. 인그레스(Ingress) 경로 설정 🌐**

**솔루션:**

1.  `ingress.yaml` 작성:
    - `ingressClassName: traefik` 설정.
    - 경로 규칙(`rules`) 설정.

    **YAML 예시:**
    ```yaml
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
    ```

2.  적용:
    ```bash
    kubectl apply -f ingress.yaml
    ```

**검증 (Validation):**
```bash
kubectl describe ingress main-ingress -n traffic-mgmt
```

---

### **12. 서비스 레이블 수정 및 노출 🔗**

**솔루션:**

1.  서비스 수정:
    ```bash
    kubectl edit svc backend-svc -n svc-discovery
    ```

2.  `selector` 수정:

    **YAML 변경 부분:**
    ```yaml
    spec:
      selector:
        app: backend-v1 # 기존 값 수정
    ```

**검증 (Validation):**
```bash
# Endpoints 연결 확인
kubectl get ep backend-svc -n svc-discovery

# 실제 통신 확인 (동일 네임스페이스 내 파드에서 테스트)
kubectl exec -n svc-discovery deployment/backend-deploy -- curl -s http://backend-svc
# 결과에 'Backend Connected'가 출력되어야 함
```

---

### **13. 롤링 업데이트 및 롤백 전략 🔄**

**솔루션:**

1.  업데이트 실행:
    ```bash
    kubectl set image deployment/web-deploy nginx=nginx:1.26 -n update-strategy
    ```

2.  전략 수정 (RollingUpdate):
    ```bash
    kubectl edit deployment web-deploy -n update-strategy
    ```

    **YAML 변경 부분:**
    ```yaml
    spec:
      strategy:
        rollingUpdate:
          maxUnavailable: 0
    ```

3.  롤백:
    ```bash
    kubectl rollout undo deployment/web-deploy -n update-strategy
    ```

**검증 (Validation):**
```bash
kubectl rollout status deployment/web-deploy -n update-strategy
```

---

### **14. PV & PVC 스토리지 연결 💾**

**솔루션:**

1.  `pv.yaml`, `pvc.yaml` 작성:

    **PV 예시:**
    ```yaml
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
    ```

    **PVC 예시:**
    ```yaml
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
    ```

2.  Deployment 수정 (`kubectl edit deployment ...`):

    **YAML 변경 부분:**
    ```yaml
    spec:
      template:
        spec:
          volumes:
          - name: data-volume
            persistentVolumeClaim:
              claimName: task-pvc
          containers:
          - name: nginx
            volumeMounts:
            - mountPath: "/mnt/data"
              name: data-volume
    ```

3.  적용:
    ```bash
    kubectl apply -f pv.yaml
    kubectl apply -f pvc.yaml
    ```

**검증 (Validation):**
```bash
kubectl get pvc -n storage-layer
kubectl describe pod -n storage-layer | grep Mounts -A 2
```

---

### **15. Readiness Probe 상태 확인 🩺**

**솔루션:**

1.  Deployment 수정:
    ```bash
    kubectl edit deployment ready-check-app -n availability-test
    ```

2.  Probe 추가:

    **YAML 변경 부분:**
    ```yaml
    spec:
      template:
        spec:
          containers:
          - name: web
            readinessProbe:
              httpGet:
                path: /healthz
                port: 8080
              failureThreshold: 3
    ```

**검증 (Validation):**
```bash
# 프로브 설정 확인
kubectl describe deployment ready-check-app -n availability-test | grep Readiness

# 파드 준비 상태 확인 (Ready 1/1 확인)
kubectl get pods -n availability-test -l app=ready-check
```

---

### **16. 컨피그맵(ConfigMap) 볼륨 마운트 ⚙️**

**솔루션:**

1.  ConfigMap 생성:
    ```bash
    kubectl create configmap app-config --from-literal=server.port=8080 -n config-db
    ```

2.  Pod 수정 및 재성성:
    - Pod의 경우 실행 중인 상태에서 볼륨 수정을 지원하지 않으므로, YAML을 추출하여 수정한 뒤 재생성합니다.
    ```bash
    kubectl get pod config-pod -n config-db -o yaml > pod.yaml
    vi pod.yaml # spec.volumes 및 spec.containers.volumeMounts 추가
    kubectl delete pod config-pod -n config-db
    kubectl apply -f pod.yaml
    ```

    **YAML 변경 부분:**
    ```yaml
    spec:
      volumes:
      - name: config-volume
        configMap:
          name: app-config
      containers:
      - name: db-app
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
    ```

**검증 (Validation):**
```bash
# 마운트 및 파일 내용 확인
kubectl exec -n config-db config-pod -- cat /etc/config/server.port
# 결과로 '8080'이 출력되어야 함
```

---

### **17. Nginx 환경 설정 및 포트 노출 🌐**

**솔루션:**

1.  명령어 실행 (YAML 생성 없이 바로 실행):
    ```bash
    kubectl run nginx-pod --image=nginx --port=8080 --env="ENV_MODE=production" -n web-server-prod
    ```

2.  또는 YAML로 생성 시 (`kubectl run ... --dry-run=client -o yaml`):

    **YAML 예시:**
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-pod
      namespace: web-server-prod
    spec:
      containers:
      - name: nginx-pod
        image: nginx
        ports:
        - containerPort: 8080
        env:
        - name: ENV_MODE
          value: "production"
    ```

    **적용:**
    ```bash
    kubectl apply -f pod.yaml
    ```

**검증 (Validation):**
```bash
# 환경 변수 확인 (Pod 내부)
kubectl exec -n web-server-prod nginx-pod -- env | grep ENV_MODE

# 포트 설정 확인
kubectl get pod nginx-pod -n web-server-prod -o jsonpath='{.spec.containers[0].ports[0]}'
```

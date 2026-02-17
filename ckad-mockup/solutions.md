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
    - 복사한 YAML을 문제의 요구사항에 맞게 수정합니다.
    - `replicas`: `1`
    - `matchLabels` 및 `template.labels`: `app: web-server`, `version: v2` 추가
    - `image`: `nginx:1.25`

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
kubectl get pods -n production-webapp -l version=v2
kubectl get ep my-app-service -n production-webapp
```

---

### **2. 크론잡 (CronJob) 고급 설정 ⏰**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `CronJob`
    - 문서: [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
    - 예제 YAML 복사하여 `cronjob.yaml` 생성.

2.  `cronjob.yaml` 수정:
    - `metadata.name`: `settlement-job`
    - `metadata.namespace`: `batch-processing`
    - `spec.schedule`: `"30 2 * * 1"`
    - `spec.successfulJobsHistoryLimit`: `5`
    - `spec.failedJobsHistoryLimit`: `2`
    - `spec.jobTemplate.spec.template.spec.containers` 수정:
        - `image`: `busybox`
        - `command`: `["/bin/sh", "-c", "echo 'Processing...'"]`

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

1.  `docker build` 설명서 확인 (또는 `--help`):
    - `docker build --help`

2.  명령어 실행:
    ```bash
    # 빌드
    docker build -t internal-tool:v2.0 --build-arg VERSION=2.0 .
    
    # 아카이브 저장
    docker save -o tool-v2.tar internal-tool:v2.0
    ```

**검증 (Validation):**
```bash
ls -lh tool-v2.tar
```

---

### **4. 네트워크 정책 (Network Policy) 해결 🛡️**

**솔루션:**

1.  Kubernetes 공식 문서 검색 (개념 확인):
    - 검색어: `NetworkPolicy`
    - 문서: [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
    - 문서를 통해 `podSelector`와 `ingress` 규칙의 작동 방식을 이해합니다.

2.  기존 정책 확인:
    ```bash
    kubectl get netpol db-access-policy -n database-tier -o yaml
    ```
    - `spec.ingress.from.podSelector.matchLabels`에 `role: db-client`가 있는지 확인.

3.  파드(Deployment) 수정:
    - 문서에서 파드 레이블 수정 방법을 찾거나 `kubectl edit` 사용.
    ```bash
    kubectl edit deployment api-server -n backend-tier
    ```
    - `spec.template.metadata.labels`에 `role: db-client` 추가.

**검증 (Validation):**
```bash
kubectl get pods -n backend-tier --show-labels | grep db-client
```

---

### **5. 시크릿(Secret) 생성 및 환경 변수 주입 🔐**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `Secret`, `environment variable secret`
    - 문서: [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) -> "Using Secrets as environment variables" 섹션 참고.

2.  Secret 생성 (Imperative 방식 권장):
    ```bash
    kubectl create secret generic api-auth --from-literal=api-token=secret-value-123 -n secure-api
    ```

3.  Deployment 수정 (문서 예제 참고):
    - 문서에서 `valueFrom`, `secretKeyRef` 구문 복사.
    - `kubectl edit deployment api-server -n secure-api` 실행.
    - `env` 섹션 추가:
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

1.  Kubernetes 공식 문서 검색:
    - 검색어: `SecurityContext`
    - 문서: [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

2.  파드 YAML 수정:
    - 문서 예제를 참고하여 `securityContext` 필드 작성.
    - `kubectl get pod web-app -n hardened-apps -o yaml > web-app.yaml` 후 수정.
    ```yaml
    spec:
      containers:
      - name: web-app
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 2000
    ```
    - 기존 파드 삭제 후 재생성 (`kubectl replace --force -f web-app.yaml`).

**검증 (Validation):**
```bash
kubectl get pod web-app -n hardened-apps -o jsonpath='{.spec.containers[0].securityContext}'
```

---

### **7. SA 및 RBAC 권한 할당 👤**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `RBAC`
    - 문서: [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

2.  리소스 생성 (문서의 Role, RoleBinding 예제 활용 가능하지만, Imperative가 빠름):
    - **ServiceAccount:** `kubectl create sa event-watcher-sa -n infra-monitoring`
    - **Role:** `kubectl create role event-watcher-role --verb=get,list,watch --resource=events -n infra-monitoring`
    - **RoleBinding:** `kubectl create rolebinding event-watcher-binding --role=event-watcher-role --serviceaccount=infra-monitoring:event-watcher-sa -n infra-monitoring`

    *문서 활용시:* YAML 예제를 복사하여 `subjects`(ServiceAccount), `roleRef`(Role), `rules`(resources, verbs) 부분을 수정.

**검증 (Validation):**
```bash
kubectl auth can-i list events --as=system:serviceaccount:infra-monitoring:event-watcher-sa -n infra-monitoring
```

---

### **8. API 버전 업그레이드 (Deprecation) ⚠️**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `Deployment`
    - 문서의 최상단에서 현재 지원되는 `apiVersion` 확인 (`apps/v1`).
    - `apps/v1` Deployment 스펙에서 `selector`가 필수인지 확인.

2.  `old-deploy.yaml` 수정:
    - `apiVersion: apps/v1`으로 변경.
    - `spec.selector` 추가 (문서 예제 참고):
      ```yaml
      selector:
        matchLabels:
          app: old-app
      ```

3.  적용:
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

1.  Quota 확인:
    ```bash
    kubectl describe resourcequota -n resource-mgmt
    ```

2.  Kubernetes 공식 문서 검색:
    - 검색어: `Resource Quota` 또는 `Pod resource limits`
    - 문서: [Manage Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
    - 예제 YAML 복사.

3.  파드 YAML 작성:
    - 복사한 예제에서 `resources.requests`와 `limits` 섹션을 수정.
    - `memory: "512Mi"`, `cpu: "0.5"` (1Gi, 1CPU의 50%).

4.  적용:
    ```bash
    kubectl apply -f pod.yaml
    ```

**검증 (Validation):**
```bash
kubectl get pod quota-pod -n resource-mgmt
```

---

### **10. 멀티 컨테이너 로그 진단 📋**

**솔루션:**

1.  `kubectl logs` 도움말 확인:
    - `kubectl logs --help`
    - 멀티 컨테이너 파드의 경우 `-c` 옵션 사용법 확인.

2.  명령어 실행:
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

1.  Kubernetes 공식 문서 검색:
    - 검색어: `Ingress`
    - 문서: [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
    - "Minimal Ingress resource" 또는 "Simple fanout" 예제 YAML 복사.

2.  `ingress.yaml` 작성 및 수정:
    - `metadata.name`, `namespace` 설정.
    - `spec.ingressClassName: nginx` 추가.
    - `rules` 섹션 수정:
      ```yaml
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

3.  적용:
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

1.  Kubernetes 공식 문서 검색 (Service 정의 확인):
    - 검색어: `Service`
    - 문서: [Service](https://kubernetes.io/docs/concepts/services-networking/service/) -> "Defining a Service" 섹션.
    - `selector`가 파드의 레이블과 일치해야 함을 확인.

2.  상태 확인 및 수정:
    - 파드 레이블 확인: `kubectl get pod -n svc-discovery --show-labels`
    - 서비스 수정: `kubectl edit svc backend-svc -n svc-discovery`
    - `selector` 값을 파드 레이블과 일치시킴 (`app: backend-v1`).

**검증 (Validation):**
```bash
kubectl get ep backend-svc -n svc-discovery
```

---

### **13. 롤링 업데이트 및 롤백 전략 🔄**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `Rolling Update`, `Deployment strategy`
    - 문서: [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) -> "Rolling Update Deployment" 섹션.

2.  업데이트 실행:
    ```bash
    kubectl set image deployment/web-deploy nginx=nginx:1.26 -n update-strategy
    ```

3.  전략 수정 (YAML 문서 예제 참고):
    ```bash
    kubectl edit deployment web-deploy -n update-strategy
    ```
    - `spec.strategy` 부분 수정:
      ```yaml
      strategy:
        rollingUpdate:
          maxUnavailable: 0
      ```

4.  롤백:
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

1.  Kubernetes 공식 문서 검색:
    - 검색어: `PersistentVolume`
    - 문서: [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
    - PV 및 PVC 예제 YAML 복사.

2.  YAML 작성:
    - `pv.yaml`: `capacity`, `accessModes`, `hostPath` 수정.
    - `pvc.yaml`: `resources.requests.storage`, `accessModes` 수정.

3.  Deployment 마운트 (문서의 "Mounting PVC" 섹션 참고):
    - `kubectl edit deployment ...`
    - `volumes`에 PVC 지정, `containers.volumeMounts`에 경로 지정.

**검증 (Validation):**
```bash
kubectl get pvc -n storage-layer
kubectl describe pod -n storage-layer | grep Mounts -A 2
```

---

### **15. Readiness Probe 상태 확인 🩺**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `ReadinessProbe`
    - 문서: [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
    - "Define a readiness HTTP request" 섹션의 YAML 예제 참고.

2.  Deployment 수정:
    - `kubectl edit deployment ...`
    - `readinessProbe` 섹션 추가:
      ```yaml
      readinessProbe:
        httpGet:
          path: /healthz
          port: 8080
        failureThreshold: 3
      ```

**검증 (Validation):**
```bash
kubectl get deploy -n availability-test -o yaml | grep readinessProbe -A 5
```

---

### **16. 컨피그맵(ConfigMap) 볼륨 마운트 ⚙️**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 검색어: `ConfigMap`
    - 문서: [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) -> "Use a ConfigMap as a file from a Pod" 예제 참고.

2.  ConfigMap 생성:
    ```bash
    kubectl create configmap app-config --from-literal=server.port=8080 -n config-db
    ```

3.  파드/Deployment 수정 (문서 예제 활용):
    - `kubectl edit pod ...`
    - `volumes` 섹션에 `configMap` 정의.
    - `volumeMounts` 섹션에 경로 정의.

**검증 (Validation):**
```bash
kubectl exec -n config-db <pod-name> -- cat /etc/config/server.port
```

---

### **17. Nginx 환경 설정 및 포트 노출 🌐**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - 파드 생성에 대한 기본 문서는 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)를 참고하나, 이 경우는 `kubectl run` 명령어가 더 효율적.
    - 문서 검색: `kubectl run`

2.  명령어 실행:
    ```bash
    kubectl run nginx-pod --image=nginx --port=8080 --env="ENV_MODE=production" -n web-server-prod
    ```

**검증 (Validation):**
```bash
kubectl get pod nginx-pod -n web-server-prod -o yaml
```

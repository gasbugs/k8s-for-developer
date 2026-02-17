# **쿠버네티스 & 컨테이너 실무 실습 17제 풀이 (Solutions)**

이 문서는 `problems.md`에 제시된 문제들에 대한 예시 풀이를 제공합니다. 실제 시험 환경이나 클러스터 설정에 따라 세부 내용은 달라질 수 있습니다.

> **💡 팁:** 시험에서는 시간을 절약하기 위해 `kubectl`의 imperative command를 최대한 활용하고, 필요한 경우 `-o yaml --dry-run=client` 옵션을 사용하여 YAML 템플릿을 생성하세요.

---

### **1. 카나리 배포 (Canary Deployment) 수행 🐤**

**솔루션:**

1.  Kubernetes 공식 문서 검색:
    - [kubernetes.io/ko/docs/concepts/workloads/controllers/deployment](https://kubernetes.io/ko/docs/concepts/workloads/controllers/deployment/) 페이지로 이동하거나 검색창에 `Deployment`를 검색합니다.
    - 예제 YAML을 복사하여 `app-v2.yaml` 파일을 생성합니다.

2.  `app-v2.yaml` 수정:
    - 복사한 YAML을 문제의 요구사항에 맞게 수정합니다.
    - `metadata.name`을 `app-v2`로 변경.
    - `replicas`를 `1`로 설정.
    - `selector.matchLabels`에 `app: web-server`와 `version: v2` 추가 (Deployment 식별용).
    - `template.metadata.labels`에 `app: web-server` (서비스 연동용)와 `version: v2` (식별용) 추가.
    - `spec.template.spec.containers`의 `image`를 `nginx:1.25`로 변경.

    **최종 YAML 예시:**
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app-v2
      namespace: production-webapp # 네임스페이스 주의
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: web-server
          version: v2  # Deployment가 자신의 파드만 관리하도록 고유 라벨 추가
      template:
        metadata:
          labels:
            app: web-server # 서비스가 트래픽을 보낼 공통 라벨
            version: v2     # 식별용 라벨
        spec:
          containers:
          - name: nginx
            image: nginx:1.25
    ```

3.  적용:
    ```bash
    kubectl apply -f app-v2.yaml
    ```

---

### **2. 크론잡 (CronJob) 고급 설정 ⏰**

**솔루션:**

1.  CronJob 생성:
    ```bash
    kubectl create cronjob settlement-job --image=busybox --schedule="30 2 * * 1" -n batch-processing --dry-run=client -o yaml > cronjob.yaml
    ```

2.  `cronjob.yaml` 수정하여 `historyLimit` 및 `command` 추가:
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

---

### **3. 이미지 빌드 및 아카이브 (Docker/Podman) 🐳**

**솔루션:**

1.  이미지 빌드:
    ```bash
    # Dockerfile이 있는 디렉토리에서 실행
    docker build -t internal-tool:v2.0 --build-arg VERSION=2.0 .
    ```

2.  이미지 저장 (tar 아카이브):
    ```bash
    docker save -o tool-v2.tar internal-tool:v2.0
    ```
    (Note: `ci-cd-pipeline` 네임스페이스로 "전달"하라는 것은 보통 클러스터 노드에서 이미지를 사용할 수 있게 하거나, 해당 파일을 특정 위치로 옮기는 것을 의미합니다. 시험 환경에 따라 scp 등을 사용할 수도 있습니다.)

---

### **4. 네트워크 정책 (Network Policy) 해결 🛡️**

**솔루션:**

1.  기존 정책 확인:
    ```bash
    kubectl get netpol -n database-tier
    kubectl describe netpol db-access-policy -n database-tier
    ```
    (출력에서 `ingress` 규칙의 `podSelector`가 `role: db-client`를 요구하는지 확인)

2.  `backend-tier`의 `api-server` 파드에 레이블 추가:
    Deployment를 수정하여 파드 템플릿에 레이블을 추가합니다.
    ```bash
    kubectl edit deployment api-server -n backend-tier
    ```
    
    `spec.template.metadata.labels` 섹션에 `role: db-client` 추가:
    ```yaml
      template:
        metadata:
          labels:
            app: api-server
            role: db-client # 추가
    ```

---

### **5. 시크릿(Secret) 생성 및 환경 변수 주입 🔐**

**솔루션:**

1.  Secret 생성:
    ```bash
    kubectl create secret generic api-auth --from-literal=api-token=secret-value-123 -n secure-api
    ```

2.  Deployment 수정:
    ```bash
    kubectl edit deployment api-server -n secure-api
    ```
    
    컨테이너 `env` 섹션 추가:
    ```yaml
        env:
        - name: SERVICE_TOKEN
          valueFrom:
            secretKeyRef:
              name: api-auth
              key: api-token
    ```

---

### **6. 보안 문맥 (Security Context) 강화 🔒**

**솔루션:**

1.  파드 수정 (파드는 직접 수정 시 일부 필드만 변경 가능하므로, YAML 추출 후 재생성하거나 Deployment라면 Deployment 수정):
    ```bash
    kubectl get pod web-app -n hardened-apps -o yaml > web-app.yaml
    kubectl delete pod web-app -n hardened-apps
    ```

2.  `web-app.yaml` 수정:
    ```yaml
    spec:
      containers:
      - name: web-app
        image: ...
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 2000
    ```

3.  재생성:
    ```bash
    kubectl apply -f web-app.yaml
    ```

---

### **7. SA 및 RBAC 권한 할당 👤**

**솔루션:**

1.  ServiceAccount 생성:
    ```bash
    kubectl create sa event-watcher-sa -n infra-monitoring
    ```

2.  Role 생성:
    ```bash
    kubectl create role event-watcher-role --verb=get,list,watch --resource=events -n infra-monitoring
    ```

3.  RoleBinding 생성:
    ```bash
    kubectl create rolebinding event-watcher-binding --role=event-watcher-role --serviceaccount=infra-monitoring:event-watcher-sa -n infra-monitoring
    ```

---

### **8. API 버전 업그레이드 (Deprecation) ⚠️**

**솔루션:**

1.  `old-deploy.yaml` 파일 수정:
    - `apiVersion`: `extensions/v1beta1` -> `apps/v1`
    - `spec.selector` 추가 (Deployment 스펙 내):
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: old-app
      namespace: migration-test
    spec:
      selector:
        matchLabels:
          app: old-app # spec.template.metadata.labels와 일치해야 함
      template:
        metadata:
          labels:
            app: old-app
    ...
    ```

2.  적용 (선택):
    ```bash
    kubectl apply -f old-deploy.yaml
    ```

---

### **9. 리소스 쿼터(ResourceQuota) 관리 📊**

**솔루션:**

1.  Quota 확인:
    ```bash
    kubectl describe resourcequota -n resource-mgmt
    ```
    (예: Hard limits가 CPU 1, Memory 1Gi이고 사용량이 0이라면)

2.  파드 생성 YAML 작성 (50% 이하 설정):
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
            cpu: "0.5"
            memory: "512Mi"
          limits:
            cpu: "0.5"
            memory: "512Mi"
    ```

---

### **10. 멀티 컨테이너 로그 진단 📋**

**솔루션:**

1.  로그 확인 및 파일 저장:
    ```bash
    kubectl logs multi-pod -c sidecar -n log-analysis > /tmp/sidecar_error.log
    ```
    
    (만약 특정 에러 라인만 추출해야 한다면 `grep` 사용: `kubectl logs ... | grep ERROR > ...`)

---

### **11. 인그레스(Ingress) 경로 설정 🌐**

**솔루션:**

1.  Ingress YAML 작성:
    ```bash
    kubectl create ingress main-ingress -n traffic-mgmt --class=nginx \
      --rule="/api=api-service:80" \
      --rule="/=web-service:80" \
      --dry-run=client -o yaml > ingress.yaml
    ```
    (참고: `--rule` 문법은 `kubectl` 버전에 따라 다를 수 있습니다. YAML을 직접 작성하는 것이 가장 확실합니다.)

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

---

### **12. 서비스 레이블 수정 및 노출 🔗**

**솔루션:**

1.  서비스와 파드 레이블 확인:
    ```bash
    kubectl get pod -n svc-discovery --show-labels
    # (예: app=backend-v1)
    kubectl get svc -n svc-discovery -o yaml
    # (예: selector: app=frontend-v1 -> 불일치 확인)
    ```

2.  서비스 수정:
    ```bash
    kubectl edit svc backend-svc -n svc-discovery
    ```
    `selector`를 `app: backend-v1`으로 수정.

---

### **13. 롤링 업데이트 및 롤백 전략 🔄**

**솔루션:**

1.  이미지 업데이트:
    ```bash
    kubectl set image deployment/web-deploy nginx=nginx:1.26 -n update-strategy
    ```

2.  MaxUnavailable 설정 (Deployment 수정):
    ```bash
    kubectl edit deployment web-deploy -n update-strategy
    ```
    `spec.strategy.rollingUpdate` 섹션 수정/추가:
    ```yaml
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 0
        maxSurge: 25% # 기본값 또는 필요에 따라 설정
    ```

3.  롤백 (문제 상황 가정 시):
    ```bash
    kubectl rollout undo deployment/web-deploy -n update-strategy
    ```

---

### **14. PV & PVC 스토리지 연결 💾**

**솔루션:**

1.  PV 생성:
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

2.  PVC 생성 (`storage-layer` 네임스페이스):
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

3.  파드/Deployment에 마운트:
    ```bash
    kubectl edit deployment <deploy-name> -n storage-layer
    ```
    ```yaml
    spec:
      containers:
      - name: ...
        volumeMounts:
        - mountPath: "/mnt/data"
          name: data-volume
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: task-pvc
    ```

---

### **15. Readiness Probe 상태 확인 🩺**

**솔루션:**

1.  Deployment/Pod 수정:
    ```bash
    kubectl edit deployment <deploy-name> -n availability-test
    ```

2.  Readiness Probe 추가:
    ```yaml
    spec:
      containers:
      - name: ...
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          failureThreshold: 3
          periodSeconds: 10 # 선택 사항
    ```

---

### **16. 컨피그맵(ConfigMap) 볼륨 마운트 ⚙️**

**솔루션:**

1.  ConfigMap 생성:
    ```bash
    kubectl create configmap app-config --from-literal=server.port=8080 -n config-db
    ```

2.  파드 수정 (볼륨 마운트):
    ```bash
    kubectl edit pod <pod-name> -n config-db
    ```
    (또는 Deployment 수정)
    ```yaml
    spec:
      containers:
      - name: ...
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
    ```

---

### **17. Nginx 환경 설정 및 포트 노출 🌐**

**솔루션:**

1.  파드 생성 및 환경변수 주입, 포트 노출:
    ```bash
    kubectl run nginx-pod --image=nginx --port=8080 --env="ENV_MODE=production" -n web-server-prod --dry-run=client -o yaml > pod.yaml
    ```
    (`--port`는 컨테이너 포트 정보만 메타데이터로 남김, 실제 Nginx 설정을 바꾸진 않지만 문제 요구사항인 '포트 노출' 명시)

2.  적용:
    ```bash
    kubectl apply -f pod.yaml
    ```

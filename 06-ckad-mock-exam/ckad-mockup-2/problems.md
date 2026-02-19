# **쿠버네티스 실무 실습 - 고급 과정 (ckad-mockup-2)**

이 실습은 기존보다 더 복잡한 시나리오와 엄격한 제약 사항을 포함하고 있습니다. 실제 운영 환경에서 발생할 수 있는 문제 해결 능력을 기르는 것을 목표로 합니다.

---

### **1. 무중단 롤링 업데이트 및 롤백 전략 (Rolling Update & Rollback) 🔄**

- **상황:** `production-tier` 네임스페이스에서 운영 중인 웹 서버를 가득 찬 사용자 트래픽 속에서 업데이트해야 합니다. 서비스 가동 중단(Downtime)은 허용되지 않으며, 업데이트 중 발생하는 리소스 낭비를 최소화해야 합니다.
- **요구사항:**
    1. `production-tier` 네임스페이스에 `advanced-web` Deployment를 생성하십시오. (이미지: `nginx:1.20`)
    2. 복제본(Replicas)은 5개로 설정하십시오.
    3. 업데이트 시 가용성을 100% 유지하기 위해 `maxUnavailable`을 `0`으로 설정하고, 동시에 생성되는 추가 파드 수를 1개로 제한하기 위해 `maxSurge`를 `1`로 설정하십시오.
    4. 이미지를 `nginx:1.26`으로 업데이트한 후, 업데이트 이력을 확인하고 문제가 발생했다는 가정하에 즉시 이전 버전으로 롤백하십시오.
- **주의:** 모든 과정은 `kubectl rollout` 명령어를 사용하여 이력을 관리해야 합니다.

### **2. 엄격한 네트워크 보안 정책 구축 (Isolated Network Policy) 🛡️**

- **상황:** `secure-db` 네임스페이스의 데이터베이스 파드가 외부의 모든 트래픽(Egress)으로부터 차단되어야 하며, 오직 특정 레이블을 가진 내부 파드로부터만 5432 포트 접근을 허용해야 합니다.
- **요구사항:**
    1. `secure-db` 네임스페이스에 `strict-db-policy` NetworkPolicy를 생성하십시오.
    2. 모든 Egress 트래픽을 차단(Deny all)하십시오.
    3. Ingress 트래픽은 `role: api-backend` 레이블을 가진 파드로부터의 TCP 5432 포트 접속만 허용하십시오.
    4. 다른 네임스페이스에서의 접근은 완전히 차단해야 합니다.
- **주의:** 네임스페이스 셀렉터(NamespaceSelector) 없이 파드 셀렉터(PodSelector)만 사용하여 동일 네임스페이스 내 통신으로 제한하십시오.

### **3. 복합 리소스 권한 제어 (RBAC Role & Binding) 👤**

- **상황:** `security-audit` 네임스페이스 내의 특정 파드가 `ConfigMap`과 `Secret` 리소스를 모두 조회(get/list)할 수 있는 전용 권한이 필요합니다.
- **요구사항:**
    1. `security-audit` 네임스페이스에 `audit-viewer-sa` ServiceAccount를 생성하십시오.
    2. 동일 네임스페이스 내의 `ConfigMaps`와 `Secrets` 두 리소스에 대해 `get`, `list` 권한을 가진 `Role`(`audit-viewer-role`)을 생성하십시오.
    3. `RoleBinding`을 통해 생성한 SA와 Role을 연결하십시오.
- **주의:** 최소 권한 원칙(Principle of Least Privilege)에 따라 명시된 리소스 외의 다른 권한(예: delete, update)은 부여하지 마십시오.

### **4. 복합 컨테이너 파드 및 공유 볼륨 (Multi-Container & Shared Volume) 📦**

- **상황:** 로그를 생성하는 메인 컨테이너와 이를 실시간으로 처리하는 어댑터(Adapter) 사이드카 컨테이너를 한 파드에 구성해야 합니다.
- **요구사항:**
    1. `logging-namespace` 네임스페이스에 `log-handler` 파드를 생성하십시오.
    2. 메인 컨테이너(`app-container`): `busybox` 이미지를 사용하며, 5초마다 `/var/log/app.log` 파일에 현재 시간을 기록합니다.
    3. 사이드카 컨테이너(`adapter-container`): `busybox` 이미지를 사용하며, 공유 볼륨을 통해 `/var/log/app.log` 파일을 읽어 표준 출력(Stdout)으로 출력합니다.
    4. 두 컨테이너는 `emptyDir` 볼륨을 공유해야 합니다.
- **주의:** 각 컨테이너의 역할이 명확해야 하며 로그 데이터가 실시간으로 공유되어야 합니다.

### **5. 리소스 제한 및 우선순위 관리 (Resource Quota & Priority) 📊**

- **상황:** `critical-apps` 네임스페이스에서 실행되는 파드가 반드시 자원을 보장받아야 하며, 네임스페이스 전체의 CPU 사용량이 1Core를 넘지 않도록 제한해야 합니다.
- **요구사항:**
    1. `critical-apps` 네임스페이스에 `ResourceQuota`(`cpu-limit-quota`)를 생성하여 CPU 한도(limits.cpu)를 `1000m`으로 설정하십시오.
    2. 해당 네임스페이스에 `critical-pod`를 배포하십시오. (이미지: `nginx`)
    3. 이 파드는 쿼터 범위 내에서 최소 `200m` CPU를 요청(Requests)하고 최대 `500m` CPU로 제한(Limits)해야 합니다.
- **주의:** 쿼터 설정을 위반하여 파드 생성이 실패하는 일이 없도록 리소스 설정을 정교하게 계산하십시오.

### **6. Readiness & Liveness Probe 복합 설정 🩺**

- **상황:** 애플리케이션의 시작 시간(Startup)이 길어 초기 부팅 중에는 트래픽을 차단하고, 실행 중 파드가 멈추면(Hang) 자동으로 재시작해야 합니다.
- **요구사항:**
    1. `app-tier` 네임스페이스에 `health-check-app` Deployment를 생성하십시오.
    2. `Readiness Probe`: HTTP GET 8080 포트의 `/ready` 경로를 5초마다 체크하고, 3번 실패 시 트래픽을 차단하십시오.
    3. `Liveness Probe`: TCP 8080 포트를 10초마다 체크하고, 3번 실패 시 파드를 재시작하십시오.
    4. 초기 지연 시간(`initialDelaySeconds`)을 15초로 설정하십시오.
- **주의:** 두 프로브(Probe)가 서로 간섭하지 않도록 임계치와 간격을 적절히 설정하십시오.

### **7. 크론잡 동시성 제어 및 재시도 제한 (CronJob Concurrency & Backoff) ⏰**

- **상황:** `finance-batch` 네임스페이스에서 데이터 백업 작업을 수행해야 합니다. 작업이 지연될 경우 이전 작업과 겹쳐서 실행되지 않아야 하며, 실패 시 최대 3번까지만 재시도해야 합니다.
- **요구사항:**
    1. `finance-batch` 네임스페이스에 `backup-cronjob`을 생성하십시오. (이미지: `busybox`)
    2. 스케줄은 매 시간 0분에 실행되도록 설정하십시오 (`0 * * * *`).
    3. `concurrencyPolicy`를 `Forbid`로 설정하여 중복 실행을 방지하십시오.
    4. 작업 실패 시의 `backoffLimit`을 `3`으로 설정하십시오.
- **주의:** 컨테이너는 `sh -c "echo Backup started; sleep 30"` 명령을 수행해야 합니다.

### **8. 인그레스 경로 재작성 및 멀티 서비스 (Ingress Rewrite & Multi-Service) 🌐**

- **상황:** 하나의 도메인 하위 경로(`/app1`, `/app2`)를 각각 다른 서비스로 연결하고, 각 서비스는 루트 경로(`/`)로 요청을 수신해야 합니다.
- **요구사항:**
    1. `multi-app` 네임스페이스에 `app-ingress`를 생성하십시오.
    2. `/app1` 경로는 `svc-1:80`으로, `/app2` 경로는 `svc-2:80`으로 연결하십시오.
    3. `nginx.ingress.kubernetes.io/rewrite-target: /` 어노테이션(Annotation)을 추가하여 경로를 재작성하십시오.
    4. `ingressClassName`은 `traefik`으로 설정하십시오.
- **주의:** 각 서비스(`svc-1`, `svc-2`)는 이미 존재한다고 가정하고 Ingress 설정에만 집중하십시오.

### **9. 노드 어피니티 및 테인트 수용 (Node Affinity & Tolerations) 🏗️**

- **상황:** 보안상의 이유로 특정 파드는 '보안 노드'(`dedicated=secure`)에서만 실행되어야 하며, 해당 노드에 설정된 테인트(Taint)를 수용해야 합니다.
- **요구사항:**
    1. `secure-compute` 네임스페이스에 `secure-workload` 파드를 생성하십시오. (이미지: `nginx`)
    2. `nodeAffinity`를 사용하여 `dedicated=secure` 레이블을 가진 노드에만 스케줄링되도록 설정하십시오 (`requiredDuringSchedulingIgnoredDuringExecution`).
    3. 노드에 설정된 `key=value:effect`가 `dedicated=secure:NoSchedule`인 테인트에 대한 `toleration`을 추가하십시오.
- **주의:** 테인트 값과 효과(Effect)가 일치하지 않으면 파드가 `Pending` 상태에 머물 수 있습니다.

### **10. PVC 동적 프로비저닝 및 볼륨 확장 (PVC Expansion) 💾**

- **상황:** 애플리케이션의 데이터 저장 공간이 부족하여 기존 10Mi 용량의 PVC를 100Mi로 확장해야 합니다.
- **요구사항:**
    1. `storage-expansion` 네임스페이스에 존재하는 `data-pvc`의 용량을 `100Mi`로 수정하십시오.
    2. 해당 PVC를 사용하는 `storage-pod`가 정상적으로 실행 중인지 확인하십시오.
- **주의:** 사용 중인 스토리지 클래스(StorageClass)가 `allowVolumeExpansion: true`를 지원한다고 가정합니다.

### **11. 트러블슈팅: 잘못된 컨피그맵 참조 수정 (Troubleshooting ConfigMap) 🔧**

- **상황:** `app-stack` 네임스페이스의 웹 서버가 실행되지 않고 `CreateContainerConfigError` 상태에 빠져 있습니다.
- **요구사항:**
    1. 해당 파드의 오류 원인을 진단하십시오 (`kubectl describe`).
    2. 파드가 참조하는 ConfigMap의 키(Key) 이름이 실제 ConfigMap과 일치하지 않는 문제를 수정하십시오.
    3. 파드가 정상적으로 `Running` 상태가 되도록 하십시오.
- **주의:** 파드를 삭제하고 다시 생성하거나, 상위 리소스(Deployment)를 수정하여 해결하십시오.

### **12. 보안 강화: 읽기 전용 파일시스템 적용 (ReadOnlyRootFilesystem) 🔒**

- **상황:** 컨테이너 내부의 루트 파일시스템에 대한 무단 수정을 방지하기 위해 읽기 전용 설정을 적용해야 합니다.
- **요구사항:**
    1. `hardened-app` 네임스페이스에 `readonly-pod` 파드를 생성하십시오. (이미지: `nginx`)
    2. `securityContext` 설정에서 `readOnlyRootFilesystem`을 `true`로 설정하십시오.
    3. Nginx가 로그를 쓰기 위해 필요로 하는 `/var/cache/nginx` 경로에는 `emptyDir` 볼륨을 마운트하여 실제 쓰기가 가능하도록 구성하십시오.
- **주의:** 읽기 전용 설정만 적용할 경우 Nginx 실행 시 오류가 발생하므로 반드시 볼륨 마운트를 함께 설정해야 합니다.

### **13. 블루-그린 배포 수동 전환 (Blue-Green Switch) 🔵🟢**

- **상황:** 신규 버전(Green)이 완벽히 준비되었습니다. 이제 기존 서비스(Service)가 가리키는 파드를 구버전(Blue)에서 신규 버전으로 전환해야 합니다.
- **요구사항:**
    1. `deployment-strategy` 네임스페이스에 존재하는 `my-service` 서비스를 수정하십시오.
    2. 서비스의 셀렉터(Selector)를 `version: blue`에서 `version: green`으로 변경하십시오.
    3. 변경 후 서비스의 엔드포인트(Endpoints)가 새로운 파드들의 IP로 갱신되었는지 확인하십시오.
- **주의:** 기존 `blue` 파드들이 삭제되지 않도록 서비스 리소스만 수정하십시오.

### **14. HPA를 이용한 자동 스케일링 (Horizontal Pod Autoscaler) 📈**

- **상황:** 예상 대규모 트래픽 발생 시 웹 서버의 파드를 자동으로 증가시켜야 합니다.
- **요구사항:**
    1. `scaling-system` 네임스페이스의 `web-app` Deployment에 대해 HPA를 생성하십시오.
    2. 최소 복제본은 `2`, 최대 복제본은 `10`으로 설정하십시오.
    3. CPU 사용율(CPU Utilization)이 `50%`를 초과할 때 스케일 아웃이 발생하도록 하십시오.
- **주의:** 대상 Deployment에 반드시 `resources.requests.cpu` 설정이 있어야 HPA가 정상 작동합니다.

### **15. 병렬 잡 수행 및 완료 보장 (Parallel Jobs) 🏃‍♂️**

- **상황:** 배치 작업을 빠르게 처리하기 위해 여러 개의 파드를 동시에 실행하고, 총 10번의 성공 결과가 나올 때까지 작업을 계속해야 합니다.
- **요구사항:**
    1. `batch-world` 네임스페이스에 `parallel-processor` Job을 생성하십시오. (이미지: `busybox`)
    2. `completions`를 `10`으로, `parallelism`을 `3`으로 설정하여 동시에 3개씩 작업을 처리하십시오.
    3. 각 파드는 `sh -c "echo Processing node; sleep 5"` 명령을 수행해야 합니다.
- **주의:** 잡이 수동으로 삭제되기 전까지 모든 파드가 성공적으로 완료되었는지 확인하십시오.

---
**추가 지침:** 모든 문제는 `ckad-mockup-2` 클러스터에서 수행되어야 하며, 채점 시 환경 변수, 네임스페이스, 레이블이 정확히 일치해야 PASS 처리가 됩니다.
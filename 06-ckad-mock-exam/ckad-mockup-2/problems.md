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

### **3. RBAC 기반의 세밀한 권한 제어 (Granular RBAC) 👤**

- **상황:** 보안 감사를 위해 `audit-system` 네임스페이스에 특정 파드만 클러스터 전체의 `PersistentVolume` 정보를 조회할 수 있는 읽기 전용 권한을 부여해야 합니다.
- **요구사항:**
    1. `audit-system` 네임스페이스에 `pv-auditor-sa` ServiceAccount를 생성하십시오.
    2. 클러스터 전체 범위의 `PersistentVolumes` 리소스에 대해 `get`, `list` 권한만 가진 `ClusterRole`(`pv-reader-role`)을 생성하십시오.
    3. `ClusterRoleBinding`을 사용하여 생성한 SA에 이 권한을 할당하십시오.
- **주의:** 권한은 최소 권한 원칙(Principle of Least Privilege)을 준수해야 하며, `PersistentVolumeClaims` 권한은 포함하지 마십시오.

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

---
**추가 지침:** 모든 문제는 `ckad-mockup-2` 클러스터에서 수행되어야 하며, 채점 시 환경 변수, 네임스페이스, 레이블이 정확히 일치해야 PASS 처리가 됩니다.
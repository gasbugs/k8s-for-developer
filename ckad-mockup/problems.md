# **쿠버네티스 & 컨테이너 실무 실습 17제**

### **쿠버네티스 & 컨테이너 실무 실습 17제 (Namespace 강화 버전)**

### **1. 카나리 배포 (Canary Deployment) 수행 🐤**

- **상황:** `production-webapp` 네임스페이스에서 운영 중인 `app-v1` (이미지: `httpd`)에 신규 버전 `app-v2`를 일부 배포하여 검증해야 합니다.
- **요구사항:**
    1. `production-webapp` 네임스페이스 내에 `app-v2` Deployment를 생성하십시오. (이미지: `nginx:1.25`)
    2. 기존 `app-v1` 파드들이 사용하는 서비스 셀렉터 레이블(`app: web-server`)을 `app-v2` 파드 템플릿에도 동일하게 설정하십시오.
    3. `app-v2`의 복제본(replicas)을 1개로 설정하여 전체 트래픽의 10%만 수신하도록 구성하십시오.
    4. `v2` 파드를 식별할 수 있도록 전용 레이블 `version: v2`를 추가하십시오.

### **2. 크론잡 (CronJob) 고급 설정 ⏰**

- **상황:** `batch-processing` 네임스페이스에서 매주 특정 시간에 데이터 정산 작업을 수행해야 합니다.
- **요구사항:**
    1. `batch-processing` 네임스페이스에 `settlement-job`이라는 이름의 CronJob을 생성하십시오.
    2. 스케줄은 매주 월요일 새벽 2시 30분(`30 2 * * 1`)에 실행되도록 설정하십시오.
    3. 성공한 작업 내역은 최대 5개, 실패한 내역은 최대 2개만 유지하도록 `historyLimit`을 설정하십시오.
    4. 컨테이너 이미지 `busybox`를 사용하여 "Processing..." 메시지를 출력하도록 하십시오.

### **3. 이미지 빌드 및 아카이브 (Docker/Podman) 🐳**

- **상황:** `ci-cd-pipeline` 네임스페이스에 배포할 이미지를 로컬에서 빌드하여 서버로 전달해야 합니다.
- **요구사항:**
    1. 현재 경로의 `Dockerfile`을 이용해 `internal-tool:v2.0` 이미지를 빌드하십시오.
    2. 빌드 시 인자(build-arg)로 `VERSION=2.0`을 전달하십시오.
    3. 빌드된 이미지를 `tool-v2.tar` 파일로 저장하십시오.
    4. 저장된 파일이 `ci-cd-pipeline` 네임스페이스의 테스트 환경에서 사용될 수 있도록 준비하십시오.

### **4. 네트워크 정책 (Network Policy) 해결 🛡️**

- **상황:** `database-tier` 네임스페이스의 DB 파드가 `backend-tier` 네임스페이스 파드의 접근을 차단하고 있습니다.
- **요구사항:**
    1. `database-tier` 네임스페이스에 적용된 기존 Network Policy를 분석하십시오.
    2. `backend-tier` 네임스페이스의 `api-server` 파드들이 DB에 접근할 수 있도록, 정책에서 허용하는 레이블(`role: db-client`)을 `api-server` 파드 템플릿에 추가하십시오.
    3. **주의:** 설정된 Network Policy 리소스는 직접 수정하지 마십시오.

### **5. 시크릿(Secret) 생성 및 환경 변수 주입 🔐**

- **상황:** `secure-api` 네임스페이스의 서버가 외부 인증을 위한 토큰 정보가 필요합니다.
- **요구사항:**
    1. `secure-api` 네임스페이스에 `api-auth` 시크릿을 생성하십시오. (데이터: `api-token=secret-value-123`)
    2. 동일 네임스페이스 내의 `api-server` Deployment를 수정하여, 시크릿의 값을 `SERVICE_TOKEN`이라는 환경 변수로 주입하십시오.

### **6. 보안 문맥 (Security Context) 강화 🔒**

- **상황:** `hardened-apps` 네임스페이스 내의 컨테이너가 루트 권한을 가지지 않도록 제한해야 합니다.
- **요구사항:**
    1. `hardened-apps` 네임스페이스에서 실행 중인 `web-app` 파드의 설정을 수정하십시오.
    2. `allowPrivilegeEscalation: false`를 설정하여 권한 상승을 차단하십시오.
    3. 컨테이너 실행 유저를 `UID 2000`으로 고정하십시오.

### **7. SA 및 RBAC 권한 할당 👤**

- **상황:** `infra-monitoring` 네임스페이스의 파드가 클러스터의 이벤트를 감시해야 합니다.
- **요구사항:**
    1. `infra-monitoring` 네임스페이스에 `event-watcher-sa` 서비스 어카운트를 생성하십시오.
    2. 해당 네임스페이스 내 `events` 리소스에 대해 `get`, `list`, `watch` 권한을 가진 Role을 생성하십시오.
    3. RoleBinding을 통해 생성한 SA와 Role을 연결하고, 이를 특정 파드에 적용하십시오.

### **8. API 버전 업그레이드 (Deprecation) ⚠️**

- **상황:** `migration-test` 네임스페이스에 구형 API 버전으로 작성된 YAML 배포가 실패하고 있습니다.
- **요구사항:**
    1. `migration-test` 네임스페이스용 `old-deploy.yaml` 파일의 `apiVersion`을 `apps/v1`으로 수정하십시오.
    2. `spec.selector.matchLabels` 필드가 누락되었다면 이를 추가하여 최신 규격에 맞게 보정하십시오.

### **9. 리소스 쿼터(ResourceQuota) 관리 📊**

- **상황:** `resource-mgmt` 네임스페이스에 할당된 자원 제한으로 인해 신규 파드 생성이 거부됩니다.
- **요구사항:**
    1. `resource-mgmt` 네임스페이스의 `ResourceQuota` 잔여량을 확인하십시오.
    2. 배포할 파드의 `requests`와 `limits`를 쿼터 잔여량의 50% 이내로 계산하여 설정하십시오.

### **10. 멀티 컨테이너 로그 진단 📋**

- **상황:** `log-analysis` 네임스페이스의 `multi-pod` 파드 내 사이드카 컨테이너에서 장애가 발생했습니다.
- **요구사항:**
    1. `kubectl logs` 명령어를 사용하여 `log-analysis` 네임스페이스 내 파드의 `sidecar` 컨테이너 로그를 확인하십시오.
    2. 에러가 포함된 로그 내용을 `/tmp/sidecar_error.log` 파일로 저장하십시오.

### **11. 인그레스(Ingress) 경로 설정 🌐**

- **상황:** `traffic-mgmt` 네임스페이스를 통해 외부 트래픽을 각 서비스로 분산해야 합니다.
- **요구사항:**
    1. `traffic-mgmt` 네임스페이스에 `main-ingress` 리소스를 생성하십시오.
    2. `/api` 경로는 `api-service`로, 그 외 경로는 `web-service`로 연결되도록 설정하십시오.
    3. `ingressClassName`을 `nginx`로 지정하십시오.

### **12. 서비스 레이블 수정 및 노출 🔗**

- **상황:** `svc-discovery` 네임스페이스의 서비스가 파드와 연결되지 않아 통신 장애가 발생합니다.
- **요구사항:**
    1. `svc-discovery` 네임스페이스 내 서비스의 `selector` 레이블과 Deployment 파드의 레이블을 대조하십시오.
    2. 서비스의 `selector`를 파드 레이블과 일치하도록 수정하여 `Endpoints`가 정상 생성되게 하십시오.

### **13. 롤링 업데이트 및 롤백 전략 🔄**

- **상황:** `update-strategy` 네임스페이스의 애플리케이션 업데이트 중 오류가 발견되었습니다.
- **요구사항:**
    1. `update-strategy` 네임스페이스의 `web-deploy` 이미지를 `nginx:1.26`으로 업데이트하십시오.
    2. 가용성 유지를 위해 `maxUnavailable`을 0으로 설정하십시오.
    3. 업데이트 직후 문제가 발생하면 `kubectl rollout undo`를 사용하여 이전 버전으로 되돌리십시오.

### **14. PV & PVC 스토리지 연결 💾**

- **상황:** `storage-layer` 네임스페이스의 파드가 영구적인 데이터 저장이 필요합니다.
- **요구사항:**
    1. 1Gi 용량의 영구 볼륨(PV)을 생성하십시오.
    2. `storage-layer` 네임스페이스에 해당 PV와 바인딩될 1Gi 용량의 PVC를 생성하십시오.
    3. 해당 네임스페이스의 파드에 `/mnt/data` 경로로 PVC를 마운트하십시오.

### **15. Readiness Probe 상태 확인 🩺**

- **상황:** `availability-test` 네임스페이스의 서비스가 준비되지 않은 파드로 트래픽을 보내고 있습니다.
- **요구사항:**
    1. `availability-test` 네임스페이스 내 파드에 `HTTP GET` 방식의 `Readiness Probe`를 추가하십시오.
    2. `8080` 포트의 `/healthz` 경로를 체크하도록 설정하십시오.
    3. 실패 횟수가 3회 이상일 경우 트래픽에서 제외되도록 하십시오.

### **16. 컨피그맵(ConfigMap) 볼륨 마운트 ⚙️**

- **상황:** `config-db` 네임스페이스의 애플리케이션 설정값을 파일 형태로 주입해야 합니다.
- **요구사항:**
    1. `config-db` 네임스페이스에 `app-config` 컨피그맵을 생성하십시오. (내용: `server.port=8080`)
    2. 파드 내의 `/etc/config` 디렉토리에 해당 컨피그맵을 파일로 마운트하여 연결하십시오.

### **17. Nginx 환경 설정 및 포트 노출 🌐**

- **상황:** `web-server-prod` 네임스페이스의 웹 서버 환경을 설정해야 합니다.
- **요구사항:**
    1. `web-server-prod` 네임스페이스에 Nginx 파드를 배포하고 `8080` 포트를 노출하십시오.
    2. `ENV_MODE=production`이라는 환경 변수를 직접 주입하여 실행 여부를 확인하십시오.

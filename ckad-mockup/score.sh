#!/bin/bash

# 초기화
SCORE=0
TOTAL_SCORE=0
PASS_THRESHOLD=66

echo "=================================================="
echo "       CKAD Mock Exam Scoring Script"
echo "=================================================="
echo ""

# 함수: 채점 (문제 번호, 배점, 설명, 검증 명령어)
check_problem() {
    local problem_num=$1
    local points=$2
    local description=$3
    local command=$4

    echo -n "[Problem $problem_num] $description ($points pts)... "

    # 명령어 실행 및 결과 확인
    if eval "$command" > /dev/null 2>&1; then
        echo "PASS"
        SCORE=$((SCORE + points))
    else
        echo "FAIL"
    fi
    TOTAL_SCORE=$((TOTAL_SCORE + points))
}

# 1. Canary Deployment (7점)
# - app-v2 배포 존재 확인
# - app-v2 이미지 nginx:1.25 확인
# - app-v2 복제본 1개 확인
# - Service(my-app-service)가 app-v2도 셀렉팅하는지 확인 (Endpoints 개수 확인)
check_problem 1 7 "Canary Deployment" "
    kubectl get deploy app-v2 -n production-webapp && \
    kubectl get deploy app-v2 -n production-webapp -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q 'nginx:1.25' && \
    [ \$(kubectl get deploy app-v2 -n production-webapp -o jsonpath='{.spec.replicas}') -eq 1 ] && \
    [ \$(kubectl get ep my-app-service -n production-webapp -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w) -ge 2 ]
"

# 2. CronJob (6점)
# - CronJob 존재 및 스케줄 확인
# - HistoryLimit 확인
check_problem 2 6 "CronJob Setup" "
    kubectl get cronjob settlement-job -n batch-processing && \
    kubectl get cronjob settlement-job -n batch-processing -o jsonpath='{.spec.schedule}' | grep -q '30 2 \* \* 1' && \
    [ \$(kubectl get cronjob settlement-job -n batch-processing -o jsonpath='{.spec.successfulJobsHistoryLimit}') -eq 5 ] && \
    [ \$(kubectl get cronjob settlement-job -n batch-processing -o jsonpath='{.spec.failedJobsHistoryLimit}') -eq 2 ]
"

# 3. Image Build (5점)
# - tar 파일 존재 확인
check_problem 3 5 "Image Build & Archive" "
    ls tool-v2.tar
"

# 4. Network Policy (7점)
# - api-server 파드에 role: db-client 레이블 확인
check_problem 4 7 "Network Policy (Label)" "
    kubectl get pod -n backend-tier -l app=api-server,role=db-client | grep -q 'Running'
"

# 5. Secret & Env (6점)
# - Secret 존재 확인
# - 파드 환경변수 주입 확인
check_problem 5 6 "Secret & Env Var" "
    kubectl get secret api-auth -n secure-api && \
    kubectl get deploy api-server -n secure-api -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' | grep -q 'SERVICE_TOKEN'
"

# 6. Security Context (6점)
# - runAsUser 2000 확인
# - allowPrivilegeEscalation: false 확인
check_problem 6 6 "Security Context" "
    kubectl get pod web-app -n hardened-apps -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' | grep -q '2000' && \
    kubectl get pod web-app -n hardened-apps -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' | grep -q 'false'
"

# 7. ServiceAccount & RBAC (7점)
# - SA 생성 확인
# - 권한 확인 (auth can-i)
check_problem 7 7 "RBAC Configuration" "
    kubectl get sa event-watcher-sa -n infra-monitoring && \
    kubectl auth can-i list events --as=system:serviceaccount:infra-monitoring:event-watcher-sa -n infra-monitoring | grep -q 'yes'
"

# 8. API Version Upgrade (5점)
# - old-app 배포가 apps/v1으로 업데이트 되었는지 확인 (kubectl get deploy로 확인되면 성공한 것)
check_problem 8 5 "API Version Upgrade" "
    kubectl get deploy old-app -n migration-test -o jsonpath='{.apiVersion}' | grep -q 'apps/v1'
"

# 9. Resource Quota (6점)
# - 쿼터 제한을 넘지 않는 파드 생성 확인 (quota-pod 존재 확인)
check_problem 9 6 "Resource Quota" "
    kubectl get pod quota-pod -n resource-mgmt | grep -q 'Running'
"

# 10. Multi-container Logs (5점)
# - 로그 파일 존재 및 내용 확인
check_problem 10 5 "Log Extraction" "
    grep -q 'ERROR: Connection failed' /tmp/sidecar_error.log
"

# 11. Ingress (7점)
# - Ingress 존재 확인
# - 규칙(Host/Path) 확인
check_problem 11 7 "Ingress Configuration" "
    kubectl get ingress main-ingress -n traffic-mgmt && \
    kubectl get ingress main-ingress -n traffic-mgmt -o jsonpath='{.spec.rules[0].http.paths[*].path}' | grep -q '/api' && \
    kubectl get ingress main-ingress -n traffic-mgmt -o jsonpath='{.spec.rules[0].http.paths[*].path}' | grep -q '/'
"

# 12. Service Selector (6점)
# - 서비스 Endpoints 존재 확인 (IP가 있어야 함)
check_problem 12 6 "Service Selector Fix" "
    [ \$(kubectl get ep backend-svc -n svc-discovery -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w) -gt 0 ]
"

# 13. Rolling Update (6점)
# - 이미지 1.26 확인
# - MaxUnavailable 0 확인
check_problem 13 6 "Rolling Update Setup" "
    kubectl get deploy web-deploy -n update-strategy -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q 'nginx:1.26' && \
    kubectl get deploy web-deploy -n update-strategy -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' | grep -q '0'
"

# 14. PV & PVC (6점)
# - PV, PVC Bound 상태 확인
# - 파드 마운트 확인
check_problem 14 6 "PV & PVC" "
    kubectl get pvc task-pvc -n storage-layer | grep -q 'Bound' && \
    kubectl get deploy -n storage-layer -o jsonpath='{.items[*].spec.template.spec.containers[*].volumeMounts[*].name}' | grep -q 'data-volume'
"

# 15. Readiness Probe (5점)
# - Probe 설정 확인
check_problem 15 5 "Readiness Probe" "
    kubectl get deploy -n availability-test -o jsonpath='{.items[*].spec.template.spec.containers[*].readinessProbe.httpGet.path}' | grep -q '/healthz'
"

# 16. ConfigMap (5점)
# - 마운트 확인
check_problem 16 5 "ConfigMap Mount" "
    kubectl get pod -n config-db -o jsonpath='{.items[*].spec.containers[*].volumeMounts[*].mountPath}' | grep -q '/etc/config'
"

# 17. Pod Env & Port (5점)
# - 환경변수 확인
# - 포트 8080 확인 (메타데이터)
check_problem 17 5 "Pod Env & Port" "
    kubectl get pod nginx-pod -n web-server-prod -o jsonpath='{.spec.containers[0].env[*].value}' | grep -q 'production' && \
    kubectl get pod nginx-pod -n web-server-prod -o jsonpath='{.spec.containers[0].ports[*].containerPort}' | grep -q '8080'
"

echo ""
echo "=================================================="
echo "Final Score: $SCORE / $TOTAL_SCORE"
echo "=================================================="

if [ $SCORE -ge $PASS_THRESHOLD ]; then
    echo "Result: PASS (Congratulations!)"
else
    echo "Result: FAIL (Keep practicing!)"
fi

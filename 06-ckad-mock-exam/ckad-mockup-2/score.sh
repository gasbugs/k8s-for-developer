#!/bin/bash
set -e

# 초기화
SCORE=0
TOTAL_SCORE=0
PASS_THRESHOLD=66

echo "=================================================="
echo "       ckad-mockup-2 Scoring Script"
echo "=================================================="
echo ""

check_problem() {
    local num=$1 pts=$2 desc=$3 cmd=$4
    echo -n "[Problem $num] $desc ($pts pts)... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS"
        SCORE=$((SCORE + pts))
    else
        echo "FAIL"
    fi
    TOTAL_SCORE=$((TOTAL_SCORE + pts))
}

# 1. 롤링 업데이트 및 롤백 (7점)
check_problem 1 7 "Rolling Update & Rollback Settings" "
    kubectl get deploy advanced-web -n production-tier -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' | grep -q '0' && \
    kubectl get deploy advanced-web -n production-tier -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' | grep -q '1' && \
    [ \$(kubectl get deploy advanced-web -n production-tier -o jsonpath='{.spec.replicas}') -eq 5 ]
"

# 2. 엄격한 네트워크 보안 정책 (7점)
check_problem 2 7 "Strict Network Policy" "
    kubectl get netpol strict-db-policy -n secure-db && \
    kubectl get netpol strict-db-policy -n secure-db -o yaml | grep -q 'podSelector: {}' && \
    kubectl get netpol strict-db-policy -n secure-db -o yaml | grep -q 'role: api-backend' && \
    kubectl get netpol strict-db-policy -n secure-db -o yaml | grep -q 'port: 5432'
"

# 3. RBAC (7점)
check_problem 3 7 "RBAC Role & Binding" "
    kubectl get sa audit-viewer-sa -n security-audit && \
    kubectl get role audit-viewer-role -n security-audit && \
    kubectl auth can-i get secrets --as=system:serviceaccount:security-audit:audit-viewer-sa -n security-audit | grep -q 'yes' && \
    kubectl auth can-i list configmaps --as=system:serviceaccount:security-audit:audit-viewer-sa -n security-audit | grep -q 'yes' && \
    kubectl auth can-i delete secrets --as=system:serviceaccount:security-audit:audit-viewer-sa -n security-audit | grep -q 'no'
"

# 4. 멀티 컨테이너 (6점)
check_problem 4 6 "Multi-Container Pod" "
    [ \$(kubectl get pod log-handler -n logging-namespace -o jsonpath='{.spec.containers[*].name}' | wc -w) -eq 2 ] && \
    kubectl get pod log-handler -n logging-namespace -o jsonpath='{.spec.volumes[*].emptyDir}' | grep -v 'null' > /dev/null
"

# 5. 리소스 쿼터 (6점)
check_problem 5 6 "Resource Quota Compliance" "
    kubectl get resourcequota cpu-limit-quota -n critical-apps && \
    kubectl get pod critical-pod -n critical-apps -o jsonpath='{.spec.containers[0].resources.requests.cpu}' | grep -q '200m' && \
    kubectl get pod critical-pod -n critical-apps -o jsonpath='{.spec.containers[0].resources.limits.cpu}' | grep -q '500m'
"

# 6. 프로브 설정 (7점)
check_problem 6 7 "Readiness & Liveness Probes" "
    kubectl get deploy health-check-app -n app-tier -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' | grep -q '8080' && \
    kubectl get deploy health-check-app -n app-tier -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.tcpSocket.port}' | grep -q '8080' && \
    kubectl get deploy health-check-app -n app-tier -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}' | grep -q '15'
"

# 7. 크론잡 (6점)
check_problem 7 6 "CronJob Settings" "
    kubectl get cronjob backup-cronjob -n finance-batch -o jsonpath='{.spec.concurrencyPolicy}' | grep -q 'Forbid' && \
    kubectl get cronjob backup-cronjob -n finance-batch -o jsonpath='{.spec.jobTemplate.spec.backoffLimit}' | grep -q '3'
"

# 8. 인그레스 (7점)
check_problem 8 7 "Ingress Multi-Path & Rewrite" "
    kubectl get ingress app-ingress -n multi-app -o jsonpath='{.metadata.annotations}' | grep -q 'rewrite-target' && \
    kubectl get ingress app-ingress -n multi-app -o jsonpath='{.spec.rules[0].http.paths[*].path}' | grep -q '/app1' && \
    kubectl get ingress app-ingress -n multi-app -o jsonpath='{.spec.rules[0].http.paths[*].path}' | grep -q '/app2'
"

# 9. 노드 어피니티 (7점)
check_problem 9 7 "Node Affinity & Tolerations" "
    kubectl get pod secure-workload -n secure-compute -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution}' && \
    kubectl get pod secure-workload -n secure-compute -o jsonpath='{.spec.tolerations[*].key}' | grep -q 'dedicated'
"

# 10. PVC 확장 (6점)
check_problem 10 6 "PVC Expansion" "
    kubectl get pvc data-pvc -n storage-expansion -o jsonpath='{.spec.resources.requests.storage}' | grep -q '100Mi'
"

# 11. 트러블슈팅 (7점)
check_problem 11 7 "Troubleshooting ConfigMap" "
    kubectl get pod -n app-stack -l app=web -o jsonpath='{.items[0].status.phase}' | grep -q 'Running' && \
    kubectl get deploy web-deploy -n app-stack -o yaml | grep -q 'key: correct-key'
"

# 12. 읽기 전용 파일시스템 (6점)
check_problem 12 6 "ReadOnlyRootFilesystem" "
    kubectl get pod readonly-pod -n hardened-app -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' | grep -q 'true' && \
    kubectl get pod readonly-pod -n hardened-app -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -q '/var/cache/nginx'
"

# 13. 블루-그린 전환 (7점)
check_problem 13 7 "Blue-Green Switch" "
    kubectl get svc my-service -n deployment-strategy -o jsonpath='{.spec.selector.version}' | grep -q 'green'
"

# 14. HPA (7점)
check_problem 14 7 "HPA Configuration" "
    kubectl get hpa -n scaling-system && \
    kubectl get hpa -n scaling-system -o jsonpath='{.spec.maxReplicas}' | grep -q '10' && \
    kubectl get hpa -n scaling-system -o jsonpath='{.spec.targetCPUUtilizationPercentage}' | grep -q '50'
"

# 15. 병렬 잡 (7점)
check_problem 15 7 "Parallel Jobs" "
    kubectl get job parallel-processor -n batch-world -o jsonpath='{.spec.completions}' | grep -q '10' && \
    kubectl get job parallel-processor -n batch-world -o jsonpath='{.spec.parallelism}' | grep -q '3'
"

echo ""
echo "=================================================="
echo "Final Score: $SCORE / $TOTAL_SCORE"
echo "=================================================="

if [ $SCORE -ge $PASS_THRESHOLD ]; then
    echo "Result: PASS"
else
    echo "Result: FAIL"
fi

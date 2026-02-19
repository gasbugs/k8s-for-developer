#!/bin/bash
set -e

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

# Example Problem
# check_problem 1 10 "Verify Nginx Pod" "kubectl get pods | grep -q nginx"

echo ""
echo "=================================================="
echo "Final Score: $SCORE / $TOTAL_SCORE"
echo "=================================================="

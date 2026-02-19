---
name: k8s-lab-engineer
description: Kubernetes 기반의 실험실(Laboratory), 모의고사(Mock Exam), 또는 클라우드 보안 진단(Cloud Security Diagnosis) 프로젝트를 생성하고 관리하는 것을 돕습니다. 사용자가 "새로운 k8s 실습 제작", "모의고사 환경 구축", 또는 "k8s 진단 프로젝트 설정"과 같은 요청을 할 때 이 스킬을 트리거하세요.
---

# K8s Lab Engineer 스킬 (Skill)

이 스킬은 표준화된 Kubernetes 실험실 환경의 생성을 자동화합니다. 이 스킬은 검증된 워크플로우(Workflow)인 설정(Setup) -> 문제 배포(Deploy Problems) -> 채점/검증(Score/Validate) -> 정리(Cleanup)를 따릅니다.

## 트리거 조건 (Trigger Conditions)
사용자가 다음과 같이 말할 때 이 스킬을 사용하세요:
- "ckad-mockup과 같은 새로운 Kubernetes 프로젝트를 시작하고 싶어."
- "[주제]를 위한 새로운 K8s 실습(Lab)을 만들어줘."
- "Kubernetes에서 클라우드 보안 진단 환경을 구축해줘."

## 단계별 수행 절차 (Step-by-Step Instructions)

### 1. 프로젝트 초기화 (Project Initialization)
사용자에게 다음 세부 정보를 요청하세요:
- **프로젝트 이름 (Project Name)**: 예: `k8s-security-lab`
- **네임스페이스 (Namespaces)**: 격리(Isolation)를 위해 생성할 네임스페이스 목록.
- **Kind 설정 (Kind Configuration)**: 특정 클러스터(Cluster) 설정이 필요한 경우 노드(Node)/역할(Role) 정보 (기본값은 간단한 멀티 노드 설정).

### 2. 핵심 스크립트 스캐폴딩 (Scaffold Core Scripts)
다음 디렉토리 구조와 파일들을 생성하세요:

- `setup.sh`: Kind 클러스터를 초기화하는 스크립트.
- `deploy-problems.sh`: 초기(의도적으로 오류가 있거나 기본 상태인) YAML 리소스(Resource)를 적용하는 스크립트.
- `score.sh`: 사용자 솔루션(Solution)을 확인하는 채점 엔진(Validation Engine).
- `cleanup.sh`: 클러스터를 삭제하는 스크립트.
- `problems.md`: 사용자가 수행해야 할 작업(Task) 설명.
- `solutions.md`: 문제를 해결하기 위한 단계별 가이드.

### 3. 구현 패턴 (Implementation Patterns)

#### 컨테이너 엔진 감지 (Container Engine Detection)
Docker와 Podman을 모두 지원하기 위해 셸 스크립트(Shell Script) 상단에 항상 이 코드 조각(Snippet)을 포함하세요:
```bash
if docker info >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
elif podman info >/dev/null 2>&1; then
    CONTAINER_ENGINE="podman"
else
    echo "Error: Neither Docker nor Podman found."
    exit 1
fi
```

#### 채점 엔진 (Validation Engine - score.sh)
일관된 검증을 위해 `check_problem` 함수 패턴을 사용하세요:
```bash
check_problem() {
    local num=$1 pts=$2 desc=$3 cmd=$4
    echo -n "[Problem $num] $desc ($pts pts)... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS"; SCORE=$((SCORE + pts))
    else
        echo "FAIL"
    fi
}
```

### 4. 스캐폴딩 스크립트 사용 (Using the Scaffolding Script)
사용 가능한 경우, 제공된 Python 스크립트를 사용하여 보일러플레이트(Boilerplate)를 생성하세요:
`python3 .agent/skills/k8s-lab-engineer/scripts/scaffold_lab.py --output-dir <DIR> --name <PROJECT_NAME>`

## 스킬 테스트 (Testing the Skill)
스킬이 정상 작동하는지 테스트하려면:
1. 프로젝트 생성 요청을 트리거합니다.
2. 4개의 핵심 `.sh` 파일과 2개의 `.md` 파일이 생성되었는지 확인합니다.
3. `score.sh`에 `check_problem` 함수가 포함되어 있는지 확인합니다.

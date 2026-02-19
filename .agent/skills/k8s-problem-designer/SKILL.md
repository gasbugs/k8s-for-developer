---
name: k8s-problem-designer
description: Kubernetes 실습 문제나 시험 문항(Problems/Questions)을 설계하고 Markdown 형식으로 작성하는 것을 돕습니다. 사용자가 "새로운 k8s 문제 만들어줘", "더 어려운 실습 문항이 필요해", 또는 "problems.md 작성해줘"라고 요청할 때 이 스킬을 트리거하세요.
---

# K8s Problem Designer 스킬 (Skill)

이 스킬은 고품질의 Kubernetes 실무 실습 문제를 설계합니다. 단순히 기술적인 요구사항만 나열하는 것이 아니라, 실제 운영 환경에서 발생할 법한 상황(Scenario)과 구체적인 제약 사항(Constraints)을 포함하여 교육 효과를 극대화합니다.

## 트리거 조건 (Trigger Conditions)
사용자가 다음과 같이 말할 때 이 스킬을 사용하세요:
- "새로운 Kubernetes 문제를 만들어줘."
- "문제가 너무 쉬워. 좀 더 어렵게 변형해줘."
- "`problems.md`에 실습 문항을 설계해줘."
- "특정 주제(예: 네트워크, 보안)에 집중된 문제를 생성해줘."

## 단계별 수행 절차 (Step-by-Step Instructions)

### 1. 요구사항 분석 (Requirements Analysis)
사용자에게 다음 정보를 확인하거나, 문맥을 통해 파악하세요:
- **대상 및 난이도 (Target & Difficulty)**: 초급, 중급(CKAD 수준), 고급(CKS/CKA 수준).
- **핵심 주제 (Core Topics)**: 배포(Deployment), 네트워킹(Networking), 보안(Security), 트러블슈팅(Troubleshooting) 등.
- **기존 문제 참조 (Reference Existing Problems)**: 기존에 배포된 문제와 중복되지 않도록 분석합니다.

### 2. 문제 설계 규칙 (Problem Design Rules)
각 문제는 다음 구조를 엄격히 따릅니다:
- **상황 (Scenario)**: 왜 이 작업을 수행해야 하는지에 대한 배경 설명.
- **요구사항 (Requirements)**: 구체적으로 생성하거나 수정해야 할 리소스(Resource) 명세.
- **주의/제약 사항 (Caution/Constraints)**: 직접 수정을 금지하거나, 반드시 지켜야 할 이름(Name), 네임스페이스(Namespace) 등.

### 3. 기술적 정확성 검증 (Technical Validation)
- 생성된 문제가 현재 Kubernetes 버전에서 유효한 API를 사용하는지 확인합니다.
- 문제가 실제로 해결 가능한지(Solvable) 논리적으로 검토합니다.

### 4. Markdown 포맷팅 (Markdown Formatting)
다음과 같은 표준 형식을 사용합니다:
```markdown
### **[번호]. [문제 제목] [아이콘]**

- **상황:** [배경 설명]
- **요구사항:**
    1. [리소스 명세 1]
    2. [리소스 명세 2]
- **주의:** [제약 사항]
```

## 스킬 테스트 (Testing the Skill)
스킬이 정상 작동하는지 테스트하려면:
1. "보안(Security) 주제로 중급 난이도 문제 2개를 만들어줘"라고 요청합니다.
2. 출력된 결과가 상황-요구사항-주의 구조를 갖추고 있는지 확인합니다.
3. 기술 용어 옆에 원어(영어)가 병기되어 있는지 확인합니다.

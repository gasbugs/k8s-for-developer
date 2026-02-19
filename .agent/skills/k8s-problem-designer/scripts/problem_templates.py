#!/usr/bin/env python3
import json

# Common K8s Problem Templates
TEMPLATES = [
    {
        "topic": "Deployment & Strategy",
        "difficulty": "Advanced",
        "scenario": "운영 중인 서비스의 가동 중지 시간을 방지하면서 새로운 버전으로 업데이트해야 합니다. 특히 시스템 리소스가 부족한 상황을 가정하여 매우 엄격한 롤링 업데이트 전략을 세워야 합니다.",
        "requirements": [
            "네임스페이스 '{namespace}'에 'web-server' Deployment를 생성하십시오. (이미지: nginx:1.21)",
            "롤링 업데이트 시 가용성을 100% 유지하기 위해 'maxUnavailable'을 0으로 설정하십시오.",
            "동시에 프로비저닝되는 추가 파드 수를 제한하기 위해 'maxSurge'를 1로 설정하십시오.",
            "업데이트 후 이미지 버전을 'nginx:1.23'으로 변경하고 롤아웃 이력을 확인하십시오."
        ],
        "caution": "업데이트 중 중단이 발생하면 즉시 이전 버전으로 롤백(Rollback)해야 합니다."
    },
    {
        "topic": "Network Security",
        "difficulty": "Advanced",
        "scenario": "특정 데이터베이스 파드가 외부 인터넷과 차단되어야 하며, 오직 특정 'frontend' 레이블이 붙은 파드로부터만 6379 포트로의 통신을 허용해야 합니다.",
        "requirements": [
            "네임스페이스 '{namespace}'에 'db-policy'라는 NetworkPolicy를 생성하십시오.",
            "모든 Egress 트래픽을 차단(Deny all)하십시오.",
            "Ingress는 'role: frontend' 레이블을 가진 파드로부터의 6379 포트 접속만 허용하십시오."
        ],
        "caution": "기존에 존재하던 다른 서비스들의 통신이 끊기지 않도록 주의하십시오."
    }
]

def get_problems(namespace="default"):
    output = []
    for i, t in enumerate(TEMPLATES, 1):
        reqs = "\n    ".join([f"{j}. {r.format(namespace=namespace)}" for j, r in enumerate(t['requirements'], 1)])
        p = f"### **{i}. {t['topic']} ({t['difficulty']}) 🚀**\n\n"
        p += f"- **상황:** {t['scenario']}\n"
        p += f"- **요구사항:**\n    {reqs}\n"
        p += f"- **주의:** {t['caution']}\n"
        output.append(p)
    return "\n".join(output)

if __name__ == "__main__":
    print(get_problems("ckad-mockup-2"))

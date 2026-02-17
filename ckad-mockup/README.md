# CKAD 모의고사 환경

이 디렉토리는 CKAD 모의고사 환경을 설정하기 위한 파일들을 포함하고 있습니다.

## 빠른 시작

다음 명령어를 실행하여 전체 환경을 설정하세요:

```bash
bash setup.sh
```

이 스크립트는 다음 작업을 수행합니다:
1. `kind-mockup-config.yaml` 설정을 사용하여 Kind 클러스터를 생성합니다.
2. Cilium CNI를 설치합니다.
3. `traefik-values.yaml`을 사용하여 Traefik Ingress Controller를 설치합니다.
4. `setup-lab.sh`를 실행하여 CKAD 모의고사용 네임스페이스와 리소스를 생성합니다.

## 실습 문제


## 실습 문제

실습 문제는 [problems.md](problems.md) 파일에서 확인할 수 있습니다.

## 채점 (Scoring)

문제를 모두 풀었다면 다음 스크립트를 실행하여 점수를 확인할 수 있습니다 (총 100점 만점):

```bash
bash score.sh
```

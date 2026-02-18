# 실습 환경 구성을 위한 필수 도구 설치 가이드

이 문서는 CKAD 모의고사 환경(`setup.sh`)을 실행하기 위해 필요한 도구들의 설치 방법을 안내합니다.
모든 명령어는 Ubuntu/Debian Linux 환경을 기준으로 작성되었습니다.

## 1. Docker 설치

컨테이너 런타임으로 Docker를 사용합니다.

```bash
# Docker 설치 스크립트 실행
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 현재 사용자를 docker 그룹에 추가 (로그아웃 후 다시 로그인 필요)
sudo usermod -aG docker $USER
rm get-docker.sh
```

## 2. Kubectl 설치

Kubernetes 클러스터 제어를 위한 도구입니다.

```bash
# 최신 안정화 버전 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 실행 권한 부여 및 이동
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 버전 확인
kubectl version --client
```

## 3. Kind (Kubernetes in Docker) 설치

로컬 Kubernetes 클러스터를 실행하기 위한 도구입니다.

```bash
# Kind 바이너리 다운로드 (v0.20.0 기준)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# 실행 권한 부여 및 이동
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 버전 확인
kind version
```

## 4. Helm 설치

Kubernetes 패키지 매니저입니다 (Traefik 설치 시 사용).

```bash
# Helm 설치 스크립트 실행
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 버전 확인
helm version
```

## 5. Cilium CLI 설치

Cilium CNI 설치 및 상태 확인을 위한 도구입니다.

```bash
# 최신 버전 다운로드 및 설치
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# 버전 확인
cilium version
```

---

## 설치 완료 후 확인

모든 도구가 설치되었다면 다음 명령어로 확인해 보세요:

```bash
docker --version
kubectl version --client
kind version
helm version
cilium version
```

위 도구들이 준비되었다면 `bash setup.sh`를 실행하여 실습 환경을 구축할 수 있습니다.

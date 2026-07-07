FROM node:20-bookworm

# システムパッケージのインストール
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    vim \
    zsh \
    socat \
    default-mysql-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

# pnpm のインストール
RUN corepack enable && corepack prepare pnpm@latest --activate

# node ユーザを vscode にリネーム（devcontainer の remoteUser に合わせる）
# node:20-bookworm には UID 1000 の node ユーザが存在するため、rename で対応
RUN apt-get update && apt-get install -y sudo \
    && usermod -l vscode -d /home/vscode -m node \
    && groupmod -n vscode node \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

# oh-my-zsh のインストール（vscode ユーザ用）
USER vscode
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
USER root

# ── kiro-cli インストール ──
# install.sh は /root/.local/bin に配置するため、vscode ユーザ用に /usr/local/bin へ移動
ARG KIRO_CLI_VERSION=latest
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) kiroArch="x86_64" ;; \
      arm64) kiroArch="aarch64" ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl --proto '=https' --tlsv1.2 -fsSL \
      "https://desktop-release.q.us-east-1.amazonaws.com/${KIRO_CLI_VERSION}/kirocli-${kiroArch}-linux.zip" \
      -o /tmp/kirocli.zip; \
    unzip -q /tmp/kirocli.zip -d /tmp; \
    /tmp/kirocli/install.sh --no-confirm --force; \
    mv /root/.local/bin/kiro-cli /usr/local/bin/kiro-cli; \
    chmod 755 /usr/local/bin/kiro-cli; \
    rm -rf /tmp/kirocli /tmp/kirocli.zip

# 作業ディレクトリ
WORKDIR /workspace

USER vscode

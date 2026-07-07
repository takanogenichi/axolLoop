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

# MinIO Client (mc) のインストール
RUN arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) mcArch="amd64" ;; \
      arm64) mcArch="arm64" ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://dl.min.io/client/mc/release/linux-${mcArch}/mc" -o /usr/local/bin/mc \
    && chmod 755 /usr/local/bin/mc

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
# aarch64 は glibc 2.39 要求のため musl ビルドを使用。
# Q_INSTALL_GLOBAL=1 で /usr/local/bin に直接配置（vscode ユーザから実行可能）。
ARG KIRO_CLI_VERSION=latest
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) kiroZip="kirocli-x86_64-linux.zip" ;; \
      arm64) kiroZip="kirocli-aarch64-linux-musl.zip" ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl --proto '=https' --tlsv1.2 -fsSL \
      "https://desktop-release.q.us-east-1.amazonaws.com/${KIRO_CLI_VERSION}/${kiroZip}" \
      -o /tmp/kirocli.zip; \
    unzip -q /tmp/kirocli.zip -d /tmp; \
    Q_INSTALL_GLOBAL=1 KIRO_CLI_SKIP_SETUP=1 /tmp/kirocli/install.sh; \
    rm -rf /tmp/kirocli /tmp/kirocli.zip

# 作業ディレクトリ
WORKDIR /workspace

USER vscode

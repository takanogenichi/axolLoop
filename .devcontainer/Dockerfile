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
    mysql-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

# pnpm のインストール
RUN corepack enable && corepack prepare pnpm@latest --activate

# oh-my-zsh のインストール（node ユーザ用）
USER node
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
USER root

# 作業ディレクトリ
WORKDIR /workspace

# node ユーザに sudo 権限を付与
RUN apt-get update && apt-get install -y sudo \
    && echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

USER node

#!/bin/bash
# Docker 自动安装脚本
# 适用于 Ubuntu/Debian 系统

set -euo pipefail

echo "========================================="
echo "  Docker & Docker Compose 自动安装脚本"
echo "========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用 sudo 或以 root 用户运行此脚本"
    exit 1
fi

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "错误: 无法检测操作系统类型"
    exit 1
fi

echo "检测到操作系统: $OS"

case "$OS" in
    ubuntu|debian) ;;
    *)
        echo "错误: 此脚本只支持 Ubuntu 或 Debian" >&2
        exit 1
        ;;
esac

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "检测到已有 Docker 与 Compose，跳过安装。"
    systemctl enable --now docker
    docker info >/dev/null
    docker --version
    docker compose version
    exit 0
fi

# 更新包索引
echo "[1/4] 更新包索引..."
apt-get update -y

# 安装依赖包
echo "[2/4] 安装依赖包..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加 Docker GPG 密钥
echo "[3/4] 添加 Docker GPG 密钥..."
install -m 0755 -d /etc/apt/keyrings
tmp_key=$(mktemp)
trap 'rm -f -- "$tmp_key"' EXIT
curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o "$tmp_key"
gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg "$tmp_key"
chmod a+r /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker Engine
echo "[4/4] 安装 Docker Engine..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动并启用 Docker 服务
systemctl enable --now docker

# 验证安装
echo ""
echo "========================================="
echo "  安装完成！版本信息："
echo "========================================="
docker --version
docker compose version

echo ""
echo "提示: 如需非 root 用户使用 Docker，请执行:"
echo "  sudo usermod -aG docker \$USER"
echo "  然后重新登录"

#!/bin/bash
# X-UI 一键部署脚本
# 基于 alireza7/x-ui Docker 镜像（上游 alireza0/x-ui 的 Docker 发布方式）

set -euo pipefail

echo "========================================="
echo "  X-UI 面板自动部署脚本"
echo "  基于: alireza7/x-ui"
echo "========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用 sudo 或以 root 用户运行此脚本"
    exit 1
fi

# 启动前检查 Docker 和 Compose，避免创建目录后才发现环境不可用
if ! command -v docker >/dev/null 2>&1; then
    echo "错误: Docker 未安装，请先运行 install-docker.sh"
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "错误: Docker 服务不可用，请先启动 Docker 并检查权限"
    exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
    echo "错误: Docker Compose 插件不可用，请先运行 install-docker.sh"
    exit 1
fi

# 可通过 XUI_DIR 指定部署目录；模板路径与调用脚本时的目录无关
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
COMPOSE_TEMPLATE="$SCRIPT_DIR/../configs/docker-compose.yml"
XUI_DIR="${XUI_DIR:-/opt/x-ui}"

echo ""
echo "[1/4] 创建 X-UI 工作目录..."
mkdir -p -- "$XUI_DIR/db" "$XUI_DIR/cert"
cd -- "$XUI_DIR"

echo "[2/4] 准备并验证 docker-compose.yml..."
if [ -e docker-compose.yml ]; then
    echo "保留已有 docker-compose.yml"
else
    if [ ! -f "$COMPOSE_TEMPLATE" ]; then
        echo "错误: 本地模板不存在: $COMPOSE_TEMPLATE"
        exit 1
    fi
    cp -- "$COMPOSE_TEMPLATE" docker-compose.yml
fi
if ! docker compose -f docker-compose.yml config --quiet; then
    echo "错误: Compose 配置验证失败，未启动容器"
    exit 1
fi

echo "[3/4] 启动 X-UI 容器..."
if ! docker compose -f docker-compose.yml up -d; then
    echo "错误: 容器启动失败，请检查日志: docker logs x-ui"
    exit 1
fi

# 等待容器启动
echo "[4/4] 等待容器启动（最多 30 秒）..."
for i in {1..30}; do
    CONTAINER_STATE=$(docker inspect --type container --format '{{.State.Status}}' x-ui 2>/dev/null || true)
    if [ "$CONTAINER_STATE" = "running" ]; then
        echo "✓ x-ui 容器状态为 running"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "✗ 容器启动超时，请检查日志: docker logs x-ui"
        exit 1
    fi
    sleep 1
done

echo ""
echo "========================================="
echo "  X-UI 容器已启动"
echo "========================================="
echo ""
echo "实际面板端口、访问路径和登录凭据请按 docs/03-panel-config.md 核对。"
echo "容器 running 不代表面板或代理连接已通过验收。"
echo ""
echo "修改面板端口可在面板设置中操作，或手动执行（示例 54322）："
echo "  docker exec x-ui /app/x-ui setting -port 54322"
echo "  docker restart x-ui"
echo "首次登录后请修改密码，并参考 docs/05-security-hardening.md 进行安全加固。"
echo ""
echo "查看日志: docker logs -f x-ui"
printf '停止服务: cd %q && docker compose -f docker-compose.yml down\n' "$XUI_DIR"
printf '重启服务: cd %q && docker compose -f docker-compose.yml restart\n' "$XUI_DIR"

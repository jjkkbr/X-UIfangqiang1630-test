#!/bin/bash
# X-UI 数据目录备份；在线 tar 不保证 SQLite 一致性，维护窗口请先停止 xui 服务。
set -euo pipefail

XUI_DIR="${XUI_DIR:-/opt/x-ui}"
BACKUP_DIR="${BACKUP_DIR:-/opt/x-ui-backups}"
RETENTION_DAYS=30
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# cron 会先解释百分号，命令由 /bin/sh 解释；单引号同时保护空格和 shell 字符。
cron_quote() {
    local value="$1"
    if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
        echo "错误: cron 路径不能包含换行。" >&2
        return 1
    fi
    value=${value//\'/\'\\\'\'}
    value=${value//%/\\%}
    printf "'%s'" "$value"
}

if [ "${1:-}" = "--print-cron" ] && [ "$#" -eq 1 ]; then
    CRON_XUI_DIR=$(cron_quote "$XUI_DIR")
    CRON_BACKUP_DIR=$(cron_quote "$BACKUP_DIR")
    CRON_SCRIPT=$(cron_quote "$SCRIPT_DIR/backup-db.sh")
    printf '0 2 * * * XUI_DIR=%s BACKUP_DIR=%s /bin/bash %s\n' \
        "$CRON_XUI_DIR" "$CRON_BACKUP_DIR" "$CRON_SCRIPT"
    exit 0
elif [ "$#" -ne 0 ]; then
    echo "用法: bash backup-db.sh [--print-cron]" >&2
    exit 1
fi

if [ ! -f "$XUI_DIR/db/x-ui.db" ]; then
    echo "错误: X-UI 数据库不存在: $XUI_DIR/db/x-ui.db" >&2
    exit 1
fi

umask 077
mkdir -p -- "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/x-ui-db-$TIMESTAMP-$$.tar.gz"

echo "正在备份数据库目录..."
if tar -czf "$BACKUP_FILE" -C "$XUI_DIR" db/; then
    echo "备份成功: $BACKUP_FILE"
else
    rm -f -- "$BACKUP_FILE"
    echo "备份失败，不会清理旧备份。" >&2
    exit 1
fi

find "$BACKUP_DIR" -maxdepth 1 -type f -name 'x-ui-db-*.tar.gz' \
    -mtime +"$RETENTION_DAYS" -delete
echo "已清理 $RETENTION_DAYS 天前的旧备份。"
echo "恢复前停止 xui 服务并保留当前 db 目录；具体步骤见 docs/06-troubleshooting.md。"
echo "生成每日 02:00 的任务行: /bin/bash '$SCRIPT_DIR/backup-db.sh' --print-cron"
echo "将输出放入 sudo crontab -e；定时任务使用服务器时区。"

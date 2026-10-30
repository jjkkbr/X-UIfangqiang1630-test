# Docker 部署指南

## 📦 部署方式选择

### 方式一：一键部署脚本（推荐）

```bash
# 1. 下载项目
git clone <your-repo-url>
cd x-ui-deployment

# 2. 赋予执行权限
chmod +x scripts/*.sh

# 3. 安装 Docker（如未安装）
sudo bash scripts/install-docker.sh

# 4. 部署 X-UI（读取本项目 configs/docker-compose.yml）
sudo bash scripts/deploy-xui.sh
```

完整项目需先上传到 Linux VPS。脚本默认部署到 `/opt/x-ui`，会保留已有的 `docker-compose.yml`；不会下载远程 Compose 模板或重置数据库中的账号、端口和路径。

### 方式二：手动部署

#### Step 1: 创建工作目录

```bash
mkdir -p /opt/x-ui/{db,cert}
cd /opt/x-ui
```

#### Step 2: 创建 docker-compose.yml

以下仅用于全新部署。已有 `/opt/x-ui/docker-compose.yml` 时先备份并保留现有配置；推荐从本项目 `configs/docker-compose.yml` 复制模板后按实际环境检查。

```yaml
services:
  xui:
    image: alireza7/x-ui@sha256:1dbf49e4307a2ceb543070108efce535cf1a06919269111fcc7a44d0de301989
    container_name: x-ui
    hostname: xui-server
    volumes:
      - ./db/:/etc/x-ui/
      - ./cert/:/root/cert/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
    tty: true
    network_mode: host
    restart: unless-stopped
```

#### Step 3: 启动服务

```bash
docker compose up -d
```

#### Step 4: 验证部署

```bash
# 检查容器状态
docker ps | grep x-ui

# 查看日志
docker logs -f x-ui

# 测试端口连通性
curl http://localhost:54321
```

全新数据库可能使用面板端口 `54321` 和上游初始化账号；严禁在生产环境保留默认凭据，首次登录后必须立即设置随机用户名和密码。已有数据库继续沿用原端口、账号和路径。开启 HTTPS 或自定义路径后，访问地址也要相应调整。日志可能包含登录失败时输入的凭据，分享前须脱敏。

## 🔧 常用管理命令

### 查看服务状态

```bash
docker ps | grep x-ui
docker stats x-ui
```

### 查看日志

```bash
# 实时日志
docker logs -f x-ui

# 最近 100 行日志
docker logs --tail 100 x-ui

# 带时间戳的日志
docker logs -t x-ui
```

### 重启服务

```bash
cd /opt/x-ui
docker compose restart
```

### 停止服务

```bash
cd /opt/x-ui
docker compose down
```

### 更新版本

```bash
cd /opt/x-ui
docker compose pull
docker compose up -d
```

### 备份数据库

```bash
# 以下命令在服务器的项目根目录执行
sudo bash scripts/backup-db.sh

# 自动备份：输出含实际脚本绝对路径的任务行
sudo bash scripts/backup-db.sh --print-cron
sudo crontab -e
```

将 `--print-cron` 输出的完整行加入 root 的 crontab，默认每天服务器时间凌晨 2 点运行。项目移动目录后须重新生成任务行。数据库默认位于 `/opt/x-ui/db`，备份保存到 `/opt/x-ui-backups`；在线压缩 SQLite 目录不能保证一致性，生产使用前应做恢复验证。

## 🌐 网络配置

### 防火墙规则

```bash
# 保留实际 SSH 端口，面板仅允许办公 IP（替换占位符）
sudo ufw allow <实际SSH端口>/tcp
sudo ufw allow from <办公IP> to any port <面板端口> proto tcp

# 开放代理端口（根据实际配置调整，例如 443）
sudo ufw allow 443/tcp

# 重载防火墙
sudo ufw reload
```

### 端口映射说明

X-UI 使用 `network_mode: host`，因此：
- 容器直接使用宿主机网络
- 无需额外端口映射
- 面板端口由 X-UI 的数据库设置决定（全新数据库通常为 54321）
- 代理端口在面板中配置（通常 443）

`XUI_PORT` 不是上游支持的端口设置环境变量。通过面板设置修改端口，或在容器运行时执行以下命令（示例改为 54322），随后同步更新访问地址与防火墙规则：

```bash
docker exec x-ui /app/x-ui setting -port 54322
docker restart x-ui
```

命令与容器内路径见上游 [main.go](https://github.com/alireza0/x-ui/blob/main/main.go) 和 [Dockerfile](https://github.com/alireza0/x-ui/blob/main/Dockerfile)。

## 📊 资源监控

### 查看资源占用

```bash
# CPU 和内存使用
docker stats x-ui

# 磁盘使用
du -sh /opt/x-ui/db/
```

### 性能优化建议

- **内存限制**：在 docker-compose.yml 中添加资源限制
- **日志轮转**：配置 Docker 日志最大大小
- **定期清理**：删除旧容器和镜像

```bash
# 清理未使用的容器
docker container prune

# 清理未使用的镜像
docker image prune -a
```

---

**下一步**：[面板配置说明 →](./03-panel-config.md)

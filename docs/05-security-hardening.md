# 安全加固建议

## 🔐 基础安全配置

### 1. 修改默认端口和凭据

**立即执行**（首次登录后）：

```bash
# 进入面板设置 → 面板配置
# - 修改面板端口（避免使用 54321、8080 等常见端口）
# - 设置自定义路径（如 /xui-admin-panel-2026）

# 进入面板设置 → 用户设置
# - 修改管理员用户名（不要用 admin）
# - 设置强密码（12+ 位，含大小写、数字、特殊字符）
```

### 2. 启用防火墙规则

```bash
# 仅开放必要端口
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 开放实际 SSH 端口；修改前保留当前会话，确认第二个会话可登录
sudo ufw allow <实际SSH端口>/tcp

# X-UI 面板只允许办公 IP（替换为实际 IP 和面板端口）
sudo ufw allow from <办公IP> to any port <面板端口> proto tcp

# 开放代理端口
sudo ufw allow 443/tcp

# 启用防火墙
sudo ufw enable

# 查看规则
sudo ufw status verbose
```

### 3. 配置 Fail2ban（SSH 防暴力破解）

本方案只保护 SSH。上游 X-UI 的登录失败日志没有来源 IP，不能据此建立可靠的面板封禁规则；也没有提供 `/opt/x-ui/db/x-ui.log` 或 `filter = x-ui`。面板应使用办公 IP 限制或 SSH 隧道保护，不能把 SSH jail 的状态当作面板防护验证。依据见 [X-UI 登录控制器](https://github.com/alireza0/x-ui/blob/main/web/controller/index.go) 与 [Fail2ban 默认 jail 配置](https://github.com/fail2ban/fail2ban/blob/master/config/jail.conf)。

```bash
# 安装
sudo apt install -y fail2ban

# 创建独立配置，使用发行版自带的 sshd 过滤器
sudo vim /etc/fail2ban/jail.d/x-ui-ssh.local
```

添加以下内容；将 `<实际SSH端口>` 替换成 sshd 当前监听的端口。若已有其他配置启用了 `[sshd]`，先检查并统一设置，避免互相覆盖。Ubuntu/Debian 的系统需通过 systemd journal 记录 SSH 登录事件：

```ini
[sshd]
enabled = true
port = <实际SSH端口>
filter = sshd
backend = systemd
maxretry = 3
bantime = 3600
```

先测试配置，测试通过后重启并验证 SSH jail：

```bash
sudo fail2ban-client -t
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
sudo fail2ban-client status sshd
```

---

## 🛡️ 进阶安全措施

### 4. SSH 密钥登录（禁用密码）

```bash
# 生成密钥对（在本地机器执行）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 复制公钥到服务器
ssh-copy-id user@server_ip

# 测试密钥登录
ssh user@server_ip

# 确认成功后，禁用密码登录
sudo vim /etc/ssh/sshd_config
```

先在第二个终端验证密钥登录成功，并保留当前 SSH 会话；然后修改以下配置，检查 `/etc/ssh/sshd_config.d/` 中是否有覆盖项。保持发行版已有的 PAM 配置：

```ini
PasswordAuthentication no
KbdInteractiveAuthentication no
```

验证语法并重载 SSH 服务。Ubuntu 常用服务名 `ssh`，其他发行版可能是 `sshd`，先用 `systemctl status ssh` 或 `systemctl status sshd` 确认：

```bash
sudo sshd -t
sudo systemctl reload ssh
# 若实际服务名是 sshd，改用 sudo systemctl reload sshd
```

重载后再次测试新会话可以登录，再关闭旧会话。

### 5. 定期更新系统

```bash
# 安装自动更新工具
sudo apt install -y unattended-upgrades

# 配置自动更新
sudo dpkg-reconfigure -plow unattended-upgrades

# 选择 "Yes" 启用自动安全更新
```

手动检查更新：

```bash
sudo apt update && sudo apt upgrade -y
```

### 6. 面板访问限制

如果之前已向所有地址开放面板端口，检查 `sudo ufw status numbered` 并删除对应的宽泛规则，保留办公 IP 规则；还要同步检查云服务商安全组。以下以 `8443` 为例，实际按面板端口调整：

```bash
# 仅允许特定 IP 访问面板端口
sudo ufw delete allow 8443/tcp
sudo ufw allow from <办公IP> to any port 8443 proto tcp

# 重载防火墙
sudo ufw reload
```

没有固定办公 IP 时，可关闭公网面板入站规则并使用 SSH 隧道（在本地执行，替换所有占位符），然后在浏览器访问 `http://127.0.0.1:15432/<面板路径>`：

```bash
ssh -N -p <实际SSH端口> -L 15432:127.0.0.1:<面板端口> user@server_ip
```

面板启用了 HTTPS 时使用 HTTPS 地址并校验证书。代理端口与面板端口独立管理。

---

## 📊 监控与审计

### 7. 审查运行日志

本项目通过 Docker 读取 X-UI 运行日志，不假定数据库目录中存在 `x-ui.log`：

```bash
docker logs --tail 200 --timestamps x-ui
```

上游可能在登录失败日志中记录输入的用户名和密码。日志及备份应限制访问；提交问题报告或分享日志前必须脱敏。登录失败记录缺少来源 IP，无法用于按 IP 封禁面板访问。

### 8. 数据库备份

参考 [backup-db.sh](../scripts/backup-db.sh) 脚本，建议：

- **频率**：每日凌晨自动备份
- **保留策略**：保留最近 30 天
- **存储位置**：本地 + 远程云存储（如 AWS S3）

在项目根目录先执行 `sudo bash scripts/backup-db.sh` 验证，再运行 `sudo bash scripts/backup-db.sh --print-cron`，将输出加入 `sudo crontab -e`。在线打包 SQLite 目录不保证数据库一致性，必须验证恢复；重要变更前应在维护窗口停止 X-UI 再备份。

### 9. 监控资源占用

```bash
# 安装监控工具
sudo apt install -y htop iotop nethogs

# 实时监控
htop        # CPU/内存
iotop       # 磁盘 I/O
nethogs     # 网络流量
```

设置告警阈值（示例）：

```bash
# 当内存使用超过 80% 时发送通知
#!/bin/bash
MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
if (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
    echo "警告: 内存使用率 ${MEMORY_USAGE}%" | mail -s "VPS 告警" admin@example.com
fi
```

---

## 🚨 应急响应

### 发现异常时的处理流程

#### Step 1: 隔离问题

```bash
# 停止 X-UI 服务
cd /opt/x-ui
docker compose stop xui

# 检查可疑进程
ps aux | grep xray
netstat -tunlp | grep LISTEN
```

#### Step 2: 分析日志

```bash
# 查看 SSH 日志（Ubuntu 的服务名通常为 ssh）
sudo journalctl -u ssh -u sshd --since "1 hour ago" --no-pager

# 查看 Docker 日志
docker logs --tail 200 x-ui
```

#### Step 3: 恢复服务

```bash
# 确认服务已停止，保留故障数据库，避免旧 WAL 等文件混入恢复目录
(
set -e
cd /opt/x-ui
docker compose stop xui
if [ -d /opt/x-ui/db ]; then
    sudo mv /opt/x-ui/db /opt/x-ui/db-before-restore-$(date +%Y%m%d_%H%M%S)
fi

# 从已验证、可信的备份恢复数据库（替换为实际文件名）
sudo tar -xzf /opt/x-ui-backups/x-ui-db-YYYYMMDD_HHMMSS.tar.gz -C /opt/x-ui/
test -f /opt/x-ui/db/x-ui.db

# 重启服务
cd /opt/x-ui
docker compose up -d
docker logs --tail 100 x-ui
)
```

只有解压成功且确认存在正确的 `db/` 内容后才启动服务；解压失败时先修复或回退已保留的故障副本。验证原面板账号、配置和客户端连接后再安排故障副本清理。

#### Step 4: 加强防护

- 立即修改所有密码
- 检查防火墙规则
- 更新系统和软件到最新版本
- 审查访问日志，封禁可疑 IP

---

## ✅ 安全检查清单

部署完成后，请逐项确认：

- [ ] 默认端口已修改
- [ ] 管理员用户名和密码已更改
- [ ] SSH 密钥登录已启用，密码登录已禁用
- [ ] 防火墙规则已配置（仅开放必要端口）
- [ ] Fail2ban 的 `sshd` jail 已通过配置测试并运行
- [ ] 面板使用办公 IP 限制或 SSH 隧道，公网宽泛访问规则已移除
- [ ] 系统自动更新已启用
- [ ] 数据库备份脚本已配置并测试
- [ ] 日志监控已设置
- [ ] Telegram Bot 通知已配置（可选）
- [ ] 团队成员权限已分配（如有多人使用）

---

**下一步**：[常见问题排查 →](./06-troubleshooting.md)

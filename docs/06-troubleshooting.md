# 常见问题排查

## 🔍 诊断工具

### 快速检查脚本

```bash
#!/bin/bash
# 保存为 check-xui.sh

echo "========================================="
echo "  X-UI 系统健康检查"
echo "========================================="

# 1. Docker 状态
echo "[1] Docker 服务状态:"
systemctl is-active docker

# 2. 容器状态
echo -e "\n[2] X-UI 容器状态:"
docker ps | grep x-ui || echo "❌ 容器未运行"

# 3. 端口监听
echo -e "\n[3] 端口监听情况:"
netstat -tunlp | grep -E '54321|443' || ss -tunlp | grep -E '54321|443'

# 4. 磁盘空间
echo -e "\n[4] 磁盘使用率:"
df -h /opt/x-ui

# 5. 内存使用
echo -e "\n[5] 内存使用情况:"
free -h

# 6. 最近日志
echo -e "\n[6] 最近 20 条日志:"
docker logs --tail 20 x-ui 2>&1 | tail -20

echo -e "\n========================================="
echo "  检查完成"
echo "========================================="
```

使用方法：

```bash
chmod +x check-xui.sh
sudo bash check-xui.sh
```

---

## ❌ 常见错误及解决方案

### 问题 1：Docker 容器无法启动

**症状**：
```bash
docker ps  # 看不到 x-ui 容器
docker logs x-ui  # 显示错误信息
```

**可能原因及解决**：

#### 原因 A：端口冲突

```bash
# 检查端口占用
sudo lsof -i :54321
sudo netstat -tunlp | grep 54321

# 确认冲突进程所属服务，保留已有服务；通过面板设置修改 X-UI 端口
# 容器正在运行时，也可用以下 CLI（示例 54322）
docker exec x-ui /app/x-ui setting -port 54322
docker restart x-ui
```

不要在 Compose 中添加 `XUI_PORT`：上游读取数据库中的面板设置，不支持该变量。如果容器因端口冲突持续退出，可在 `/opt/x-ui` 执行 `docker compose stop xui`，再执行 `docker compose run --rm --no-deps xui /app/x-ui setting -port 54322` 修改持久化数据库，最后 `docker compose up -d`。按新端口同步更新办公 IP 防火墙规则和访问地址。

#### 原因 B：权限不足

```bash
# 检查 Docker 权限
groups $USER | grep docker

# 如无 docker 组，添加用户
sudo usermod -aG docker $USER
# 重新登录生效
```

#### 原因 C：镜像拉取失败

```bash
# 手动拉取镜像
docker pull alireza7/x-ui@sha256:1dbf49e4307a2ceb543070108efce535cf1a06919269111fcc7a44d0de301989

# 检查网络连接
ping github.com
curl https://registry.hub.docker.com
```

---

### 问题 2：面板无法访问

**症状**：浏览器打开 `http://IP:54321` 显示连接超时或拒绝

**排查步骤**：

#### Step 1: 检查容器是否运行

```bash
docker ps | grep x-ui
```

如未运行，查看日志：

```bash
docker logs x-ui
```

#### Step 2: 检查防火墙

```bash
# 查看防火墙状态
sudo ufw status

# 仅放行办公 IP（替换为实际 IP 和面板端口）
sudo ufw allow from <办公IP> to any port <面板端口> proto tcp
sudo ufw reload
```

#### Step 3: 测试本地连通性

```bash
# 在服务器上测试
curl http://localhost:54321

# 如本地可访问但外部不行，检查云服务商安全组
```

#### Step 4: 检查云服务商安全组

登录 VPS 控制台，确认：
- 入站规则已放行面板端口
- 出站规则无限制

使用实际面板端口和路径；已有数据库不会在重部署时恢复为 `54321` 或 `admin/admin`。面板采用 SSH 隧道访问时，公网面板端口关闭是预期行为，应从隧道检查访问。

---

### 问题 3：客户端连接失败

**症状**：Hiddify/Clash 显示连接超时或认证失败

**排查步骤**：

#### Step 1: 验证节点参数

从 X-UI 面板重新复制分享链接，确认：
- 节点地址为服务器公网 IP 或域名，而非 SSH 面板隧道的 `127.0.0.1`
- UUID 正确
- Flow 为 `xtls-rprx-vision`
- Public Key 非空且与面板一致，不能使用 Private Key 替代
- Short ID 与服务端允许值一致
- SNI 域名正确（如 `www.cloudflare.com`）

`PublicKey 属性无效` 表示客户端公钥缺失或格式无效，属于本地配置校验失败。先重新复制与服务端私钥配对的 Reality 公钥，再测试网络。通过 SSH 隧道访问面板时，默认分享地址可能是 `127.0.0.1`；在入站 **外部代理** 页设置公网导出地址，或导入后修改客户端地址。

如 **Get New Cert** 显示 `AxiosError: Network Error`，先确认 SSH 隧道仍在运行并重新登录面板，再检查开发者工具中的 `/server/getNewX25519Cert` 请求。该提示本身不证明 Reality 算法或 Xray 版本不兼容。已确认的容器内二进制可执行 `docker exec x-ui /app/bin/xray-linux-amd64 x25519`，输出包含私钥，只在受保护的本地终端查看，不要复制进日志或 Issue。

#### Step 2: 测试服务器端口

```bash
# 在客户端机器执行
telnet <服务器IP> 443

# 或使用 nmap
nmap -p 443 <服务器IP>
```

如端口不通，检查服务器防火墙。

TCP 端口可达后，还应使用已启动的客户端实际测试：

```powershell
curl.exe --proxy socks5h://127.0.0.1:10808 --connect-timeout 10 --max-time 20 https://www.cloudflare.com/cdn-cgi/trace
```

请求成功后检查响应中的 `ip=` 是否为服务器实际出口 IP。客户端分流规则可能把测试请求设为直连；必要时临时选择全局代理路由后重试。仅返回 HTTP 200 不能单独证明流量经过该节点。

显式代理测试成功但浏览器仍直连时，检查系统代理是否启用，以及是否被另一个代理客户端覆盖。

#### Step 3: 检查 Reality 配置

在 X-UI 面板确认：
- Reality 已开启
- Dest 和 Server Names 配置正确
- Private Key 和 Public Key 匹配

#### Step 4: 更换 uTLS Fingerprint

在客户端设置中尝试不同的指纹：
- Chrome（推荐）
- Firefox
- Safari
- iOS

---

### 问题 4：部分网站无法访问

**症状**：能上网，但某些特定网站（如 Amazon、Shopify）打不开

**可能原因及解决**：

#### 原因 A：DNS 污染

```bash
# 在客户端中自定义 DNS
# Hiddify: 设置 → DNS → 自定义 DNS
# 推荐使用: 8.8.8.8 (Google) 或 1.1.1.1 (Cloudflare)
```

#### 原因 B：路由规则问题

检查 Clash 配置中的规则：

```yaml
rules:
  - DOMAIN-SUFFIX,amazon.com,代理
  - DOMAIN-SUFFIX,shopify.com,代理
  - GEOIP,CN,DIRECT  # 确保中国大陆直连
  - MATCH,代理
```

#### 原因 C：IP 被目标网站封锁

```bash
# 测试 IP 信誉
curl https://ipinfo.io/<你的VPS_IP>

# 如 IP 被列入黑名单，联系 VPS 提供商更换 IP
```

---

### 问题 5：速度慢或不稳定

**症状**：延迟高、下载速度慢、频繁断线

**排查步骤**：

#### Step 1: 测试带宽

```bash
# 在 VPS 上测试网速
curl -s https://raw.githubusercontent.com/sivelabs/speedtest-cli/master/speedtest.py | python3

# 或使用 speedtest-cli
sudo apt install -y speedtest-cli
speedtest-cli
```

#### Step 2: 检查资源占用

```bash
# CPU 和内存
htop

# 网络流量
nethogs

# 磁盘 I/O
iotop
```

#### Step 3: 优化 Xray 配置

在 X-UI 面板中：
- 减少同时在线用户数
- 启用 mux（多路复用）
- 调整缓冲区大小

#### Step 4: 选择更优节点

- 选择离目标市场地理位置更近的 VPS
- 升级带宽套餐（建议 10Mbps+）
- 考虑使用 CN2 GIA 等优质线路

---

### 问题 6：数据库损坏或丢失

**症状**：面板登录后配置全部消失

**恢复步骤**：

#### Step 1: 从备份恢复

```bash
# 列出备份文件
ls -lh /opt/x-ui-backups/

# 停止服务，先保留现有数据库目录（存在时），避免残留 WAL 文件混入
(
set -e
cd /opt/x-ui
docker compose stop xui
if [ -d /opt/x-ui/db ]; then
    sudo mv /opt/x-ui/db /opt/x-ui/db-before-restore-$(date +%Y%m%d_%H%M%S)
fi

# 恢复已验证、可信的备份（替换为实际备份文件名）
sudo tar -xzf /opt/x-ui-backups/x-ui-db-YYYYMMDD_HHMMSS.tar.gz -C /opt/x-ui/
test -f /opt/x-ui/db/x-ui.db

# 恢复成功后启动并检查日志，再验证面板配置
docker compose up -d
docker logs --tail 100 x-ui
)
```

恢复包需要包含 `db/` 目录。停止服务后才覆盖数据库；若解压失败，先修复或回退故障副本，不能直接启动空数据库。在线压缩 SQLite 目录不保证一致性，应事先验证备份可恢复。

#### Step 2: 如无备份

只能重新配置所有节点和用户。

**预防措施**：
- 务必配置自动备份：在服务器项目根目录执行 `sudo bash scripts/backup-db.sh --print-cron`，将输出的完整行加入 `sudo crontab -e`
- 定期将备份文件复制到远程存储

---

### 问题 7：Telegram Bot 不工作

**症状**：收不到通知或无法通过 Bot 管理

**排查步骤**：

#### Step 1: 验证 Token 和 Chat ID

```bash
# 测试 Bot API
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# 应返回 Bot 信息
```

#### Step 2: 检查网络连接

```bash
# 测试 Telegram API 连通性
curl https://api.telegram.org
```

如无法访问，可能需要额外配置代理。

#### Step 3: 确认 Chat ID 正确

向 Bot 发送消息后，访问：

```
https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
```

从返回的 JSON 中确认 `"chat":{"id":123456789}` 与配置一致。

---

## 📞 获取帮助

### 官方资源

- [alireza0/x-ui GitHub Issues](https://github.com/alireza0/x-ui/issues)
- [Xray 官方文档](https://xtls.github.io/)
- [Hiddify 社区](https://t.me/hiddify)

### 提供有效的问题报告

提交 Issue 时请包含：

1. **系统信息**：
   ```bash
   uname -a
   docker --version
   docker compose version
   ```

2. **错误日志**：
   ```bash
   docker logs --tail 100 x-ui
   ```

   上游登录失败日志可能包含输入的用户名和密码，分享前务必脱敏；不要假定 `/opt/x-ui/db/x-ui.log` 存在。

3. **配置文件**：脱敏后的 `docker-compose.yml`

4. **复现步骤**：详细描述操作步骤

5. **预期与实际结果**：对比说明

---

## ✅ 维护最佳实践

### 定期检查清单（每周）

- [ ] 查看系统资源使用情况
- [ ] 审查操作日志，检查异常登录
- [ ] 测试关键业务网站连通性
- [ ] 验证备份文件完整性

### 每月任务

- [ ] 更新 X-UI 到最新版本
- [ ] 更新系统和依赖包
- [ ] 轮换密码和密钥
- [ ] 清理旧日志和临时文件

### 每季度任务

- [ ] 全面安全审计
- [ ] 性能基准测试
- [ ] 灾难恢复演练
- [ ] 评估 VPS 性价比，必要时迁移

---

**回到首页**：[README →](../README.md)

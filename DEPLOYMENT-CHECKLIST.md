# X-UI 部署快速参考清单

> 本清单用于指导小规模、自托管、经授权的 X-UI 网络网关部署。

---

## 📋 部署前准备

### 硬件与网络
- [ ] VPS 已购买（推荐 Ubuntu 20.04+ / Debian 11+）
- [ ] 内存 ≥ 1GB，存储 ≥ 10GB
- [ ] 公网 IP 已分配
- [ ] SSH 密钥已配置（禁用密码登录）

### 软件环境
- [ ] Docker 已安装（运行 `docker --version` 验证）
- [ ] Docker Compose 已安装（运行 `docker compose version` 验证）
- [ ] 系统已更新（`sudo apt update && sudo apt upgrade -y`）

---

## 🚀 部署步骤

### Step 1: 将完整项目上传到 VPS

将本地目录中的全部文件上传到 Linux VPS，并进入项目根目录。若已有项目仓库，也可使用以下命令（先替换仓库地址）：
```bash
git clone <your-repo-url>
cd x-ui-deployment
```

### Step 2: 安装 Docker（如未安装）
```bash
chmod +x scripts/*.sh
sudo bash scripts/install-docker.sh
```

### Step 3: 部署 X-UI
```bash
sudo bash scripts/deploy-xui.sh
```

记录以下信息：
- 面板访问地址：以实际端口、路径和 HTTPS 设置为准；全新数据库通常使用端口 `54321`
- 管理员账号：全新数据库可能初始化为 `admin` / `admin`，已有数据库继续使用原账号
- 部署脚本使用本地 Compose 模板，保留已有部署配置和数据库

### Step 4: 首次登录并修改配置
- [ ] 访问面板并登录
- [ ] **立即修改管理员用户名和密码**
- [ ] 修改面板端口（建议非标准端口）
- [ ] 可选：设置自定义路径

### Step 5: 配置 VLESS + Reality 节点
- [ ] 进入 **入站列表** → **添加入站**
- [ ] 协议选择：**VLESS**
- [ ] 端口：**443**
- [ ] Reality：**开启**
- [ ] Dest：`www.cloudflare.com:443`
- [ ] Server Names：`www.cloudflare.com`
- [ ] 点击 **Get New Cert** 生成密钥
- [ ] Flow：`xtls-rprx-vision`
- [ ] 添加客户端用户（记录 UUID）
- [ ] 保存配置

### Step 6: 配置防火墙

将占位符替换为实际值，先保留当前 SSH 会话并确认 SSH 端口可达。面板优先只允许办公 IP 访问：

```bash
sudo ufw allow <实际SSH端口>/tcp
sudo ufw allow from <办公IP> to any port <面板端口> proto tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Step 7: 配置自动备份

在服务器的项目根目录执行，复制输出的完整任务行到 root crontab。项目后续若移动目录，需要重新生成并更新任务行。

```bash
sudo bash scripts/backup-db.sh
sudo bash scripts/backup-db.sh --print-cron
sudo crontab -e
```

---

## 📱 客户端配置

### Hiddify（推荐）
- [ ] 下载安装对应平台客户端
- [ ] 从面板复制分享链接或扫描二维码
- [ ] 确认 Flow 为 `xtls-rprx-vision`
- [ ] 测试连接并验证 IP

### Clash（高级用户）
- [ ] 使用 `clients/clash-config.yaml` 模板
- [ ] 替换 `<服务器IP>`、`<UUID>`、`<Public Key>`
- [ ] 导入配置文件到 Clash 客户端
- [ ] 选择代理组并测试

---

## 🔐 安全加固

- [ ] SSH 密钥登录已启用，密码登录已禁用
- [ ] Fail2ban 的 `sshd` jail 已验证（仅保护 SSH；面板另用办公 IP 限制或 SSH 隧道）
- [ ] 系统自动更新已启用
- [ ] 数据库手动备份成功，root 定时任务使用正确的脚本路径
- [ ] Telegram Bot 通知已配置（可选）

---

## ✅ 验收测试

### 基础连通性
- [ ] 面板可正常访问
- [ ] 客户端连接成功
- [ ] IP 切换验证通过（访问 ipinfo.io）

### 业务场景测试
- [ ] Amazon Seller Central 可访问
- [ ] Shopify Admin 可访问
- [ ] PayPal Business 可访问
- [ ] Google Analytics 可访问
- [ ] Facebook Business 可访问

### 性能测试
- [ ] 延迟 < 300ms
- [ ] 下载速度满足业务需求
- [ ] 多设备同时连接稳定

---

## 📞 应急联系

如遇问题，参考以下文档：
- [常见问题排查](docs/06-troubleshooting.md)
- [alireza0/x-ui GitHub Issues](https://github.com/alireza0/x-ui/issues)

---

**最后更新**：2026-10-13
**版本**：v1.1

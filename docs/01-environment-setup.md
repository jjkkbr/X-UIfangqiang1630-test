# 环境准备清单

## 🖥️ VPS 选择建议

### 推荐服务商

| 服务商 | 优点 | 月付价格 | 备注 |
|--------|------|----------|------|
| Vultr | 全球节点多，网络稳定 | $5-10 | 支持支付宝 |
| DigitalOcean | 文档完善，社区活跃 | $6-12 | 新手友好 |
| Linode | 性能稳定，技术支持好 | $5-10 | 适合企业用户 |
| AWS Lightsail | 与 AWS 生态集成 | $3.5-5 | 适合已有 AWS 账户 |

### 系统要求

- **操作系统**：Ubuntu 20.04+ / Debian 11+（推荐）
- **内存**：最低 1GB，推荐 2GB+
- **存储**：至少 10GB 可用空间
- **架构**：amd64 / arm64 / armv7

### 网络要求

- 公网 IP 地址
- 防火墙允许入站连接（后续需开放面板端口和代理端口）
- DNS 解析正常（用于访问 GitHub API）

## 🔧 系统初始化

### 1. 更新系统包

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. 安装必要工具

```bash
sudo apt install -y curl wget git vim net-tools ufw
```

### 3. 配置时区和时间同步

```bash
sudo timedatectl set-timezone Asia/Shanghai
sudo apt install -y chrony
sudo systemctl enable chrony
sudo systemctl start chrony
```

### 4. 创建专用用户（可选但推荐）

```bash
sudo adduser xui-admin
sudo usermod -aG docker xui-admin
```

## 📦 Docker 环境准备

### 检查是否已安装 Docker

```bash
docker --version
docker compose version
```

如果未安装，执行下一章节的自动安装脚本。

## 🔐 安全基线检查

在部署前确认以下安全措施已到位：

- [ ] SSH 密钥登录已配置（禁用密码登录）
- [ ] 系统防火墙（UFW/iptables）已启用
- [ ] fail2ban 的 `sshd` jail 已安装并验证（保护 SSH；面板另用办公 IP 限制或 SSH 隧道）
- [ ] 定期自动更新已启用（unattended-upgrades）

---

**下一步**：[Docker 部署指南 →](./02-docker-deployment.md)

# 项目结构说明

```
x-ui-deployment/
│
├── README.md                          # 项目总览和快速入门指南
├── DEPLOYMENT-CHECKLIST.md            # 部署快速参考清单（打印版）
├── PROJECT-STRUCTURE.md               # 本文件：项目结构说明
│
├── docs/                              # 📚 详细文档目录
│   ├── 01-environment-setup.md        # 环境准备：VPS选择、系统初始化、安全基线
│   ├── 02-docker-deployment.md        # Docker部署：一键脚本、手动部署、管理命令
│   ├── 03-panel-config.md             # 面板配置：首次登录、添加入站、流量管理、TG Bot
│   ├── 04-client-setup.md             # 客户端连接：Hiddify/Clash 配置、测试方法
│   ├── 05-security-hardening.md       # 安全加固：防火墙、Fail2ban、SSH密钥、监控
│   └── 06-troubleshooting.md          # 问题排查：常见错误、诊断工具、应急响应
│
├── scripts/                           # 🛠️ 自动化脚本目录
│   ├── install-docker.sh              # Docker & Docker Compose 自动安装脚本
│   ├── deploy-xui.sh                  # X-UI 一键部署脚本（基于 alireza7/x-ui）
│   └── backup-db.sh                   # 数据库定时备份脚本（保留30天）
│
├── configs/                           # ⚙️ 配置文件模板目录
│   ├── docker-compose.yml             # Docker Compose 配置模板
│   └── xray-template.json             # Xray 核心配置模板（供高级用户参考）
│
└── clients/                           # 📱 客户端配置示例目录
    ├── hiddify-config.md              # Hiddify 客户端详细配置指南
    └── clash-config.yaml              # Clash 配置文件示例（含电商路由规则）
```

---

## 📂 目录说明

### `docs/` - 详细文档

按部署流程顺序编号，建议按顺序阅读：

1. **01-environment-setup.md**
   - VPS 选择建议（服务商对比表）
   - 系统初始化步骤
   - 安全基线检查清单

2. **02-docker-deployment.md**
   - 一键部署脚本使用方法
   - 手动部署详细步骤
   - 常用管理命令（查看日志、重启、更新等）

3. **03-panel-config.md**
   - 首次登录和修改默认凭据
   - 添加 VLESS + Reality + Vision 节点（图文步骤）
   - 流量管理和 Telegram Bot 集成

4. **04-client-setup.md**
   - Hiddify 客户端配置（扫码/粘贴/手动）
   - Clash 客户端配置（含 YAML 示例）
   - 连接测试和业务场景验证

5. **05-security-hardening.md**
   - 基础安全：修改端口密码、防火墙、Fail2ban
   - 进阶措施：SSH 密钥、自动更新、IP 限制
   - 监控审计和应急响应流程

6. **06-troubleshooting.md**
   - 诊断工具脚本
   - 7 类常见问题及解决方案
   - 维护最佳实践清单

### `scripts/` - 自动化脚本

脚本需在 Linux VPS 上运行。Windows 复制文件不保留 Linux 执行权限，可用 `sudo bash scripts/<脚本名>.sh` 调用，或先执行 `chmod +x scripts/*.sh`：

- **install-docker.sh**
  - 自动检测操作系统（Ubuntu/Debian）
  - 卸载旧版本 Docker
  - 安装最新版 Docker Engine 和 Compose Plugin
  - 验证安装并输出提示信息

- **deploy-xui.sh**
  - 检查 Docker 是否已安装
  - 创建工作目录 `/opt/x-ui`
  - 从项目内 `configs/docker-compose.yml` 复制部署配置，不依赖远程模板下载
  - 保留 `/opt/x-ui/docker-compose.yml` 中的已有配置
  - 启动容器并验证状态
  - 输出检查命令；面板端口、路径和账号以现有数据库设置为准

- **backup-db.sh**
  - 压缩备份 `/opt/x-ui/db/` 目录
  - 保存到 `/opt/x-ui-backups/`
  - 自动清理 30 天前的旧备份
  - 使用 `sudo bash scripts/backup-db.sh --print-cron` 生成含实际脚本绝对路径的 root crontab 任务行

### `configs/` - 配置文件模板

- **docker-compose.yml**
  - 基于 alireza0/x-ui 上游项目的 alireza7/x-ui Docker 镜像
  - 使用 `network_mode: host` 简化网络配置
  - 挂载数据卷持久化数据库和证书
  - 包含可选的资源限制注释

- **xray-template.json**
  - VLESS + Reality 完整配置示例
  - 包含详细的字段注释
  - 供高级用户自定义路由规则和出站配置

### `clients/` - 客户端配置示例

- **hiddify-config.md**
  - Hiddify 各平台下载安装链接
  - 三种添加节点方式（扫码/粘贴/手动）
  - DNS、路由、连接选项详细配置
  - 多设备同步方法

- **clash-config.yaml**
  - 完整的 Clash 配置文件
  - 提供可替换的通用路由模板
  - 包含代理组、自动测速、负载均衡配置
  - 替换占位符后即可直接使用

---

## 🎯 使用建议

### 新手用户
1. 阅读 `README.md` 了解项目概况
2. 打印 `DEPLOYMENT-CHECKLIST.md` 作为操作清单
3. 按顺序阅读 `docs/01-06` 文档
4. 执行 `scripts/deploy-xui.sh` 完成部署
5. 参考 `clients/hiddify-config.md` 配置客户端

### 高级用户
1. 直接查看 `configs/docker-compose.yml` 自定义配置
2. 参考 `configs/xray-template.json` 调整路由规则
3. 修改 `clients/clash-config.yaml` 适配特定业务需求
4. 根据 `docs/05-security-hardening.md` 进行深度加固

### 运维团队
1. 在服务器的项目根目录用 `sudo bash scripts/backup-db.sh --print-cron` 生成任务行，再用 `sudo crontab -e` 添加到 root 定时任务
2. 定期执行 `docs/06-troubleshooting.md` 中的健康检查脚本
3. 按照"维护最佳实践"章节执行周/月/季度任务
4. 建立维护文档，记录部署环境特定的配置和问题

---

## 📝 文档维护

如发现文档错误或需要补充内容：

1. 提交 Issue 描述问题
2. Fork 仓库并修改对应文档
3. 提交 Pull Request 说明修改内容
4. 等待审核合并

**最后更新**：2026-10-13
**维护者**：项目维护者

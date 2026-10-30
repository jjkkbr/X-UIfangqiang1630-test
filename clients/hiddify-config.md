# Hiddify 客户端配置指南

## 📥 下载安装

### 官方下载渠道

| 平台 | 下载地址 | 备注 |
|------|---------|------|
| Windows | [hiddify.com](https://hiddify.com/) | 支持 Win10/11 |
| macOS | [hiddify.com](https://hiddify.com/) | Intel & Apple Silicon |
| Android | [Google Play](https://play.google.com/store/apps/details?id=app.hiddify.com) / [GitHub Releases](https://github.com/hiddify/hiddify-next/releases) | Android 8.0+ |
| iOS | [App Store](https://apps.apple.com/app/hiddify) | iOS 15+ |
| Linux | [GitHub Releases](https://github.com/hiddify/hiddify-next/releases) | AppImage / Deb |

---

## 🔗 添加节点

### 方式一：扫码添加（推荐）

1. 打开 X-UI 面板 → **入站列表**
2. 找到目标节点，点击 **操作** → **二维码**
3. 打开 Hiddify，点击主界面 **+** 按钮
4. 选择 **扫描二维码**
5. 对准屏幕上的二维码
6. 确认节点信息后点击 **保存**

### 方式二：粘贴分享链接

1. 在 X-UI 面板点击 **操作** → **复制**
2. 打开 Hiddify，点击 **+** → **从剪贴板导入**
3. 自动识别并添加节点

### 方式三：手动配置

1. 点击 **+** → **手动添加**
2. 选择协议：**VLESS**
3. 填写以下参数：

| 字段 | 值 | 说明 |
|------|-----|------|
| 名称 | self-hosted-vless | 自定义备注 |
| 地址 | `<服务器IP>` | VPS 公网 IP |
| 端口 | `443` | 面板中配置的代理端口 |
| UUID | `<从面板复制>` | 客户端 UUID |
| Flow | `xtls-rprx-vision` | **必须选择此项** |
| 传输协议 | TCP | - |
| 安全类型 | Reality | - |
| SNI | `www.cloudflare.com` | 与面板配置一致 |
| Public Key | `<从面板复制>` | Reality 公钥 |
| Short ID | `<留空或填写>` | 可选 |
| uTLS Fingerprint | Chrome | 推荐 |

4. 点击 **保存**

---

## ⚙️ 高级设置

### DNS 配置

为避免 DNS 污染，建议自定义 DNS：

1. 进入 **设置** → **DNS**
2. 启用 **自定义 DNS**
3. 添加以下 DNS 服务器：
   - `8.8.8.8` (Google)
   - `1.1.1.1` (Cloudflare)
   - `9.9.9.9` (Quad9)

### 路由规则

1. 进入 **设置** → **路由**
2. 选择模式：**绕过局域网和中国大陆 IP**
3. 可选：添加自定义规则
   ```
   # 强制代理的域名
   DOMAIN-SUFFIX,amazon.com
   DOMAIN-SUFFIX,shopify.com
   DOMAIN-SUFFIX,paypal.com
   
   # 直连的域名
   DOMAIN-SUFFIX,baidu.com
   DOMAIN-SUFFIX,taobao.com
   ```

### 连接选项

- **MUX 多路复用**：✅ 启用（提高并发性能）
- **UDP 代理**：✅ 启用（支持语音/视频通话）
- **系统代理**：✅ 启用（全局代理）

---

## 🧪 测试连接

### 延迟测试

1. 在节点列表中长按节点（移动端）或右键（桌面端）
2. 选择 **测试延迟**
3. 查看响应时间（建议 < 300ms）

### 速度测试

1. 连接节点
2. 进入 **工具** → **速度测试**
3. 查看下载/上传速度

### IP 验证

1. 连接节点
2. 打开浏览器访问 [ipinfo.io](https://ipinfo.io/)
3. 确认显示的 IP 为 VPS IP，且地理位置正确

### 业务场景测试

针对你的授权业务范围，测试必要的目标服务：

- ✅ Amazon Seller Central: `sellercentral.amazon.com`
- ✅ Shopify Admin: `admin.shopify.com`
- ✅ PayPal Business: `business.paypal.com`
- ✅ Google Analytics: `analytics.google.com`
- ✅ Facebook Business: `business.facebook.com`

确保页面加载流畅，无超时或证书错误。

---

## 🔧 常见问题

### Q1: 连接后立即断开

**解决**：
- 确认 Flow 设置为 `xtls-rprx-vision`
- 检查 Public Key 是否与面板一致
- 尝试更换 uTLS Fingerprint（Chrome/Firefox/Safari）

### Q2: 部分网站打不开

**解决**：
- 检查路由规则是否设置为"绕过中国大陆"
- 自定义 DNS 为 `8.8.8.8` 或 `1.1.1.1`
- 清除浏览器缓存和 DNS 缓存

### Q3: 速度慢

**解决**：
- 测试不同时间段的速度（避开高峰）
- 检查 VPS 带宽是否充足
- 尝试启用 MUX 多路复用
- 考虑升级 VPS 套餐或更换线路

### Q4: 无法扫码

**解决**：
- 使用"从剪贴板导入"方式
- 或在桌面端使用"手动配置"方式
- 确保二维码完整清晰（可放大截图）

---

## 📱 多设备同步

Hiddify 目前不支持账号同步，如需在多设备使用：

1. **方法一**：在每个设备上分别添加相同的节点配置
2. **方法二**：导出配置文件（桌面端），手动复制到移动设备

### 导出配置（桌面端）

1. 右键节点 → **导出配置**
2. 保存为 `.json` 文件
3. 通过邮件/云盘发送到移动设备
4. 在移动端选择 **导入配置**

---

**返回主文档**：[README →](../README.md)

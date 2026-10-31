# 客户端连接指南

## 📱 推荐客户端

| 平台 | 推荐客户端 | 下载链接 |
|------|-----------|----------|
| Windows | Hiddify / Clash Verge | [Hiddify](https://hiddify.com/) / [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev) |
| macOS | Hiddify / ClashX Pro | [Hiddify](https://hiddify.com/) / [ClashX](https://github.com/yichengchen/ClashX) |
| Android | Hiddify / v2rayNG | [Hiddify](https://hiddify.com/) / [v2rayNG](https://github.com/2dust/v2rayNG) |
| iOS | Hiddify / Shadowrocket | [Hiddify](https://hiddify.com/) / App Store |
| Linux | Hiddify CLI / Clash | [Hiddify](https://hiddify.com/) |

---

## 🔗 获取节点信息

### 方式一：扫描二维码

1. 在 X-UI 面板进入 **入站列表**
2. 找到对应的节点，点击 **操作** → **二维码**
3. 使用客户端扫码添加

### 方式二：复制分享链接

1. 在 X-UI 面板点击 **操作** → **复制**
2. 获得类似格式的链接：
   ```
   vless://uuid@server_ip:443?type=tcp&security=reality&flow=xtls-rprx-vision&sni=www.cloudflare.com&pbk=public_key&sid=short_id&fp=chrome#remark
   ```
3. 在客户端中选择 **从剪贴板导入** 或手动粘贴

如果通过 SSH 隧道访问 X-UI，导入后首先检查节点地址：应为服务器公网 IP 或域名，不能是面板隧道地址 `127.0.0.1`。同时确认 Reality 公钥（链接中的 `pbk`）非空。服务端私钥不能填入客户端公钥字段。

### 方式三：手动配置

如果上述方式不可用，可手动填写参数：

| 参数 | 值 | 说明 |
|------|-----|------|
| 协议 | VLESS | - |
| 地址 | `<服务器IP>` | 你的 VPS IP 地址 |
| 端口 | `443` | 面板中配置的端口 |
| UUID | `<从面板复制>` | 客户端配置中的 UUID |
| Flow | `xtls-rprx-vision` | 必须选择此项 |
| 传输协议 | TCP | - |
| 安全类型 | Reality | - |
| SNI | `www.cloudflare.com` | 与面板配置一致 |
| Public Key | `<从面板复制>` | Reality 公钥 |
| Short ID | `<从面板复制>` | 必须匹配服务端允许的值，服务端不允许空值时不能留空 |
| uTLS Fingerprint | Chrome | 推荐 |

---

## 📖 Hiddify 客户端配置（推荐）

### Windows/macOS/Linux

#### Step 1: 下载安装

访问 [Hiddify 官网](https://hiddify.com/) 下载对应平台的安装包。

#### Step 2: 添加节点

**方法 A：扫码/粘贴链接**
1. 打开 Hiddify
2. 点击 **+** 按钮
3. 选择 **扫描二维码** 或 **从剪贴板导入**
4. 确认节点信息后保存

**方法 B：手动添加**
1. 点击 **+** → **手动添加**
2. 选择协议：**VLESS**
3. 依次填入上述参数
4. 点击 **保存**

#### Step 3: 连接测试

1. 在节点列表中选中刚添加的节点
2. 点击 **连接** 按钮
3. 等待连接成功提示
4. 打开浏览器访问 [ipinfo.io](https://ipinfo.io/) 验证 IP 是否切换

### Android/iOS

操作流程与桌面版类似：
1. 安装 Hiddify App
2. 扫码或粘贴分享链接
3. 点击连接并测试

---

## ⚙️ Clash 客户端配置

### 生成 Clash 配置

X-UI 目前不直接导出 Clash 格式，需手动转换或使用第三方工具。

### 示例配置（clash-config.yaml）

```yaml
proxies:
  - name: "self-hosted-vless"
    type: vless
    server: <服务器IP>
    port: 443
    uuid: <UUID>
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: www.cloudflare.com
    reality-opts:
      public-key: <Public Key>
      short-id: "<Short ID>"
    client-fingerprint: chrome

proxy-groups:
  - name: "代理"
    type: select
    proxies:
      - "self-hosted-vless"

rules:
  - DOMAIN-SUFFIX,amazon.com,代理
  - DOMAIN-SUFFIX,shopify.com,代理
  - GEOIP,CN,DIRECT
  - MATCH,代理
```

### 使用方法

1. 将上述配置保存为 `config.yaml`
2. 替换 `<服务器IP>`、`<UUID>`、`<Public Key>`、`<Short ID>` 为实际值
3. 在 Clash 客户端中导入配置文件
4. 选择 **代理** 组并启用

---

## 🧪 连接测试

### Windows v2rayN

1. 导入后确认地址是服务器公网地址、公钥非空且格式有效、Flow 为 `xtls-rprx-vision`。
2. 重启服务，检查日志中的核心启动结果，再运行真连接延迟测试。`PublicKey 属性无效` 表示本地参数不完整，需要先修复；端口可达不能替代协议握手验证。
3. 通过本地代理显式测试成功后，如需浏览器使用该节点，在底部 **系统代理** 中选择 **自动配置系统代理**。同一时间只让一个客户端管理系统代理，避免和其他代理客户端互相覆盖。
4. 仅使用系统代理不需要开启 TUN；系统代理不会覆盖所有应用和所有网络流量。

### 基础测试

```powershell
# 第一层：检查 TCP 端口可达性
Test-NetConnection <服务器公网IP> -Port 443

# 第二层：核心启动后经客户端代理测试实际 HTTPS 握手
# 把 10808 替换为客户端实际的 SOCKS 监听端口
curl.exe --proxy socks5h://127.0.0.1:10808 --connect-timeout 10 --max-time 20 https://www.cloudflare.com/cdn-cgi/trace
```

请求成功后检查响应中的 `ip=` 是否为服务器实际出口 IP。客户端分流规则可能把测试请求设为直连；必要时临时选择全局代理路由后重试。仅返回 HTTP 200 不能单独证明流量经过该节点。

直接向 Reality 服务器 IP 发 HTTPS 请求通常只会触发目标站点转发或证书不匹配，不能证明客户端认证成功，也不应通过 `-k` 忽略证书校验来判定可用。

### 客户端内测试

大多数客户端提供内置测试功能：
- **延迟测试**：检查节点响应时间
- **速度测试**：测试下载/上传速度
- **IP 泄露检测**：验证 DNS 和 WebRTC 是否泄露

### 业务场景测试

针对你的授权业务范围，建议测试：

1. **Amazon Seller Central**：登录卖家后台
2. **Shopify Admin**：访问店铺管理页面
3. **PayPal Business**：处理跨境支付
4. **Google Analytics**：查看海外站点数据

确保这些关键业务网站访问流畅且无异常中断。

---

## 🔧 常见问题

### 问题 1：连接后立即断开

**可能原因**：
- Flow 未设置为 `xtls-rprx-vision`
- Reality 配置错误（SNI、Public Key 不匹配）

**解决方法**：
1. 检查客户端 Flow 设置
2. 重新从面板复制完整的分享链接
3. 确认 Public Key 与面板显示一致

### 问题 2：部分网站无法访问

**可能原因**：
- DNS 污染
- 路由规则未正确配置

**解决方法**：
1. 在客户端中启用 **绕过局域网和中国大陆 IP**
2. 使用自定义 DNS（如 `8.8.8.8` 或 `1.1.1.1`）
3. 检查 Clash 规则是否包含目标域名

### 问题 3：速度慢或不稳定

**可能原因**：
- VPS 带宽不足
- 地理位置过远
- 同时在线设备过多

**解决方法**：
1. 升级 VPS 套餐（建议 5Mbps+ 带宽）
2. 选择离目标市场更近的节点（如美西、欧洲）
3. 限制单用户设备数

---

**下一步**：[安全加固建议 →](./05-security-hardening.md)

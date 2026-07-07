# VLESS Reality IPv6 自动部署脚本

## 📖 项目简介

这是一个专为 **IPv6-only** 服务器设计的 VLESS Reality 自动部署脚本。支持 Ubuntu/Debian 系统,可一键完成所有配置并生成连接链接。

## ⚡ 快速开始

### 方法一: 直接从 GitHub 下载执行 (推荐)

```bash
# 下载并执行脚本
curl -fsSL https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh | sudo bash
```

或使用 wget:

```bash
wget -qO- https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh | sudo bash
```

### 方法二: 先下载后执行

```bash
# 1. 下载脚本
curl -fsSL https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh -o deploy-vless-reality.sh

# 2. 赋予执行权限
chmod +x deploy-vless-reality.sh

# 3. 运行脚本
sudo bash deploy-vless-reality.sh
```

### 方法三: 克隆仓库后执行

```bash
# 1. 克隆仓库
git clone https://github.com/[你的用户名]/[仓库名].git
cd [仓库名]

# 2. 运行脚本
sudo bash deploy-vless-reality.sh
```

## 🔧 使用前准备

### 1. 上传到 GitHub

#### 步骤 1: 创建 GitHub 仓库
1. 访问 [GitHub](https://github.com)
2. 点击 "New repository"
3. 填写仓库名称 (如 `vless-reality-deploy`)
4. 选择 Public (公开) 或 Private (私有)
5. 点击 "Create repository"

#### 步骤 2: 上传文件
**方式 A: 通过网页上传**
1. 进入新建的仓库
2. 点击 "Add file" → "Upload files"
3. 拖拽或选择 `deploy-vless-reality.sh` 文件
4. 点击 "Commit changes"

**方式 B: 通过 Git 命令行**
```bash
# 初始化 git
git init
git add deploy-vless-reality.sh
git commit -m "Initial commit: VLESS Reality deploy script"

# 关联远程仓库
git remote add origin https://github.com/[你的用户名]/[仓库名].git
git branch -M main
git push -u origin main
```

### 2. 获取 Raw 文件链接

上传完成后,获取文件的 raw 链接:
```
https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh
```

将此链接替换到上面的快速开始命令中即可。

## 🎯 功能特性

- ✅ **IPv6 Only 支持**: 专为纯 IPv6 服务器优化
- ✅ **自动获取 IPv6**: 从多个源自动检测公网 IPv6 地址
- ✅ **自动生成密钥**: UUID、X25519 密钥对、ShortID
- ✅ **自动安装 Xray**: 下载并安装最新版本
- ✅ **Reality 协议**: 完美伪装成 www.microsoft.com HTTPS 流量
- ✅ **systemd 管理**: 开机自启、自动重启
- ✅ **完整日志**: 输出详细部署信息和连接链接

## 📋 系统要求

- **操作系统**: Ubuntu 18.04+ 或 Debian 9+
- **网络**: 必须支持 IPv6 (纯 IPv6 或双栈)
- **权限**: root 或 sudo 权限
- **端口**: 443 端口未被占用

## 🚀 部署流程

脚本会自动执行以下步骤:

1. **检测系统**: 确认 Ubuntu/Debian 版本
2. **安装依赖**: openssl, curl, wget, jq, unzip
3. **获取 IPv6**: 从 ifconfig.365919.xyz 或其他源获取公网 IPv6
4. **生成密钥**: 
   - UUID (客户端标识)
   - X25519 密钥对 (Reality 协议必需)
   - ShortID (短标识符)
5. **安装 Xray**: 下载最新版本的 Xray-core
6. **创建配置**: 生成 Reality 协议配置文件
7. **启动服务**: 配置 systemd 并启动 Xray
8. **输出链接**: 生成 vless:// 格式的连接链接

## 📱 客户端配置

### 支持的客户端

| 平台 | 推荐客户端 |
|------|-----------|
| Windows | V2rayN, Clash Verge, NekoBox |
| macOS | ClashX, V2rayU, ShadowsocksX-NG |
| Android | V2rayNG, Clash for Android, NekoBox |
| iOS | Shadowrocket, Quantumult X, Loon |
| Linux | Qv2ray, Clash |

### 手动配置参数

如果客户端不支持直接导入 vless:// 链接,请手动填写:

| 参数 | 值 | 说明 |
|------|-----|------|
| 协议 | VLESS | - |
| 地址 | `[IPv6地址]` | 用方括号包裹,如 `[2001:db8::1]` |
| 端口 | 443 | - |
| UUID | [从文件获取] | 自动生成的 UUID |
| 流控 | xtls-rprx-vision | 必须设置 |
| 加密 | none | 不加密 |
| 传输协议 | TCP | - |
| TLS | Reality | 安全类型 |
| SNI | www.microsoft.com | 伪装域名 |
| Fingerprint | chrome | TLS 指纹 |
| PublicKey | [从文件获取] | X25519 公钥 |
| ShortId | [从文件获取] | 短标识符 |

### 导入 vless:// 链接

大多数现代客户端支持直接导入:

1. 复制 `/root/vless-link.txt` 中的完整链接
2. 在客户端中选择 "导入订阅" 或 "添加配置"
3. 粘贴链接并保存
4. 连接到服务器

## 🔍 故障排查

### 1. 无法获取 IPv6 地址

**症状**: 脚本提示 "无法获取公网 IPv6 地址"

**解决方案**:
```bash
# 检查本地 IPv6 配置
ip -6 addr show

# 测试 IPv6 连通性
ping6 -c 4 ipv6.google.com

# 手动获取 IPv6
curl -6 https://api64.ipify.org
```

### 2. 连接失败

**可能原因**:
- 客户端网络不支持 IPv6
- 防火墙阻止 443 端口
- 服务器安全组未开放 IPv6 入站

**检查步骤**:
```bash
# 检查服务状态
systemctl status xray

# 检查端口监听
ss -tlnp | grep 443

# 查看日志
journalctl -u xray -f

# 测试 IPv6 连通性
curl -6 https://www.microsoft.com
```

### 3. 防火墙配置

**UFW (Ubuntu)**:
```bash
ufw allow 443/tcp
ufw reload
```

**iptables**:
```bash
ip6tables -I INPUT -p tcp --dport 443 -j ACCEPT
```

### 4. 客户端显示 "连接超时"

**原因**: 客户端所在网络无 IPv6 连接

**解决**:
- 确认客户端网络支持 IPv6
- 使用 IPv6 测试网站验证: https://test-ipv6.com
- 联系网络管理员开启 IPv6

## 📊 管理命令

```bash
# 查看服务状态
systemctl status xray

# 查看实时日志
journalctl -u xray -f

# 重启服务
systemctl restart xray

# 停止服务
systemctl stop xray

# 启动服务
systemctl start xray

# 查看开机自启状态
systemctl is-enabled xray

# 禁用开机自启
systemctl disable xray

# 启用开机自启
systemctl enable xray
```

## 📁 文件说明

| 文件路径 | 说明 |
|---------|------|
| `/usr/local/etc/xray/config.json` | Xray 主配置文件 |
| `/etc/systemd/system/xray.service` | systemd 服务定义 |
| `/var/log/xray/access.log` | 访问日志 |
| `/var/log/xray/error.log` | 错误日志 |
| `/root/vless-link.txt` | 连接信息文件 |

## 🔒 安全建议

1. **定期更新**: 重新运行脚本可更新到最新 Xray 版本
2. **监控日志**: 定期检查 `/var/log/xray/access.log`
3. **备份配置**: 妥善保存 `/root/vless-link.txt`
4. **限制访问**: 必要时配置防火墙仅允许特定 IPv6 前缀
5. **修改参数**: 生产环境建议自定义 ShortID

## ⚠️ 注意事项

- 本脚本仅供学习和研究使用
- 请遵守当地法律法规
- 不要用于非法用途
- 确保您有权在目标服务器上部署此服务
- IPv6-only 服务器需要客户端也支持 IPv6

## 📝 更新日志

### v1.0.0
- ✨ 初始版本发布
- ✨ 支持 IPv6-only 系统
- ✨ 自动获取公网 IPv6 地址
- ✨ 生成完整的 vless:// 链接
- ✨ systemd 服务管理

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

## 📄 许可证

MIT License

---

**免责声明**: 本项目仅用于技术学习和研究,使用者需自行承担使用风险并遵守相关法律法规。

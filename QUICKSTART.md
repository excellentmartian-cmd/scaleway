# 快速部署指南

## 🚀 一键部署 (从 GitHub)

### 前提条件
- Ubuntu/Debian 服务器
- root 或 sudo 权限
- IPv6 网络连接

### 执行命令

将 `[你的用户名]` 和 `[仓库名]` 替换为你的实际信息:

```bash
curl -fsSL https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh | sudo bash
```

或使用 wget:

```bash
wget -qO- https://raw.githubusercontent.com/[你的用户名]/[仓库名]/main/deploy-vless-reality.sh | sudo bash
```

## 📦 上传到 GitHub

### 步骤 1: 创建仓库
1. 访问 https://github.com/new
2. 填写仓库名称 (如 `vless-deploy`)
3. 选择 Public
4. 点击 "Create repository"

### 步骤 2: 上传脚本
**方法 A: 网页上传**
1. 进入仓库页面
2. 点击 "Add file" → "Upload files"
3. 上传 `deploy-vless-reality.sh`
4. 点击 "Commit changes"

**方法 B: Git 命令行**
```bash
git init
git add deploy-vless-reality.sh
git commit -m "Add deploy script"
git remote add origin https://github.com/[用户名]/[仓库名].git
git branch -M main
git push -u origin main
```

### 步骤 3: 获取 Raw 链接
```
https://raw.githubusercontent.com/[用户名]/[仓库名]/main/deploy-vless-reality.sh
```

## ✅ 验证部署

部署完成后,检查以下内容:

```bash
# 1. 查看服务状态
systemctl status xray

# 2. 查看连接信息
cat /root/vless-link.txt

# 3. 测试端口监听
ss -tlnp | grep 443
```

## 📱 客户端配置

1. 复制 `/root/vless-link.txt` 中的 vless:// 链接
2. 在客户端中导入该链接
3. 连接到服务器

**注意**: 客户端必须支持 IPv6!

## 🔧 常见问题

### Q: 提示无法获取 IPv6 地址?
A: 确认服务器已配置 IPv6 并可访问外部网络:
```bash
ip -6 addr show
ping6 -c 4 ipv6.google.com
```

### Q: 连接超时?
A: 检查防火墙和安全组是否开放 443 端口:
```bash
ufw allow 443/tcp
```

### Q: 如何更新?
A: 重新运行脚本即可 (会生成新的密钥):
```bash
curl -fsSL [raw链接] | sudo bash
```

## 📞 需要帮助?

查看详细文档: [README.md](README.md)

---

**提示**: 首次使用建议先在测试环境验证!

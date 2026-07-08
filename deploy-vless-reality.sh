#!/bin/bash

# VLESS Reality 自动部署脚本 (IPv6 Only)
# 适用于 Ubuntu/Debian 系统 (仅支持 IPv6)

set -e

echo "========================================="
echo "  VLESS Reality 自动部署脚本 (IPv6)"
echo "========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用 root 权限运行此脚本 (sudo bash $0)"
    exit 1
fi

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "错误: 无法检测操作系统类型"
    exit 1
fi

echo "检测到系统: $OS $VER"
echo ""

# 安装必要工具
echo "[1/7] 安装必要工具..."
apt-get update -y
apt-get install -y curl wget unzip openssl jq

# 获取公网 IPv6 地址
echo "[2/7] 获取公网 IPv6 地址..."

# 方法1: 从 ifconfig.365919.xyz 获取 (返回 JSON,需智能解析)
RAW_JSON=$(curl -s -6 --max-time 5 https://ifconfig.365919.xyz 2>/dev/null || echo "")
if [ -n "$RAW_JSON" ]; then
    # 尝试多种可能的字段名提取 IPv6
    # 优先级: ipv6 > ip6 > IPv6 > IP6 > addr_ipv6
    PUBLIC_IP=$(echo "$RAW_JSON" | jq -r '
        if .ipv6 and (.ipv6 | test("^[0-9a-fA-F:]+$")) then .ipv6
        elif .ip6 and (.ip6 | test("^[0-9a-fA-F:]+$")) then .ip6
        elif .IPv6 and (.IPv6 | test("^[0-9a-fA-F:]+$")) then .IPv6
        elif .IP6 and (.IP6 | test("^[0-9a-fA-F:]+$")) then .IP6
        elif .addr_ipv6 and (.addr_ipv6 | test("^[0-9a-fA-F:]+$")) then .addr_ipv6
        else empty
        end
    ' 2>/dev/null || echo "")

    # 如果还是没有,尝试从所有字符串值中找 IPv6 地址
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(echo "$RAW_JSON" | jq -r '
            [.. | strings] | map(select(test("^[0-9a-fA-F]*:[0-9a-fA-F:]*$"))) |
            map(select(length > 3)) | first // empty
        ' 2>/dev/null || echo "")
    fi
fi

# 方法2: 备用 IPv6 API (api64.ipify.org - 纯文本)
if [ -z "$PUBLIC_IP" ]; then
    echo "尝试备用 API: api64.ipify.org..."
    PUBLIC_IP=$(curl -s -6 --max-time 5 https://api64.ipify.org 2>/dev/null || echo "")
fi

# 方法3: 另一个备用 API (ident.me - 纯文本)
if [ -z "$PUBLIC_IP" ]; then
    echo "尝试备用 API: ident.me..."
    PUBLIC_IP=$(curl -s -6 --max-time 5 https://v6.ident.me 2>/dev/null || echo "")
fi

# 方法4: 再一个备用 API (icanhazip - 纯文本)
if [ -z "$PUBLIC_IP" ]; then
    echo "尝试备用 API: icanhazip..."
    PUBLIC_IP=$(curl -s -6 --max-time 5 https://ipv6.icanhazip.com 2>/dev/null || echo "")
fi

# 方法5: 从本地网络接口获取全局 IPv6 地址
if [ -z "$PUBLIC_IP" ]; then
    echo "尝试从本地网络接口获取..."
    # 获取第一个全局单播 IPv6 地址 (排除临时地址和链路本地地址)
    PUBLIC_IP=$(ip -6 addr show scope global | grep -v "temporary" | grep "inet6" | awk '{print $2}' | cut -d'/' -f1 | head -n1)
fi

if [ -z "$PUBLIC_IP" ]; then
    echo "错误: 无法获取公网 IPv6 地址"
    echo "请确认:"
    echo "  1. 服务器已配置 IPv6 地址"
    echo "  2. 可以访问外部 IPv6 网络"
    echo "  3. 防火墙允许 IPv6 出站连接"
    exit 1
fi

# 清理 IPv6 地址 (去除可能的空格和换行)
PUBLIC_IP=$(echo "$PUBLIC_IP" | tr -d '[:space:]')

# 验证是否为有效的 IPv6 地址 (简化验证,允许压缩格式)
if [[ ! "$PUBLIC_IP" =~ ^[0-9a-fA-F:]+$ ]] || [[ ${#PUBLIC_IP} -lt 3 ]]; then
    echo "错误: 获取的 IP 格式无效: $PUBLIC_IP"
    echo "请手动指定 IPv6 地址或检查网络配置"
    exit 1
fi

echo "公网 IPv6 地址: $PUBLIC_IP"
echo ""

# 生成 UUID
echo "[3/7] 生成 UUID..."
UUID=$(cat /proc/sys/kernel/random/uuid)
echo "UUID: $UUID"
echo ""

# 生成 X25519 密钥对
echo "[4/7] 生成 X25519 密钥对..."
KEY_PAIR=$(openssl rand -hex 32)
PRIVATE_KEY=$KEY_PAIR

# 使用 xray 生成公钥（如果已安装）或手动计算
if command -v xray &> /dev/null; then
    PUBLIC_KEY=$(xray x25519 -i "$PRIVATE_KEY" | grep "Public key:" | awk '{print $3}')
else
    # 如果没有 xray，使用预生成的方式
    echo "注意: 未检测到 xray，将使用备用方法生成公钥"
    PUBLIC_KEY=""
fi

echo "私钥: $PRIVATE_KEY"
echo "公钥: ${PUBLIC_KEY:-待生成}"
echo ""

# 生成 ShortID
echo "[5/7] 生成 ShortID..."
SHORTID=$(openssl rand -hex 8)
echo "ShortID: $SHORTID"
echo ""

# 下载并安装 Xray
echo "[6/7] 下载并安装 Xray..."

# 获取最新版本 (带错误处理)
XRAY_VERSION=$(curl -s --max-time 10 https://api.github.com/repos/XTLS/Xray-core/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 || echo "")

if [ -z "$XRAY_VERSION" ]; then
    echo "警告: 无法从 GitHub API 获取最新版本,使用备用版本 v1.8.24"
    XRAY_VERSION="v1.8.24"
fi

ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH_NAME="linux-64" ;;
    aarch64) ARCH_NAME="linux-arm64-v8a" ;;
    armv7l) ARCH_NAME="linux-arm32-v7a" ;;
    *) echo "错误: 不支持的架构 $ARCH"; exit 1 ;;
esac

DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-${ARCH_NAME}.zip"
echo "下载 Xray ${XRAY_VERSION} (${ARCH_NAME})..."

# 下载文件 (带错误检查)
if ! wget -q --timeout=30 -O /tmp/xray.zip "$DOWNLOAD_URL"; then
    echo "错误: 下载 Xray 失败,请检查网络连接"
    echo "下载地址: $DOWNLOAD_URL"
    exit 1
fi

# 验证下载的文件
if [ ! -f /tmp/xray.zip ] || [ ! -s /tmp/xray.zip ]; then
    echo "错误: 下载的文件为空或不存在"
    exit 1
fi

# 解压并安装
if ! unzip -o /tmp/xray.zip -d /tmp/xray-temp; then
    echo "错误: 解压 Xray 失败"
    exit 1
fi

cp /tmp/xray-temp/xray /usr/local/bin/xray
chmod +x /usr/local/bin/xray
rm -rf /tmp/xray-temp /tmp/xray.zip

echo "Xray 安装成功"

# 重新生成公钥
if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(xray x25519 -i "$PRIVATE_KEY" | grep "Public key:" | awk '{print $3}')
    echo "公钥已生成: $PUBLIC_KEY"
fi

echo ""
echo "========================================="
echo "  创建配置文件"
echo "========================================="

# 创建配置和日志目录
mkdir -p /usr/local/etc/xray
mkdir -p /var/log/xray
chmod 755 /var/log/xray

# 创建 Xray 配置文件 (IPv6 支持)
cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "::",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": [
            "www.microsoft.com"
          ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [
            "${SHORTID}"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

echo "配置文件已创建: /usr/local/etc/xray/config.json"
echo ""

# 创建 systemd 服务文件
cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd 服务文件已创建"
echo ""

# 重载 systemd 并启动服务
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# 等待服务启动
sleep 2

# 检查服务状态
if systemctl is-active --quiet xray; then
    echo "✓ Xray 服务已成功启动"
else
    echo "✗ Xray 服务启动失败，请检查日志: journalctl -u xray -f"
fi

echo ""
echo "========================================="
echo "  生成 VLESS 连接链接"
echo "========================================="

# 生成 vless:// 链接 (IPv6 地址需要用方括号包裹)
VLESS_LINK="vless://${UUID}@[${PUBLIC_IP}]:443?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORTID}&type=tcp&flow=xtls-rprx-vision#VLESS-Reality-IPv6"

echo ""
echo "VLESS 连接链接:"
echo "$VLESS_LINK"
echo ""

# 保存链接到文件
LINK_FILE="/root/vless-link.txt"
cat > "$LINK_FILE" << EOF
=====================================
VLESS Reality 连接信息 (IPv6 Only)
=====================================

服务器地址: ${PUBLIC_IP}
端口: 443
UUID: ${UUID}
公钥 (PublicKey): ${PUBLIC_KEY}
ShortID: ${SHORTID}
流控: xtls-rprx-vision
传输协议: TCP
安全: Reality
伪装域名: www.microsoft.com
IP 版本: IPv6 Only

完整连接链接:
${VLESS_LINK}

=====================================
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
=====================================

注意事项:
1. 客户端必须支持 IPv6
2. 客户端所在网络必须有 IPv6 连接
3. IPv6 地址在链接中已用方括号 [] 包裹
4. 如连接失败，请检查客户端网络的 IPv6 连通性
EOF

echo "连接信息已保存到: $LINK_FILE"
echo ""

echo "========================================="
echo "  部署完成!"
echo "========================================="
echo ""
echo "常用命令:"
echo "  查看状态: systemctl status xray"
echo "  查看日志: journalctl -u xray -f"
echo "  重启服务: systemctl restart xray"
echo "  停止服务: systemctl stop xray"
echo ""
echo "配置文件位置: /usr/local/etc/xray/config.json"
echo "连接信息文件: $LINK_FILE"
echo ""
echo "⚠️  重要提示:"
echo "  - 本服务器仅支持 IPv6 连接"
echo "  - 确保客户端网络支持 IPv6"
echo "  - IPv6 地址已在链接中正确格式化"
echo ""

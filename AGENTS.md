# VLESS Reality IPv6 自动部署

## Dependencies
- openssl - 生成密钥和随机数
- curl/wget - 下载 Xray 和获取公网 IP
- jq - JSON 处理
- unzip - 解压 Xray 压缩包

## Architecture
- **deploy-vless-reality.sh**: IPv6-only VLESS Reality 部署脚本
  - 多源获取 IPv6: ifconfig.365919.xyz → api64.ipify.org → 本地接口
  - 生成 UUID、X25519 密钥对、ShortID
  - 监听 `::` (所有 IPv6),端口 443
  - Reality 伪装 www.microsoft.com:443
  - systemd 服务注册,开机自启,崩溃自动重启
  - 输出 vless:// 链接(IPv6 用 [] 包裹)到 /root/vless-link.txt
  - GitHub API 限流时 fallback 到 v1.8.24

## Patterns / Constraints
- 需 root 权限,仅支持 Ubuntu/Debian
- 客户端必须支持 IPv6 网络
- 日志目录 `/var/log/xray/` 由脚本自动创建
- 配置验证: `/usr/local/bin/xray test -config /usr/local/etc/xray/config.json`

## Lessons
- IPv6 地址验证需宽松正则,允许压缩格式(::)
- wget 下载需加 timeout 和文件存在性检查
- systemd restart 前无需 stop,systemd 会自动处理

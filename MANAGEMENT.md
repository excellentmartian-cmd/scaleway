# Xray 服务管理与调试指南

## 📋 服务注册说明

脚本已自动将 Xray 注册为 **systemd 系统服务**,具有以下特性:

- ✅ **开机自启**: 服务器重启后自动启动
- ✅ **自动重启**: 服务崩溃时自动重启
- ✅ **后台运行**: 无需手动保持终端
- ✅ **日志管理**: 集成 systemd journal 日志系统

## 🔍 查看运行状态

### 1. 基本状态检查

```bash
# 查看服务是否正在运行
systemctl status xray

# 简洁状态(仅显示 active/inactive)
systemctl is-active xray

# 查看是否开机自启
systemctl is-enabled xray
```

**输出示例:**
```
● xray.service - Xray Service
     Loaded: loaded (/etc/systemd/system/xray.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 10:30:00 UTC; 2h ago
   Main PID: 12345 (xray)
      Tasks: 8
     Memory: 15.2M
        CPU: 1.234s
     CGroup: /system.slice/xray.service
             └─12345 /usr/local/bin/xray run -config /usr/local/etc/xray/config.json
```

**状态说明:**
- `active (running)` - 正常运行
- `inactive (dead)` - 未运行
- `failed` - 启动失败
- `activating` - 正在启动

### 2. 详细进程信息

```bash
# 查看进程详情
ps aux | grep xray

# 查看监听端口
ss -tlnp | grep 443
# 或
netstat -tlnp | grep 443

# 查看 IPv6 监听
ss -6 -tlnp | grep 443
```

## 📝 查看日志

### 1. 实时日志 (最常用)

```bash
# 实时跟踪日志输出
journalctl -u xray -f

# 按 Ctrl+C 退出
```

**用途:** 
- 调试连接问题
- 监控实时流量
- 排查启动错误

### 2. 历史日志

```bash
# 查看最近 100 行日志
journalctl -u xray -n 100

# 查看最近 50 行,不带分页
journalctl -u xray -n 50 --no-pager

# 查看今天的所有日志
journalctl -u xray --since today

# 查看指定时间范围的日志
journalctl -u xray --since "2024-01-15 10:00:00" --until "2024-01-15 12:00:00"

# 查看最近 1 小时的日志
journalctl -u xray --since "1 hour ago"
```

### 3. 过滤日志

```bash
# 只看错误日志
journalctl -u xray -p err

# 只看警告及以上级别
journalctl -u xray -p warning

# 搜索特定关键字
journalctl -u xray | grep "error"
journalctl -u xray | grep "accepted"

# 查看启动时的日志
journalctl -u xray -b
```

### 4. Xray 自带日志文件

```bash
# 访问日志 (记录所有连接)
tail -f /var/log/xray/access.log

# 错误日志 (记录错误信息)
tail -f /var/log/xray/error.log

# 查看最近 50 行
tail -n 50 /var/log/xray/access.log
tail -n 50 /var/log/xray/error.log

# 实时监控两个日志文件
tail -f /var/log/xray/access.log /var/log/xray/error.log
```

**日志格式说明:**

access.log 示例:
```
2024/01/15 10:30:45 [Info] [1234567890] vless inbound received connection from [2001:db8::1]:54321 accepted tcp:www.google.com:443
```

error.log 示例:
```
2024/01/15 10:30:45 [Warning] failed to handler mux client connection > io: read/write on closed pipe
```

## 🎛️ 服务控制命令

### 启动/停止/重启

```bash
# 启动服务
sudo systemctl start xray

# 停止服务
sudo systemctl stop xray

# 重启服务 (修改配置后使用)
sudo systemctl restart xray

# 重新加载配置 (不中断连接)
sudo systemctl reload xray
```

### 开机自启管理

```bash
# 启用开机自启
sudo systemctl enable xray

# 禁用开机自启
sudo systemctl disable xray

# 查看自启状态
systemctl is-enabled xray
# 输出: enabled 或 disabled
```

### 其他操作

```bash
# 查看服务依赖
systemctl list-dependencies xray

# 查看服务资源使用
systemctl show xray -p MemoryCurrent,CPUUsageUSec

# 强制停止并重置
sudo systemctl reset-failed xray
```

## 🐛 调试技巧

### 1. 服务启动失败排查

```bash
# 步骤 1: 查看详细错误
journalctl -u xray -n 50 --no-pager

# 步骤 2: 检查配置文件语法
/usr/local/bin/xray test -config /usr/local/etc/xray/config.json

# 步骤 3: 检查端口占用
ss -tlnp | grep 443

# 步骤 4: 检查文件权限
ls -la /usr/local/etc/xray/config.json
ls -la /usr/local/bin/xray

# 步骤 5: 手动运行测试
sudo /usr/local/bin/xray run -config /usr/local/etc/xray/config.json
```

### 2. 常见错误及解决

#### 错误: "address already in use"
```bash
# 查找占用 443 端口的进程
sudo lsof -i :443
sudo ss -tlnp | grep 443

# 停止冲突的服务
sudo systemctl stop nginx    # 如果 nginx 占用了 443
sudo systemctl stop apache2

# 或者修改 Xray 配置使用其他端口
```

#### 错误: "permission denied"
```bash
# 检查文件权限
sudo chmod 644 /usr/local/etc/xray/config.json
sudo chmod 755 /usr/local/bin/xray

# 检查目录权限
sudo chown -R root:root /usr/local/etc/xray
```

#### 错误: "invalid config"
```bash
# 验证配置文件
/usr/local/bin/xray test -config /usr/local/etc/xray/config.json

# 查看具体错误位置
cat /usr/local/etc/xray/config.json | jq .
```

#### 错误: "failed to bind to port"
```bash
# 检查是否有其他服务占用
sudo netstat -tlnp | grep 443

# 检查防火墙规则
sudo iptables -L -n | grep 443
sudo ip6tables -L -n | grep 443
```

### 3. 网络连接调试

```bash
# 从服务器测试出站连接
curl -6 https://www.microsoft.com

# 测试 DNS 解析
nslookup www.microsoft.com

# 检查 IPv6 路由
ip -6 route show

# 测试本地端口监听
curl -6 http://[::1]:443
```

### 4. 客户端连接调试

在客户端尝试连接时,服务器端实时查看日志:

```bash
# 终端 1: 实时监控日志
journalctl -u xray -f

# 终端 2: 同时监控 access.log
tail -f /var/log/xray/access.log
```

**正常连接的日志特征:**
```
[Info] vless inbound received connection from [客户端IPv6]:端口 accepted tcp:目标网站:443
```

**连接失败的日志特征:**
```
[Warning] failed to process connection > tls: first record does not look like a TLS handshake
[Error] rejected connection > access denied
```

## 🔧 配置修改流程

### 修改配置的正确步骤

```bash
# 1. 备份当前配置
sudo cp /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.bak

# 2. 编辑配置文件
sudo nano /usr/local/etc/xray/config.json

# 3. 验证配置语法
sudo /usr/local/bin/xray test -config /usr/local/etc/xray/config.json

# 4. 如果验证通过,重启服务
sudo systemctl restart xray

# 5. 检查服务状态
systemctl status xray

# 6. 查看日志确认无错误
journalctl -u xray -n 20
```

### 快速重载配置 (推荐)

如果只是修改了 UUID 等不影响监听的参数:

```bash
# 使用 reload 而非 restart,不会中断现有连接
sudo systemctl reload xray
```

## 📊 性能监控

### 1. 资源使用监控

```bash
# 查看内存和 CPU 使用
systemctl show xray -p MemoryCurrent,CPUUsageUSec

# 使用 top 查看
top -p $(pgrep xray)

# 使用 htop (如果已安装)
htop -p $(pgrep xray)
```

### 2. 连接数统计

```bash
# 统计当前活跃连接数
ss -tn | grep 443 | wc -l

# 查看详细的连接列表
ss -tn | grep 443

# 统计 access.log 中的连接数
grep "accepted" /var/log/xray/access.log | wc -l
```

### 3. 流量统计

```bash
# 查看网络接口流量
iftop   # 需要安装 iftop

# 或使用 nethogs
nethogs eth0   # 需要安装 nethogs

# 查看系统网络统计
cat /proc/net/dev
```

## 🚨 紧急情况处理

### 服务完全无响应

```bash
# 1. 强制停止
sudo systemctl kill xray

# 2. 清理残留进程
sudo pkill -9 xray

# 3. 重置服务状态
sudo systemctl reset-failed xray

# 4. 重新启动
sudo systemctl start xray

# 5. 验证
systemctl status xray
```

### 配置文件损坏

```bash
# 恢复备份
sudo cp /usr/local/etc/xray/config.json.bak /usr/local/etc/xray/config.json

# 重新生成配置 (会生成新的密钥)
sudo bash deploy-vless-reality.sh
```

### 日志文件过大

```bash
# 清理 journal 日志 (保留最近 100M)
sudo journalctl --vacuum-size=100M

# 或保留最近 7 天
sudo journalctl --vacuum-time=7d

# 清理 Xray 日志
sudo truncate -s 0 /var/log/xray/access.log
sudo truncate -s 0 /var/log/xray/error.log
```

## 📱 实用脚本

### 创建快捷查看脚本

```bash
# 创建 ~/xray-status.sh
cat > ~/xray-status.sh << 'EOF'
#!/bin/bash
echo "=== Xray 服务状态 ==="
systemctl is-active xray
echo ""
echo "=== 最近日志 ==="
journalctl -u xray -n 10 --no-pager
echo ""
echo "=== 端口监听 ==="
ss -6 -tlnp | grep 443
echo ""
echo "=== 进程信息 ==="
ps aux | grep "[x]ray"
EOF

chmod +x ~/xray-status.sh

# 使用时直接运行
~/xray-status.sh
```

### 创建日志监控别名

在 `~/.bashrc` 中添加:

```bash
alias xray-log='journalctl -u xray -f'
alias xray-status='systemctl status xray'
alias xray-restart='sudo systemctl restart xray'
alias xray-error='journalctl -u xray -p err -n 50'
```

然后执行 `source ~/.bashrc` 生效。

## 💡 最佳实践

1. **定期检查日志**: 每天查看一次错误日志
2. **备份配置**: 每次修改前先备份
3. **监控资源**: 关注内存和 CPU 使用
4. **及时更新**: 定期重新运行脚本更新 Xray
5. **测试配置**: 修改后务必用 `xray test` 验证
6. **保留备份**: 至少保留一份已知良好的配置备份

---

**提示**: 大多数问题都可以通过查看日志解决,养成先看日志的习惯!

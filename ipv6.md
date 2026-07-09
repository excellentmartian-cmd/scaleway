# 备份原 resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.bak

# 临时改用 nat64.net 的 DNS64(选个离 VPS 近的节点,不确定就用 Helsinki 或 Ashburn)
cat > /etc/resolv.conf << 'EOF'
nameserver 2a01:4ff:f0:9876::1
nameserver 2a01:4f9:c010:3f02::1
EOF

wget https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-64.zip

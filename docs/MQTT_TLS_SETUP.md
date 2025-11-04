# Mosquitto TLS配置指南（系统服务）

## 问题诊断

从设备日志看，MQTT连接失败（`rc=-2`），可能原因：
1. **Mosquitto未配置TLS监听**：8883端口未监听
2. **CA证书不匹配**：设备中的CA证书与服务器证书的CA不匹配
3. **证书路径错误**：Mosquitto找不到证书文件

## 解决方案

### 1. 检查证书文件

确保证书文件存在且路径正确：

```bash
# 检查证书目录
ls -la backend/data/certs/

# 应该看到：
# - ca.crt (CA证书)
# - server.crt (服务器证书)
# - server.key (服务器私钥)
```

### 2. 配置Mosquitto TLS

创建Mosquitto TLS配置文件：

```bash
sudo nano /etc/mosquitto/conf.d/tls.conf
```

添加以下内容：

```conf
# TLS监听端口
listener 8883 0.0.0.0
protocol mqtt

# 证书文件路径（根据实际路径修改）
cafile /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/ca.crt
certfile /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/server.crt
keyfile /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/server.key

# 不需要客户端证书（单向认证）
require_certificate false

# 允许匿名连接（开发环境）
allow_anonymous true

# TLS版本
tls_version tlsv1.2
```

### 3. 设置证书文件权限

```bash
sudo chown mosquitto:mosquitto /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/*
sudo chmod 644 /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/*.crt
sudo chmod 600 /home/shigure/mqtt-tls-iot-guardian/backend/data/certs/*.key
```

### 4. 验证配置

```bash
# 检查配置语法
sudo mosquitto -c /etc/mosquitto/mosquitto.conf -t

# 重启Mosquitto服务
sudo systemctl restart mosquitto

# 检查服务状态
sudo systemctl status mosquitto

# 检查端口监听
sudo lsof -i :8883
# 或
ss -tlnp | grep 8883
```

### 5. 验证证书匹配

确保设备中的CA证书与服务器证书的CA匹配：

```bash
# 查看服务器证书的CA
openssl x509 -in backend/data/certs/server.crt -text -noout | grep -A 5 "Issuer"

# 查看设备中的CA证书（从设备代码中提取）
# 应该与服务器证书的Issuer匹配
```

### 6. 测试TLS连接

```bash
# 使用mosquitto_pub测试（需要安装mosquitto-clients）
mosquitto_pub \
  -h localhost \
  -p 8883 \
  --cafile backend/data/certs/ca.crt \
  -t test/topic \
  -m "Test TLS connection"
```

## 常见问题

### 问题1：8883端口未监听

**原因**：Mosquitto配置中缺少TLS监听配置或证书文件路径错误

**解决**：
1. 检查 `/etc/mosquitto/conf.d/tls.conf` 是否存在
2. 检查证书文件路径是否正确
3. 检查证书文件权限
4. 查看Mosquitto日志：`sudo journalctl -u mosquitto -f`

### 问题2：CA证书不匹配

**原因**：设备中的CA证书与服务器证书的CA不匹配

**解决**：
1. 获取正确的CA证书（从后端系统获取）
2. 更新设备固件中的CA证书
3. 确保设备使用的CA证书与服务器证书的Issuer匹配

### 问题3：证书路径问题

**原因**：Mosquitto无法访问证书文件

**解决**：
1. 确保证书文件路径使用绝对路径
2. 检查文件权限（mosquitto用户需要读取权限）
3. 检查SELinux/AppArmor策略（如果启用）

## 设备代码中的CA证书

设备代码中的CA证书应该与服务器证书的CA匹配。如果证书不匹配，需要：

1. **从后端获取正确的CA证书**：
   ```bash
   # 通过API获取
   curl -X GET "http://localhost:8000/api/v1/certificates/ca" \
     -H "Authorization: Bearer YOUR_TOKEN" > ca.crt
   ```

2. **更新设备固件**：
   - 将正确的CA证书复制到设备代码中
   - 重新编译和烧录固件

## 调试步骤

1. **检查Mosquitto日志**：
   ```bash
   sudo journalctl -u mosquitto -f
   ```

2. **检查端口监听**：
   ```bash
   sudo lsof -i :8883
   ```

3. **测试TLS连接**：
   ```bash
   openssl s_client -connect localhost:8883 -CAfile backend/data/certs/ca.crt
   ```

4. **查看设备串口日志**：
   - 检查设备日志中的错误信息
   - 确认MQTT连接失败的具体原因

## 快速修复脚本

```bash
#!/bin/bash
# 快速配置Mosquitto TLS

CERT_DIR="/home/shigure/mqtt-tls-iot-guardian/backend/data/certs"
CONF_FILE="/etc/mosquitto/conf.d/tls.conf"

# 创建TLS配置
sudo tee "$CONF_FILE" > /dev/null <<EOF
listener 8883 0.0.0.0
protocol mqtt
cafile $CERT_DIR/ca.crt
certfile $CERT_DIR/server.crt
keyfile $CERT_DIR/server.key
require_certificate false
allow_anonymous true
tls_version tlsv1.2
EOF

# 设置权限
sudo chown mosquitto:mosquitto $CERT_DIR/*
sudo chmod 644 $CERT_DIR/*.crt
sudo chmod 600 $CERT_DIR/*.key

# 重启服务
sudo systemctl restart mosquitto

# 检查状态
sudo systemctl status mosquitto
```



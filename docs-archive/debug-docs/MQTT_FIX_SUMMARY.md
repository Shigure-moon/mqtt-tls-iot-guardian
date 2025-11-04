# MQTT连接问题修复总结

## 已完成的修复

### ✅ 1. 删除启动脚本中的MQTT容器启动部分

- **`scripts/start_backend.sh`**：已更新为只启动PostgreSQL和Redis，检查本地Mosquitto服务
- **`scripts/quick_start.sh`**：已更新为检查本地Mosquitto服务

### ✅ 2. 修复设备代码中的CA证书

**问题**：设备代码中使用了服务器证书而不是CA证书

**修复**：
- 已将 `shili_encrypted.ino` 中的CA证书替换为正确的CA证书
- 正确的CA证书：`MIIDjjCCAnagAwIBAgIUQ7JiWpxdHTbLU6gCSnC6KpY61Hgw...` (CN = IoT CA)

### ✅ 3. 配置Mosquitto TLS监听

**创建的配置文件**：`/etc/mosquitto/conf.d/tls.conf`

```conf
listener 8883 0.0.0.0
protocol mqtt
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate false
allow_anonymous true
tls_version tlsv1.2
```

**证书位置**：
- 证书已复制到 `/etc/mosquitto/certs/` 目录
- 权限已正确设置（mosquitto用户可读）

## 下一步操作

### 1. 重新编译和烧录设备固件

由于更新了CA证书，需要重新编译和烧录：

```bash
# 使用Arduino IDE或esptool重新烧录
# 使用更新后的 shili_encrypted.ino
```

### 2. 验证Mosquitto TLS配置

```bash
# 检查服务状态
sudo systemctl status mosquitto

# 检查8883端口监听
sudo lsof -i :8883
# 或
ss -tlnp | grep 8883

# 查看日志
sudo journalctl -u mosquitto -f
```

### 3. 测试MQTT TLS连接

```bash
# 使用mosquitto_pub测试
mosquitto_pub \
  -h localhost \
  -p 8883 \
  --cafile /etc/mosquitto/certs/ca.crt \
  -t test/topic \
  -m "Test TLS connection"
```

### 4. 设备重新连接

- 重新烧录固件后，设备应该能够成功连接到MQTT服务器
- 观察设备串口日志，应该看到：
  ```
  [MQTT] Connected!
  ```

## 问题排查

如果仍然连接失败，检查：

1. **Mosquitto服务状态**：
   ```bash
   sudo systemctl status mosquitto
   sudo journalctl -u mosquitto -f
   ```

2. **端口监听**：
   ```bash
   sudo lsof -i :8883
   ```

3. **证书验证**：
   ```bash
   # 验证服务器证书由CA签名
   openssl verify -CAfile /etc/mosquitto/certs/ca.crt /etc/mosquitto/certs/server.crt
   ```

4. **设备日志**：
   - 查看设备串口输出
   - 检查MQTT连接错误码

## 注意事项

1. **证书匹配**：确保设备中的CA证书与服务器证书的CA匹配
2. **网络可达**：确保设备能够访问MQTT服务器（10.42.0.1:8883）
3. **防火墙**：确保8883端口未被防火墙阻止
4. **用户名密码**：确保MQTT用户名和密码正确（admin/admin）



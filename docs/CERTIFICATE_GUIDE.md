# 证书管理使用指南

## 概述

本系统实现了完整的TLS证书管理功能，支持CA证书、服务器证书和客户端证书的自动生成和管理。

## 证书架构

```
CA证书 (ca.crt + ca.key)
├── 服务器证书 (server.crt + server.key) - 用于MQTT Broker
└── 客户端证书 (device-{device_id}.crt + device-{device_id}.key) - 用于IoT设备
```

## API端点

### 1. 生成CA证书

**管理员权限**

```bash
POST /api/v1/certificates/ca/generate

Response:
{
  "ca_key": "-----BEGIN PRIVATE KEY-----...",
  "ca_cert": "-----BEGIN CERTIFICATE-----...",
  "message": "CA证书已成功生成"
}
```

### 2. 下载CA证书

```bash
GET /api/v1/certificates/ca/download

Response:
{
  "ca_cert": "-----BEGIN CERTIFICATE-----..."
}

# 或作为文件下载
GET /api/v1/certificates/ca/download/file
```

### 3. 生成服务器证书

**管理员权限**

```bash
POST /api/v1/certificates/server/generate

Request Body:
{
  "common_name": "mosquitto-broker",
  "alt_names": ["localhost", "127.0.0.1"],
  "validity_days": 365
}

Response:
{
  "server_key": "-----BEGIN PRIVATE KEY-----...",
  "server_cert": "-----BEGIN CERTIFICATE-----...",
  "message": "服务器证书已成功生成"
}
```

### 4. 为设备生成客户端证书

```bash
POST /api/v1/certificates/client/generate/{device_id}

Request Body:
{
  "common_name": "device-001",  # 可选，默认使用 device-{device_id}
  "validity_days": 365
}

Response:
{
  "client_key": "-----BEGIN PRIVATE KEY-----...",
  "client_cert": "-----BEGIN CERTIFICATE-----...",
  "ca_cert": "-----BEGIN CERTIFICATE-----...",
  "serial_number": "...",
  "message": "客户端证书已成功生成并保存"
}
```

### 5. 验证证书

```bash
POST /api/v1/certificates/verify

Request Body:
{
  "certificate": "-----BEGIN CERTIFICATE-----..."
}

Response:
{
  "is_valid": true,
  "error_message": null
}
```

### 6. 吊销证书

**管理员权限**

```bash
POST /api/v1/certificates/revoke

Request Body:
{
  "serial_number": "...",
  "reason": "设备丢失"
}

Response:
{
  "success": true,
  "message": "证书已成功吊销"
}
```

## 使用流程

### 1. 初始化证书系统

```bash
# 1. 登录获取管理员token
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 2. 生成CA证书
curl -X POST "http://localhost:8000/api/v1/certificates/ca/generate" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  > ca_cert.json

# 3. 保存CA证书和私钥到文件
cat ca_cert.json | jq -r '.ca_cert' > data/certs/ca.crt
cat ca_cert.json | jq -r '.ca_key' > data/certs/ca.key

# 4. 生成服务器证书
curl -X POST "http://localhost:8000/api/v1/certificates/server/generate" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "common_name": "mosquitto-broker",
    "alt_names": ["localhost", "192.168.1.100"],
    "validity_days": 365
  }' > server_cert.json

# 5. 保存服务器证书和私钥
cat server_cert.json | jq -r '.server_cert' > data/certs/server.crt
cat server_cert.json | jq -r '.server_key' > data/certs/server.key
```

### 2. 配置MQTT Broker使用TLS

编辑 `backend/config/mqtt/mosquitto.conf`:

```conf
# 启用TLS监听
listener 8883 0.0.0.0
protocol mqtt
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key
require_certificate false  # 设为true启用双向认证
allow_anonymous false
```

重启MQTT Broker:

```bash
docker compose restart mosquitto
```

### 3. 为IoT设备生成证书

```bash
# 1. 创建设备
curl -X POST "http://localhost:8000/api/v1/devices" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "esp8266-001",
    "name": "ESP8266测试设备",
    "type": "ESP8266",
    "description": "MQTT测试设备"
  }'

# 2. 为设备生成证书
curl -X POST "http://localhost:8000/api/v1/certificates/client/generate/{device_uuid}" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "validity_days": 365
  }' > device_cert.json

# 3. 保存证书文件
cat device_cert.json | jq -r '.client_cert' > device-001.crt
cat device_cert.json | jq -r '.client_key' > device-001.key
cat device_cert.json | jq -r '.ca_cert' > ca.crt
```

### 4. 启用双向认证（推荐生产环境）

编辑 `mosquitto.conf`:

```conf
listener 8883 0.0.0.0
protocol mqtt
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key
require_certificate true  # 启用双向认证
allow_anonymous false
```

重启MQTT Broker后，设备必须使用有效的证书才能连接。

### 5. 测试MQTT连接

使用mosquitto_pub订阅（使用证书）:

```bash
mosquitto_pub \
  -h localhost \
  -p 8883 \
  --cafile ca.crt \
  --cert device-001.crt \
  --key device-001.key \
  -t test/topic \
  -m "Hello MQTT with TLS"
```

如果没有证书，连接将被拒绝：

```bash
mosquitto_pub -h localhost -p 8883 -t test/topic -m "test"
# 连接被拒绝
```

## 安全建议

### 生产环境配置

1. **禁用匿名连接**：
   ```conf
   allow_anonymous false
   ```

2. **启用双向认证**：
   ```conf
   require_certificate true
   ```

3. **使用强密码保护私钥**：
   - 建议使用密码保护CA私钥
   - 定期轮换证书

4. **限制证书有效期**：
   - CA证书：5-10年
   - 服务器证书：1年
   - 客户端证书：1年

5. **实现证书吊销列表(CRL)**：
   - 监控证书使用情况
   - 及时吊销可疑证书
   - 定期检查证书状态

6. **网络安全**：
   - 仅开放必要的端口（8883 for TLS）
   - 使用防火墙限制访问
   - 监控异常连接

### 开发环境

开发环境可以不使用TLS，使用1883端口：

```bash
# 不使用TLS的连接
mosquitto_pub -h localhost -p 1883 -t test/topic -m "test"
```

## 故障排查

### 1. 证书验证失败

检查证书链完整性：

```bash
openssl verify -CAfile ca.crt server.crt
openssl verify -CAfile ca.crt device-001.crt
```

### 2. 连接被拒绝

检查Mosquitto日志：

```bash
docker logs iot_mosquitto
```

常见问题：
- 证书文件路径错误
- 证书已过期
- 证书签名不匹配
- `require_certificate`配置错误

### 3. 证书过期

定期检查证书有效期：

```bash
openssl x509 -in ca.crt -noout -dates
openssl x509 -in server.crt -noout -dates
openssl x509 -in device-001.crt -noout -dates
```

提前更新即将过期的证书。

## 证书存储

证书保存在以下位置：

- **文件系统**：`data/certs/`
  - `ca.crt`, `ca.key` - CA证书
  - `server.crt`, `server.key` - 服务器证书
  - 已生成的其他证书

- **数据库**：`device_certificates`表
  - 证书内容（PEM格式）
  - 私钥（可选，加密存储）
  - 序列号、有效期等元数据

## 注意事项

1. **私钥安全**：
   - 永远不要将私钥暴露在公共代码库中
   - 使用环境变量或密钥管理系统存储
   - 定期备份CA私钥

2. **证书备份**：
   - 定期备份CA私钥
   - 备份所有已颁发的证书记录
   - 保存证书元数据（序列号、有效期等）

3. **合规性**：
   - 遵守公司安全政策
   - 遵循行业标准（如ISO 27001）
   - 记录所有证书操作

4. **监控**：
   - 监控证书使用情况
   - 定期审查证书列表
   - 及时处理安全事件

## 扩展功能

未来计划添加：

- [ ] 证书自动续期
- [ ] CRL（证书吊销列表）完整实现
- [ ] OCSP（在线证书状态协议）支持
- [ ] 国密算法（SM2/SM3/SM4）支持
- [ ] 证书模板管理
- [ ] 批量证书颁发
- [ ] 证书审计日志

## 参考资源

- [OpenSSL手册](https://www.openssl.org/docs/)
- [Mosquitto TLS配置](https://mosquitto.org/man/mosquitto-conf-5.html)
- [X.509证书标准](https://en.wikipedia.org/wiki/X.509)
- [MQTT安全最佳实践](https://mosquitto.org/man/mqtt-7.html)


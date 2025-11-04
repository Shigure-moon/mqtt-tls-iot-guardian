# EMQX MQTT 服务器配置指南

## 当前配置

根据 Docker 容器信息，EMQX 服务器配置如下：

### 端口映射
- **1883**: 标准 MQTT 端口（非 TLS）
- **18883**: TLS MQTT 端口（容器内 8883，映射到主机 18883）
- **18083**: Web 管理界面
- **8083-8084**: 其他协议端口

### 后端连接配置

后端需要连接到 EMQX 服务器，更新 `.env` 文件中的配置：

```bash
# MQTT配置 - 连接到EMQX
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883          # 非TLS端口，或使用 18883 连接TLS端口
MQTT_CLIENT_ID=backend-service
MQTT_USERNAME=admin            # EMQX默认用户名
MQTT_PASSWORD=public           # EMQX默认密码（请根据实际情况修改）
```

### EMQX 默认认证

EMQX 默认配置：
- 用户名: `admin`
- 密码: `public`

**重要**: 生产环境请修改默认密码！

### 访问 Web 管理界面

访问 `http://localhost:18083` 查看 EMQX 管理界面。

### 设备连接配置

设备端（ESP8266）需要连接到：
- **非TLS**: `mqtt_server:1883`
- **TLS**: `mqtt_server:18883`（需要CA证书）

### 验证连接

1. **检查后端连接**:
   ```bash
   # 查看后端日志
   tail -f backend/logs/*.log | grep MQTT
   ```

2. **检查EMQX状态**:
   ```bash
   # 查看EMQX日志
   docker logs emqx -f
   
   # 或访问Web界面
   # http://localhost:18083
   ```

3. **测试MQTT连接**:
   ```bash
   # 订阅所有设备消息
   mosquitto_sub -h localhost -p 1883 -u admin -P public -t "devices/+/#" -v
   
   # 发布测试消息
   mosquitto_pub -h localhost -p 1883 -u admin -P public -t "devices/test/status" -m "test message"
   ```

### 配置TLS连接（可选）

如果需要使用TLS连接，需要：

1. 配置EMQX使用TLS证书
2. 更新后端配置使用TLS端口 (18883)
3. 确保设备端也使用TLS连接

### 监控和日志

- **EMQX日志**: `docker logs emqx -f`
- **后端MQTT日志**: 查看后端日志中的 `[MQTT]` 标记
- **Web界面**: `http://localhost:18083`


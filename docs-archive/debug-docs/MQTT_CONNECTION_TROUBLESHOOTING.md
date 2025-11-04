# MQTT连接故障排查指南

## 问题：设备发送数据但数据库未更新

### 症状
- ESP8266设备成功连接到MQTT Broker（`10.42.0.1:8883`）
- 设备发送传感器数据和心跳消息
- 但后端数据库没有更新设备状态和传感器数据

### 原因分析

1. **后端MQTT配置不匹配**
   - 后端配置指向 `localhost:1883`（非TLS）
   - 设备连接到 `10.42.0.1:8883`（TLS）
   - 后端无法接收到设备发送的消息

2. **TLS配置缺失**
   - 后端MQTT客户端未配置TLS
   - 无法连接到EMQX的TLS端口（8883）

### 解决方案

#### 1. 更新后端MQTT配置

编辑 `backend/.env`：
```bash
MQTT_BROKER_HOST=10.42.0.1
MQTT_BROKER_PORT=8883
MQTT_USERNAME=admin
MQTT_PASSWORD=admin
```

#### 2. 后端已更新TLS支持

`backend/app/core/events.py` 已自动检测TLS端口（8883或18883）并配置：
- 自动加载CA证书：`data/certs/ca.crt`
- 配置TLS连接
- 禁用主机名验证（支持IP地址连接）

#### 3. 重启后端服务

由于使用了 `--reload` 模式，后端应该自动重新加载配置。如果没有看到MQTT连接日志，请：

```bash
# 查看后端日志
# 应该能看到类似以下的日志：
# [MQTT] Attempting to connect to 10.42.0.1:8883 (TLS: True)
# [MQTT] Using TLS connection with CA certificate: ...
# [MQTT] Connected to broker at 10.42.0.1:8883
# [MQTT] Subscribed to devices/+/status with QoS 0
# [MQTT] Subscribed to devices/+/sensor with QoS 0
# [MQTT] Subscribed to devices/+/heartbeat with QoS 0
```

### 验证步骤

#### 1. 检查后端MQTT连接

查看后端控制台输出，应该看到：
```
[MQTT] Attempting to connect to 10.42.0.1:8883 (TLS: True)
[MQTT] Using TLS connection with CA certificate: /path/to/data/certs/ca.crt
[MQTT] Connected to broker at 10.42.0.1:8883
[MQTT] Subscribed to devices/+/status with QoS 0, result: (0,)
[MQTT] Subscribed to devices/+/sensor with QoS 0, result: (0,)
[MQTT] Subscribed to devices/+/heartbeat with QoS 0, result: (0,)
```

#### 2. 检查消息接收

当设备发送消息时，应该看到：
```
[MQTT] Received message on topic: devices/esp8266/sensor, qos: 0, payload length: 256
[MQTT Processor] Got message from queue: devices/esp8266/sensor
[MQTT] Received message on topic: devices/esp8266/sensor, payload: {"device_id":"esp8266",...}
[MQTT] Parsed device_id: esp8266, message_type: sensor
[MQTT] Found device in database: esp8266 (id: ...)
[MQTT] Device esp8266 status updated to online
[MQTT] Saved 7 sensor metrics for device esp8266: {...}
```

#### 3. 测试MQTT连接

使用Python测试脚本：
```python
import paho.mqtt.client as mqtt_client
import ssl
import time

client = mqtt_client.Client(client_id="test", protocol=mqtt_client.MQTTv5)
client.username_pw_set("admin", "admin")

# 配置TLS
client.tls_set(ca_certs="data/certs/ca.crt", tls_version=ssl.PROTOCOL_TLSv1_2)
client.tls_insecure_set(True)

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print("✅ 连接成功！")
        client.subscribe("devices/+/#")

def on_message(client, userdata, msg):
    print(f"收到消息: {msg.topic} - {msg.payload.decode()}")

client.on_connect = on_connect
client.on_message = on_message

client.connect("10.42.0.1", 8883, 60)
client.loop_start()
time.sleep(5)
```

### 常见问题

#### Q1: 后端日志中没有MQTT连接信息

**A**: 检查：
1. 后端是否重新加载了配置（`--reload`模式）
2. 查看后端启动日志，是否有MQTT初始化错误
3. 如果仍无连接，手动重启后端服务

#### Q2: MQTT连接失败，错误码5（未授权）

**A**: 检查：
1. `MQTT_USERNAME` 和 `MQTT_PASSWORD` 是否正确
2. EMQX是否配置了正确的用户名密码

#### Q3: TLS握手失败

**A**: 检查：
1. CA证书路径是否正确：`data/certs/ca.crt`
2. CA证书文件是否存在且可读
3. 证书是否与EMQX使用的证书匹配

### 配置检查清单

- [ ] `backend/.env` 中 `MQTT_BROKER_HOST=10.42.0.1`
- [ ] `backend/.env` 中 `MQTT_BROKER_PORT=8883`
- [ ] `backend/.env` 中 `MQTT_USERNAME=admin`
- [ ] `backend/.env` 中 `MQTT_PASSWORD=admin`
- [ ] `data/certs/ca.crt` 文件存在
- [ ] 后端日志显示MQTT连接成功
- [ ] 后端日志显示订阅成功
- [ ] 设备发送消息时，后端日志显示消息接收

### 下一步

如果所有步骤都完成但仍无法接收消息，请检查：
1. EMQX的ACL规则是否允许后端订阅 `devices/+/#`
2. 设备发送的消息主题格式是否正确
3. 网络连接是否正常（防火墙、端口等）


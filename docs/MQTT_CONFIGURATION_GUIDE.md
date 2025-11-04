# MQTT配置指南 - 避免常见配置问题

## 问题总结

### 问题描述
**症状**：ESP8266设备成功连接到MQTT Broker并发送数据，但后端数据库没有更新。

**根本原因**：
1. **地址不匹配**：后端配置为 `localhost:1883`，设备连接到 `10.42.0.1:8883`
2. **协议不匹配**：后端使用非TLS连接（1883），设备使用TLS连接（8883）
3. **后端无法接收消息**：由于连接到错误的地址和端口，后端无法订阅设备主题

### 问题原因分析

```
设备端配置：
  - MQTT服务器：10.42.0.1:8883 (TLS)
  - 发送主题：devices/esp8266/sensor
  - 发送主题：devices/esp8266/heartbeat

后端配置（错误）：
  - MQTT服务器：localhost:1883 (非TLS)
  - 订阅主题：devices/+/sensor
  - 订阅主题：devices/+/heartbeat

结果：后端连接到不同的MQTT服务器，无法接收到设备消息
```

## 正确的配置流程

### 1. 确定MQTT Broker地址和端口

#### 检查MQTT Broker配置

```bash
# 检查EMQX容器端口映射
docker port emqx

# 检查监听端口
netstat -tlnp | grep -E ":(1883|8883)"
# 或
ss -tlnp | grep -E ":(1883|8883)"
```

**常见情况**：
- **非TLS端口**：`1883`（用于本地开发）
- **TLS端口**：`8883`（用于生产环境）
- **容器映射**：`18883` -> `8883`（如果通过Docker映射）

#### 确定服务器地址

```bash
# 检查本机IP地址
ip addr show | grep "inet " | grep -v "127.0.0.1"

# 常见情况：
# - 本地开发：localhost 或 127.0.0.1
# - 容器内：容器名称（如 emqx）
# - 局域网：实际IP地址（如 10.42.0.1）
# - 生产环境：域名或公网IP
```

### 2. 配置后端MQTT连接

#### 编辑 `backend/.env`

```bash
# 根据实际情况配置
MQTT_BROKER_HOST=10.42.0.1        # 与设备配置一致
MQTT_BROKER_PORT=8883              # 使用TLS端口（如果设备使用TLS）
MQTT_USERNAME=admin                 # 与设备配置一致
MQTT_PASSWORD=admin                 # 与设备配置一致
MQTT_CLIENT_ID=iot_backend          # 后端客户端ID
```

#### 重要检查点

✅ **地址必须一致**
- 设备连接：`10.42.0.1:8883`
- 后端连接：`10.42.0.1:8883`

✅ **端口类型必须一致**
- 如果设备使用TLS（8883），后端也必须使用TLS（8883）
- 如果设备使用非TLS（1883），后端也必须使用非TLS（1883）

✅ **认证信息必须一致**
- 用户名和密码必须与MQTT Broker配置一致
- 必须与设备配置一致

### 3. 配置设备固件

#### 确保设备配置与后端一致

```cpp
// 设备代码中的配置
const char* mqtt_server = "10.42.0.1";   // 与后端MQTT_BROKER_HOST一致
const int mqtt_port = 8883;              // 与后端MQTT_BROKER_PORT一致
const char* mqtt_user = "admin";         // 与后端MQTT_USERNAME一致
const char* mqtt_pass = "admin";         // 与后端MQTT_PASSWORD一致
```

### 4. 验证配置

#### 使用测试脚本验证连接

```bash
# 创建测试脚本 test_mqtt_connection.py
python3 << 'EOF'
import paho.mqtt.client as mqtt_client
import ssl
import time

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print("✅ 连接成功！")
        client.subscribe("devices/+/#")
    else:
        print(f"❌ 连接失败，错误码: {rc}")

def on_message(client, userdata, msg):
    print(f"📨 收到消息: {msg.topic} - {msg.payload.decode()[:100]}")

client = mqtt_client.Client(client_id="test_client", protocol=mqtt_client.MQTTv5)
client.username_pw_set("admin", "admin")
client.on_connect = on_connect
client.on_message = on_message

# 配置TLS（如果使用8883端口）
client.tls_set(ca_certs="data/certs/ca.crt", tls_version=ssl.PROTOCOL_TLSv1_2)
client.tls_insecure_set(True)

print("🔌 尝试连接到 10.42.0.1:8883")
client.connect("10.42.0.1", 8883, 60)
client.loop_start()
time.sleep(5)
client.loop_stop()
EOF
```

## 避免常见错误的检查清单

### ✅ 配置前检查

- [ ] **确认MQTT Broker地址和端口**
  ```bash
  docker port emqx  # 或检查其他MQTT服务器配置
  ```

- [ ] **确认使用TLS还是非TLS**
  - 生产环境：推荐使用TLS（8883）
  - 开发环境：可以使用非TLS（1883）

- [ ] **确认认证信息**
  - 检查EMQX/Mosquitto的用户名密码配置
  - 确保设备、后端、测试工具使用相同的认证信息

### ✅ 配置时检查

- [ ] **后端配置** (`backend/.env`)
  ```bash
  MQTT_BROKER_HOST=10.42.0.1      # 与设备配置一致
  MQTT_BROKER_PORT=8883            # 与设备配置一致
  MQTT_USERNAME=admin              # 与设备配置一致
  MQTT_PASSWORD=admin              # 与设备配置一致
  ```

- [ ] **设备固件配置** (`.ino`文件)
  ```cpp
  const char* mqtt_server = "10.42.0.1";  // 与后端一致
  const int mqtt_port = 8883;             // 与后端一致
  const char* mqtt_user = "admin";        // 与后端一致
  const char* mqtt_pass = "admin";        // 与后端一致
  ```

### ✅ 配置后验证

- [ ] **检查后端日志**
  ```bash
  # 应该看到：
  [MQTT] Attempting to connect to 10.42.0.1:8883 (TLS: True)
  [MQTT] Connected to broker at 10.42.0.1:8883
  [MQTT] Subscribed to devices/+/sensor with QoS 0
  ```

- [ ] **检查消息接收**
  ```bash
  # 当设备发送消息时，应该看到：
  [MQTT] Received message on topic: devices/esp8266/sensor
  [MQTT] Device esp8266 status updated to online
  ```

- [ ] **检查数据库更新**
  - 设备状态应该更新为 `online`
  - 传感器数据应该保存到 `device_metrics` 表

## 常见问题及解决方案

### Q1: 后端连接失败，错误码5（未授权）

**原因**：用户名或密码不正确

**解决**：
1. 检查 `backend/.env` 中的 `MQTT_USERNAME` 和 `MQTT_PASSWORD`
2. 检查EMQX/Mosquitto的用户配置
3. 确保设备和后端使用相同的认证信息

### Q2: TLS握手失败

**原因**：CA证书路径错误或证书不匹配

**解决**：
1. 检查 `data/certs/ca.crt` 是否存在
2. 确认CA证书与MQTT Broker使用的证书匹配
3. 检查文件权限：`chmod 644 data/certs/ca.crt`

### Q3: 后端连接成功但收不到消息

**原因**：
1. 订阅主题不匹配
2. 设备发送的主题格式不对
3. ACL规则限制

**解决**：
1. 检查后端订阅的主题：`devices/+/#`
2. 检查设备发送的主题：`devices/esp8266/sensor`
3. 检查EMQX的ACL规则，确保允许后端订阅

### Q4: 地址解析失败

**原因**：`localhost` 在不同环境下的含义不同

**解决**：
- **容器环境**：使用容器名称或服务名
- **本地开发**：使用 `127.0.0.1` 或 `localhost`
- **局域网**：使用实际IP地址（如 `10.42.0.1`）
- **生产环境**：使用域名或公网IP

## 最佳实践

### 1. 使用环境变量管理配置

不要硬编码MQTT配置，使用环境变量：

```bash
# backend/.env
MQTT_BROKER_HOST=${MQTT_BROKER_HOST:-10.42.0.1}
MQTT_BROKER_PORT=${MQTT_BROKER_PORT:-8883}
```

### 2. 创建配置验证脚本

```bash
#!/bin/bash
# scripts/verify_mqtt_config.sh

echo "检查MQTT配置一致性..."
echo ""

echo "后端配置："
grep MQTT backend/.env | grep -v "^#"

echo ""
echo "设备配置（从固件模板）："
grep -E "mqtt_server|mqtt_port|mqtt_user|mqtt_pass" backend/templates/*.ino | head -4

echo ""
echo "验证连接..."
# 运行测试脚本
```

### 3. 使用配置文档

在项目文档中记录：
- MQTT Broker地址和端口
- TLS配置
- 认证信息
- 主题命名规范

### 4. 统一配置管理

考虑使用配置管理工具：
- **开发环境**：`.env` 文件
- **测试环境**：环境变量或配置服务
- **生产环境**：密钥管理服务（如Vault）

### 5. 定期检查配置一致性

创建定期检查脚本，验证：
- 后端配置与设备配置一致
- MQTT连接正常
- 消息能够正常收发
- 数据库能够正常更新

## 配置同步策略

### 方案1：使用配置模板

```bash
# 创建配置模板
backend/config/mqtt.template.env

# 在部署时生成实际配置
envsubst < backend/config/mqtt.template.env > backend/.env
```

### 方案2：使用配置中心

```python
# 从配置中心获取MQTT配置
from app.core.config import get_mqtt_config

mqtt_config = get_mqtt_config()
# 自动同步到设备固件生成
```

### 方案3：配置验证脚本

```python
# scripts/validate_config.py
def validate_mqtt_config():
    """验证MQTT配置一致性"""
    backend_config = load_backend_config()
    device_config = load_device_template()
    
    assert backend_config['host'] == device_config['mqtt_server']
    assert backend_config['port'] == device_config['mqtt_port']
    # ...
```

## 总结

**核心原则**：
1. ✅ **地址一致**：设备和后端必须连接到同一个MQTT Broker
2. ✅ **协议一致**：都使用TLS或都使用非TLS
3. ✅ **认证一致**：使用相同的用户名和密码
4. ✅ **主题匹配**：设备发送的主题能被后端订阅到

**避免错误的方法**：
1. 📝 使用配置文档记录MQTT配置
2. ✅ 创建配置验证脚本
3. 🔍 定期检查配置一致性
4. 🧪 使用测试脚本验证连接
5. 📋 使用配置检查清单

**调试技巧**：
1. 查看后端日志，确认连接状态
2. 使用MQTT客户端工具测试连接
3. 检查数据库更新，确认消息处理
4. 使用监控工具（如EMQX Dashboard）查看连接和消息


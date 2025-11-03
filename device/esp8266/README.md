# ESP8266设备端烧录指南

## 概述

本目录包含适用于IoT安全管理系统的ESP8266设备端代码，实现设备与后端服务器的安全MQTT通信。

## 功能特性

- ✅ WiFi自动连接
- ✅ MQTT over TLS安全通信
- ✅ ILI9341 TFT屏幕显示
- ✅ 自动心跳上报
- ✅ 传感器数据上报
- ✅ 控制命令接收与执行
- ✅ 设备状态监控
- ✅ 断线自动重连

## 目录结构

```
device/esp8266/
├── README.md                                    # 本文件
├── iot_guardian_device/
│   └── iot_guardian_device.ino                 # 设备端主程序（带屏幕）
└── libs/                                        # 依赖库说明（可选）
```

## 硬件要求

- ESP8266开发板（NodeMCU / Wemos D1 Mini / ESP8266-12E等）
- 至少4MB Flash
- LED指示灯（可选，使用板载LED）
- **ILI9341 TFT显示屏**（可选，用于实时显示状态）

## 软件依赖

### Arduino IDE配置

1. 安装ESP8266开发板支持
   - 文件 → 首选项 → 附加开发板管理器网址：`http://arduino.esp8266.com/stable/package_esp8266com_index.json`
   - 工具 → 开发板 → 开发板管理器 → 搜索"ESP8266" → 安装

2. 安装依赖库
   - **PubSubClient**：工具 → 管理库 → 搜索"PubSubClient" → 安装最新版本
   - **ArduinoJson**：工具 → 管理库 → 搜索"ArduinoJson" → 安装6.x版本
   - **Adafruit GFX Library**：工具 → 管理库 → 搜索"Adafruit GFX" → 安装
   - **Adafruit ILI9341**：工具 → 管理库 → 搜索"Adafruit ILI9341" → 安装

3. 配置开发板
   - 工具 → 开发板 → 选择你的ESP8266型号
   - 工具 → Flash Size → 选择"4MB (FS:2MB OTA:~1019KB)"
   - 工具 → Upload Speed → 选择"115200"

## 配置步骤

### 1. 修改代码配置

打开 `iot_guardian_device/iot_guardian_device.ino`，修改以下配置：

```cpp
// 设备基本信息
#define DEVICE_ID "esp8266-001"              // 必须与数据库中注册的设备ID匹配

// 屏幕引脚配置（如果使用屏幕）
#define TFT_CS D2                            // TFT CS引脚
#define TFT_RST D3                           // TFT RST引脚
#define TFT_DC D4                            // TFT DC引脚

// WiFi配置
const char* ssid = "YOUR_WIFI_SSID";         // 你的WiFi名称
const char* password = "YOUR_WIFI_PASSWORD"; // WiFi密码

// MQTT配置
const char* mqtt_server = "localhost";       // MQTT服务器IP或域名
const int mqtt_port = 8883;                  // TLS: 8883, 非TLS: 1883
const char* mqtt_user = "mqtt_user";         // MQTT用户名
const char* mqtt_pass = "mqtt_pass";         // MQTT密码

// TLS开关
#define USE_TLS true                         // 启用TLS
```

### 2. 配置CA证书（如果使用TLS）

1. 在项目中生成CA证书：
   ```bash
   cd backend
   python -c "from app.services.certificate import CertificateService; \
              ca_key, ca_cert = CertificateService.generate_ca_certificate(); \
              print(ca_cert)"
   ```

2. 复制CA证书内容到代码中：
   ```cpp
   static const char ca_cert[] PROGMEM = R"PEM(
   -----BEGIN CERTIFICATE-----
   ...证书内容...
   -----END CERTIFICATE-----
   )PEM";
   ```

3. 如果证书包含IP地址，确保IP与mqtt_server匹配

### 3. 在数据库中注册设备

使用后端API注册设备：

```bash
# 登录获取token
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 创建设备
curl -X POST "http://localhost:8000/api/v1/devices" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "esp8266-001",
    "name": "ESP8266测试设备",
    "type": "ESP8266",
    "description": "IoT安全管理系统测试设备"
  }'
```

### 4. 生成设备证书（如果使用双向认证）

```bash
# 获取设备UUID
DEVICE_UUID=$(curl -X GET "http://localhost:8000/api/v1/devices" \
  -H "Authorization: Bearer YOUR_TOKEN" | jq -r '.[] | select(.device_id=="esp8266-001") | .id')

# 生成客户端证书
curl -X POST "http://localhost:8000/api/v1/certificates/client/generate/${DEVICE_UUID}" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "validity_days": 365
  }' > device_cert.json

# 提取证书
cat device_cert.json | jq -r '.client_cert' > device_cert.crt
cat device_cert.json | jq -r '.client_key' > device_key.key
cat device_cert.json | jq -r '.ca_cert' > ca_cert.crt
```

## 烧录步骤

### 1. 编译代码

1. 打开 `iot_guardian_device/iot_guardian_device.ino`
2. 选择开发板型号
3. 点击"验证"编译代码
4. 确认无编译错误

### 2. 连接设备

1. 使用USB线连接ESP8266到电脑
2. 安装USB驱动（如果需要）
3. 在Arduino IDE中选择正确的串口：
   - 工具 → 端口 → 选择你的串口

### 3. 烧录

1. 点击"上传"按钮
2. 等待编译完成
3. 等待烧录完成（看到"Done uploading"）
4. 打开串口监视器查看日志：
   - 工具 → 串口监视器 → 波特率设为115200

### 4. 验证连接

烧录成功后，设备将：
1. 连接WiFi
2. 连接MQTT服务器
3. 开始发送心跳和传感器数据

在串口监视器中和屏幕上应看到：

**串口输出：**
```
==========================================
IoT安全管理系统 - ESP8266设备端
==========================================
Device ID: esp8266-001
[WiFi] Connected! IP address: 192.168.1.100
[MQTT] Connected!
[MQTT] Subscribed to: devices/esp8266-001/control
[Heartbeat] Sent
[Sensor] Data sent
```

**屏幕显示：**
- 左侧（MQTT区）：连接状态、TLS握手流程、控制命令
- 右侧（Data区）：实时传感器数据（温度、湿度、电池等）

## MQTT主题说明

设备将订阅和发布以下主题：

| 主题 | 方向 | 说明 |
|------|------|------|
| `devices/{device_id}/status` | 发布 | 设备状态（上线/下线） |
| `devices/{device_id}/sensor` | 发布 | 传感器数据 |
| `devices/{device_id}/heartbeat` | 发布 | 心跳消息 |
| `devices/{device_id}/control` | 订阅 | 控制命令 |
| `devices/{device_id}/alerts` | 订阅 | 告警消息 |

## 消息格式

### 心跳消息

```json
{
  "device_id": "esp8266-001",
  "timestamp": 1696195200,
  "uptime": 3600,
  "heap": 50000,
  "rssi": -50
}
```

### 传感器数据

```json
{
  "device_id": "esp8266-001",
  "timestamp": 1696195200,
  "temperature": 25.5,
  "humidity": 60.0,
  "voltage": 3.3,
  "battery": 85.0,
  "status": {
    "wifi": "connected",
    "mqtt": "connected",
    "uptime": 3600
  }
}
```

### 控制命令

```json
{
  "command": "restart"  // 或 "led_on", "led_off"
}
```

## 故障排查

### WiFi连接失败

- 检查SSID和密码是否正确
- 确认WiFi信号强度
- 查看串口日志确认具体错误

### MQTT连接失败

- 检查服务器地址和端口是否正确
- 检查用户名和密码是否正确
- 检查防火墙是否阻挡端口
- 确认设备ID是否在数据库中注册

### TLS证书错误

- 检查CA证书是否正确配置
- 如果证书包含IP，确认IP与服务器匹配
- 测试环境下可临时使用 `secureClient->setInsecure()`

### 设备无法通信

- 检查设备是否在线（串口日志）
- 使用MQTT客户端工具测试连接
- 检查主题名称是否正确

## 高级配置

### 修改上报间隔

```cpp
const unsigned long HEARTBEAT_INTERVAL = 30000;  // 心跳间隔（毫秒）
const unsigned long SENSOR_INTERVAL = 10000;     // 传感器间隔（毫秒）
```

### 添加自定义传感器

在 `sendSensorData()` 函数中添加：

```cpp
doc["custom_sensor"] = analogRead(A0);
```

### 添加自定义控制命令

在 `mqttCallback()` 函数中添加：

```cpp
if (strstr(message, "custom_command")) {
    // 执行自定义操作
    Serial.println("[Control] Custom command executed");
}
```

## 安全建议

1. **生产环境配置**：
   - 启用TLS加密
   - 使用强密码
   - 定期更新证书
   - 启用双向认证

2. **设备管理**：
   - 使用唯一的设备ID
   - 定期更换密码
   - 监控设备行为
   - 及时更新固件

3. **网络安全**：
   - 使用独立的IoT网络
   - 限制设备访问权限
   - 配置防火墙规则
   - 监控异常流量

## 支持

如有问题，请查看：
- 项目文档：`docs/`
- API文档：`http://localhost:8000/docs`
- 证书指南：`docs/CERTIFICATE_GUIDE.md`

## 更新日志

### v1.0.0 (2025-01-03)
- ✅ 初始版本
- ✅ WiFi自动连接
- ✅ MQTT over TLS支持
- ✅ ILI9341 TFT屏幕显示
- ✅ 双窗口实时状态监控
- ✅ 心跳和传感器数据上报
- ✅ 控制命令接收
- ✅ TLS握手流程可视化

## 许可证

本项目采用 MIT 许可证，详见项目根目录 LICENSE 文件。


# 设备模板开发文档

## 目录

1. [概述](#概述)
2. [模板系统架构](#模板系统架构)
3. [创建模板](#创建模板)
4. [模板代码格式](#模板代码格式)
5. [占位符说明](#占位符说明)
6. [使用模板生成固件](#使用模板生成固件)
7. [权限要求](#权限要求)
8. [最佳实践](#最佳实践)
9. [示例模板](#示例模板)
10. [故障排查](#故障排查)

## 概述

设备模板系统允许超级管理员为不同设备类型创建和存储固件代码模板。这些模板会被加密存储，并在生成设备固件时自动使用。

### 主要特性

- **加密存储**：所有模板代码在数据库中加密存储，保护知识产权
- **类型匹配**：系统根据设备类型自动匹配对应的模板
- **占位符替换**：支持动态替换设备信息、WiFi配置、MQTT配置等
- **权限控制**：只有超级管理员可以创建、编辑和管理模板

## 模板系统架构

```
┌─────────────────┐
│  超级管理员     │
│  创建/编辑模板  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  模板管理API     │
│  (加密存储)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  数据库         │
│  (device_templates)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  固件生成服务   │
│  (解密+替换)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  设备固件代码   │
└─────────────────┘
```

## 创建模板

### 方式一：通过Web界面创建

1. 登录系统（需要超级管理员权限）
2. 导航到 **安全管理** → **模板管理** 标签页
3. 点击 **创建模板** 按钮
4. 填写模板信息：
   - **模板名称**：如 `ESP8266-ILI9341`
   - **设备类型**：如 `ESP8266`
   - **描述**：模板的功能描述
   - **模板代码**：Arduino代码（支持占位符）
   - **启用状态**：是否启用该模板
5. 点击 **确定** 保存

### 方式二：上传模板文件

1. 在 **模板管理** 页面点击 **上传模板**
2. 填写模板名称、设备类型和描述
3. 选择模板文件（支持 `.ino`, `.cpp`, `.txt` 格式）
4. 点击 **上传**

### 方式三：通过API创建

```bash
curl -X POST "http://localhost:8000/api/v1/templates" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ESP8266-ILI9341",
    "device_type": "ESP8266",
    "description": "ESP8266设备带ILI9341屏幕显示",
    "template_code": "你的模板代码...",
    "is_active": true
  }'
```

## 模板代码格式

模板代码是标准的Arduino代码，但支持占位符来动态替换配置信息。

### 基本要求

1. **代码格式**：必须是有效的Arduino代码
2. **占位符语法**：使用 `{占位符名称}` 格式
3. **编码**：UTF-8编码
4. **大小限制**：建议不超过100KB

### 支持的占位符

| 占位符 | 说明 | 示例值 |
|--------|------|--------|
| `{device_id}` | 设备唯一ID | `esp8266-001` |
| `{device_name}` | 设备名称 | `温度传感器01` |
| `{wifi_ssid}` | WiFi网络名称 | `MyWiFi` |
| `{wifi_password}` | WiFi密码 | `password123` |
| `{mqtt_server}` | MQTT服务器地址 | `192.168.1.100` |
| `{mqtt_username}` | MQTT用户名 | `iot_user` |
| `{mqtt_password}` | MQTT密码 | `mqtt_pass` |
| `{ca_cert}` | CA证书内容 | `-----BEGIN CERTIFICATE-----...` |

### 占位符使用示例

```cpp
// WiFi配置
const char* ssid = "{wifi_ssid}";
const char* password = "{wifi_password}";

// MQTT配置
const char* mqtt_server = "{mqtt_server}";
const char* mqtt_user = "{mqtt_username}";
const char* mqtt_pass = "{mqtt_password}";

// 设备标识
#define DEVICE_ID "{device_id}"
#define DEVICE_NAME "{device_name}"

// CA证书
static const char ca_cert[] PROGMEM = R"PEM(
{ca_cert}
)PEM";
```

## 占位符说明

### 设备信息占位符

#### `{device_id}`
- **类型**：字符串
- **说明**：设备的唯一标识符，用于MQTT主题和日志
- **示例**：`esp8266-001`
- **使用场景**：
  ```cpp
  #define DEVICE_ID "{device_id}"
  const char* topic = "devices/" DEVICE_ID "/status";
  ```

#### `{device_name}`
- **类型**：字符串
- **说明**：设备的显示名称，用于界面显示和日志
- **示例**：`温度传感器01`
- **使用场景**：
  ```cpp
  #define DEVICE_NAME "{device_name}"
  Serial.println("Device: " DEVICE_NAME);
  ```

### 网络配置占位符

#### `{wifi_ssid}` 和 `{wifi_password}`
- **类型**：字符串
- **说明**：WiFi网络连接信息
- **必填**：是
- **使用场景**：
  ```cpp
  WiFi.begin("{wifi_ssid}", "{wifi_password}");
  ```

#### `{mqtt_server}`
- **类型**：字符串（IP地址或域名）
- **说明**：MQTT Broker服务器地址
- **必填**：是
- **使用场景**：
  ```cpp
  mqtt.setServer("{mqtt_server}", 8883);
  ```

#### `{mqtt_username}` 和 `{mqtt_password}`
- **类型**：字符串
- **说明**：MQTT认证凭据
- **必填**：是（如果启用了MQTT认证）
- **使用场景**：
  ```cpp
  mqtt.connect(clientId, "{mqtt_username}", "{mqtt_password}");
  ```

#### `{ca_cert}`
- **类型**：字符串（PEM格式）
- **说明**：CA证书内容，用于TLS验证
- **必填**：否（如果使用TLS）
- **格式**：PEM格式证书，包含 `-----BEGIN CERTIFICATE-----` 和 `-----END CERTIFICATE-----`
- **使用场景**：
  ```cpp
  static const char ca_cert[] PROGMEM = R"PEM(
  {ca_cert}
  )PEM";
  BearSSL::X509List cert(ca_cert);
  secureClient->setTrustAnchors(&cert);
  ```

## 使用模板生成固件

### 自动匹配模板

当为设备生成固件代码时，系统会：

1. **优先使用指定模板**：如果提供了 `template_id`，使用该模板
2. **按设备类型匹配**：如果没有指定模板，根据设备类型查找匹配的模板
3. **使用默认模板**：如果找不到匹配的模板，使用系统默认模板

### 通过API生成固件

```bash
curl -X POST "http://localhost:8000/api/v1/devices/{device_id}/firmware/generate" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "wifi_ssid": "MyWiFi",
    "wifi_password": "password123",
    "mqtt_server": "192.168.1.100",
    "ca_cert": "CA证书内容（可选）",
    "template_id": "模板ID（可选）"
  }'
```

### 模板匹配规则

1. 设备类型完全匹配（如：`ESP8266`）
2. 模板状态为启用（`is_active = true`）
3. 如果多个模板匹配，使用最新创建的模板

## 权限要求

### 模板管理权限

- **创建模板**：需要超级管理员权限（`is_admin = true`）
- **编辑模板**：需要超级管理员权限
- **删除模板**：需要超级管理员权限
- **查看模板**：需要超级管理员权限（查看模板代码）
- **使用模板**：普通用户可以使用模板生成固件（但看不到模板代码）

### 权限检查

前端会自动检查用户权限：
- 非超级管理员无法看到"安全管理"菜单
- 访问模板管理页面时，后端会验证权限
- 如果权限不足，会返回403错误

## 最佳实践

### 1. 模板命名规范

- 使用描述性名称：`ESP8266-ILI9341` 而不是 `template1`
- 包含设备型号和主要特性
- 使用统一的命名格式

### 2. 代码组织

```cpp
/**********************************************************************
 * 模板头部说明
 * 设备类型：{device_type}
 * 设备ID：{device_id}
 * 
 * 功能说明：
 * - 功能1
 * - 功能2
 **********************************************************************/

// 1. 包含库
#include <...>

// 2. 配置定义
#define DEVICE_ID "{device_id}"
...

// 3. 全局变量
...

// 4. 函数定义
void setup() { ... }
void loop() { ... }
```

### 3. 错误处理

在模板中添加错误处理逻辑：

```cpp
void connectWiFi() {
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    attempts++;
  }
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[ERROR] WiFi连接失败");
    // 错误处理逻辑
  }
}
```

### 4. 日志输出

使用统一的日志格式：

```cpp
#define LOG_TAG "[{device_id}]"
Serial.println(LOG_TAG " 连接WiFi...");
Serial.println(LOG_TAG " 连接成功");
```

### 5. 资源管理

- 合理使用内存（ESP8266内存有限）
- 避免使用过大的字符串常量
- 使用 `PROGMEM` 存储常量数据

### 6. 安全性

- 不要在代码中硬编码敏感信息
- 使用TLS加密通信
- 验证证书有效性

## 示例模板

### 示例1：基础ESP8266模板

```cpp
/**********************************************************************
 * IoT安全管理系统 - ESP8266基础模板
 * 
 * 设备ID: {device_id}
 * 设备名称: {device_name}
 **********************************************************************/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// 设备配置
#define DEVICE_ID "{device_id}"
#define DEVICE_NAME "{device_name}"

// WiFi配置
const char* ssid = "{wifi_ssid}";
const char* password = "{wifi_password}";

// MQTT配置
const char* mqtt_server = "{mqtt_server}";
const char* mqtt_user = "{mqtt_username}";
const char* mqtt_pass = "{mqtt_password}";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient mqtt(espClient);

void setup() {
  Serial.begin(115200);
  
  // 连接WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi已连接");
  
  // 连接MQTT
  mqtt.setServer(mqtt_server, mqtt_port);
  while (!mqtt.connected()) {
    if (mqtt.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("MQTT已连接");
      mqtt.subscribe("devices/" DEVICE_ID "/control");
    } else {
      delay(5000);
    }
  }
}

void loop() {
  mqtt.loop();
  
  // 发送心跳
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat > 30000) {
    lastHeartbeat = millis();
    
    DynamicJsonDocument doc(256);
    doc["device_id"] = DEVICE_ID;
    doc["timestamp"] = millis() / 1000;
    
    String message;
    serializeJson(doc, message);
    mqtt.publish("devices/" DEVICE_ID "/heartbeat", message.c_str());
  }
  
  delay(100);
}
```

### 示例2：带TLS的ESP8266模板

```cpp
/**********************************************************************
 * IoT安全管理系统 - ESP8266 TLS模板
 * 
 * 设备ID: {device_id}
 * 设备名称: {device_name}
 * 使用TLS加密连接
 **********************************************************************/

#include <ESP8266WiFi.h>
#include <WiFiClientSecureBearSSL.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// 设备配置
#define DEVICE_ID "{device_id}"
#define DEVICE_NAME "{device_name}"

// WiFi配置
const char* ssid = "{wifi_ssid}";
const char* password = "{wifi_password}";

// MQTT配置
const char* mqtt_server = "{mqtt_server}";
const char* mqtt_user = "{mqtt_username}";
const char* mqtt_pass = "{mqtt_password}";
const int mqtt_port = 8883;

// CA证书
static const char ca_cert[] PROGMEM = R"PEM(
{ca_cert}
)PEM";

std::unique_ptr<BearSSL::WiFiClientSecure> secureClient(new BearSSL::WiFiClientSecure);
PubSubClient mqtt(*secureClient);

void setup() {
  Serial.begin(115200);
  
  // 连接WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi已连接");
  
  // 配置TLS
  BearSSL::X509List cert(ca_cert);
  secureClient->setTrustAnchors(&cert);
  secureClient->setBufferSizes(4096, 512);
  
  // 连接MQTT
  mqtt.setServer(mqtt_server, mqtt_port);
  while (!mqtt.connected()) {
    if (mqtt.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("MQTT已连接（TLS）");
      mqtt.subscribe("devices/" DEVICE_ID "/control");
    } else {
      delay(5000);
    }
  }
}

void loop() {
  mqtt.loop();
  
  // 发送心跳
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat > 30000) {
    lastHeartbeat = millis();
    
    DynamicJsonDocument doc(256);
    doc["device_id"] = DEVICE_ID;
    doc["timestamp"] = millis() / 1000;
    
    String message;
    serializeJson(doc, message);
    mqtt.publish("devices/" DEVICE_ID "/heartbeat", message.c_str());
  }
  
  delay(100);
}
```

### 示例3：传感器数据上报模板

```cpp
/**********************************************************************
 * IoT安全管理系统 - 传感器设备模板
 * 
 * 设备ID: {device_id}
 * 设备名称: {device_name}
 * 功能：温度、湿度传感器数据上报
 **********************************************************************/

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

#define DEVICE_ID "{device_id}"
#define DEVICE_NAME "{device_name}"

// WiFi配置
const char* ssid = "{wifi_ssid}";
const char* password = "{wifi_password}";

// MQTT配置
const char* mqtt_server = "{mqtt_server}";
const char* mqtt_user = "{mqtt_username}";
const char* mqtt_pass = "{mqtt_password}";

// 传感器配置
#define DHT_PIN D4
#define DHT_TYPE DHT22
DHT dht(DHT_PIN, DHT_TYPE);

WiFiClient espClient;
PubSubClient mqtt(espClient);

void setup() {
  Serial.begin(115200);
  dht.begin();
  
  // 连接WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi已连接");
  
  // 连接MQTT
  mqtt.setServer(mqtt_server, 1883);
  while (!mqtt.connected()) {
    if (mqtt.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("MQTT已连接");
    } else {
      delay(5000);
    }
  }
}

void loop() {
  mqtt.loop();
  
  // 读取传感器数据
  static unsigned long lastSensorRead = 0;
  if (millis() - lastSensorRead > 10000) {
    lastSensorRead = millis();
    
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    if (!isnan(temperature) && !isnan(humidity)) {
      DynamicJsonDocument doc(512);
      doc["device_id"] = DEVICE_ID;
      doc["timestamp"] = millis() / 1000;
      doc["temperature"] = temperature;
      doc["humidity"] = humidity;
      
      String message;
      serializeJson(doc, message);
      mqtt.publish("devices/" DEVICE_ID "/sensor", message.c_str());
      
      Serial.print("温度: ");
      Serial.print(temperature);
      Serial.print("°C, 湿度: ");
      Serial.print(humidity);
      Serial.println("%");
    }
  }
  
  delay(100);
}
```

## 故障排查

### 问题1：模板列表返回500错误

**可能原因**：
- 数据库表不存在
- 权限不足
- 解密失败

**解决方案**：
1. 运行数据库迁移：`alembic upgrade head`
2. 检查用户是否为超级管理员
3. 查看后端日志获取详细错误信息

### 问题2：模板代码解密失败

**可能原因**：
- 加密密钥不匹配
- 模板代码格式错误

**解决方案**：
1. 检查 `CERT_ENCRYPTION_KEY` 配置
2. 重新创建模板
3. 系统会自动处理未加密的旧数据

### 问题3：固件生成时未使用模板

**可能原因**：
- 设备类型不匹配
- 模板未启用
- 模板不存在

**解决方案**：
1. 检查设备类型是否与模板的 `device_type` 匹配
2. 确保模板的 `is_active` 为 `true`
3. 在生成固件时指定 `template_id`

### 问题4：占位符未替换

**可能原因**：
- 占位符名称拼写错误
- 占位符格式不正确（应使用 `{name}` 格式）

**解决方案**：
1. 检查占位符名称是否正确
2. 确保使用大括号 `{}` 包围占位符
3. 查看生成的固件代码确认替换结果

## API参考

### 创建模板

```http
POST /api/v1/templates
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "模板名称",
  "device_type": "设备类型",
  "description": "模板描述",
  "template_code": "模板代码",
  "is_active": true
}
```

### 获取模板列表

```http
GET /api/v1/templates?skip=0&limit=100&device_type=ESP8266
Authorization: Bearer {token}
```

### 获取模板详情

```http
GET /api/v1/templates/{template_id}
Authorization: Bearer {token}
```

### 更新模板

```http
PUT /api/v1/templates/{template_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "新名称",
  "template_code": "新代码",
  "is_active": false
}
```

### 删除模板

```http
DELETE /api/v1/templates/{template_id}
Authorization: Bearer {token}
```

### 上传模板文件

```http
POST /api/v1/templates/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

name=模板名称
device_type=设备类型
description=描述
file=模板文件
```

## 安全注意事项

1. **加密存储**：所有模板代码在数据库中加密存储
2. **权限控制**：只有超级管理员可以查看模板代码
3. **访问控制**：普通用户只能使用模板生成固件，无法查看模板代码
4. **密钥管理**：妥善保管 `CERT_ENCRYPTION_KEY`，丢失将无法解密模板

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本
- 支持模板创建、编辑、删除
- 支持模板代码加密存储
- 支持占位符替换
- 支持按设备类型自动匹配模板

## 相关文档

- [证书管理文档](./CERTIFICATE_ENCRYPTION.md)
- [API文档](../backend/README.md)
- [设备管理文档](./DEVICE_MANAGEMENT.md)

## 技术支持

如有问题，请：
1. 查看后端日志获取详细错误信息
2. 检查数据库连接和表结构
3. 验证用户权限和配置
4. 联系系统管理员


# ESP8266设备消息格式说明

## 设备发送的消息格式

### 1. 传感器数据 (`devices/esp8266/sensor`)

设备每10秒发送一次传感器数据，格式如下：

```json
{
  "device_id": "esp8266",
  "timestamp": 1762254901,
  "temperature": 25.5,
  "humidity": 60.0,
  "voltage": 3.3,
  "battery": 85.0,
  "status": {
    "wifi": "connected",
    "mqtt": "connected",
    "uptime": 1762254901
  }
}
```

**字段说明：**
- `device_id`: 设备ID（固定为 "esp8266"）
- `timestamp`: 时间戳（秒）
- `temperature`: 温度（摄氏度）
- `humidity`: 湿度（百分比）
- `voltage`: 电压（伏特）
- `battery`: 电池电量（百分比）
- `status`: 状态信息
  - `wifi`: WiFi连接状态
  - `mqtt`: MQTT连接状态
  - `uptime`: 运行时间（秒）

### 2. 心跳消息 (`devices/esp8266/heartbeat`)

设备每30秒发送一次心跳，格式如下：

```json
{
  "device_id": "esp8266",
  "timestamp": 1762254901,
  "uptime": 1762254901,
  "heap": 50000,
  "rssi": -45
}
```

**字段说明：**
- `device_id`: 设备ID
- `timestamp`: 时间戳（秒）
- `uptime`: 运行时间（秒）
- `heap`: 可用内存（字节）
- `rssi`: WiFi信号强度（dBm）

### 3. 状态消息 (`devices/esp8266/status`)

设备上线时发送状态消息：

```json
{
  "status": "online",
  "device_id": "esp8266"
}
```

## 后端处理逻辑

后端会：
1. 接收所有 `devices/esp8266/*` 主题的消息
2. 解析 `device_id` 和消息类型
3. 更新设备状态为 "online"
4. 对于传感器数据，提取以下指标并保存到数据库：
   - `temperature` → DeviceMetrics (metric_type: "temperature")
   - `humidity` → DeviceMetrics (metric_type: "humidity")
   - `voltage` → DeviceMetrics (metric_type: "voltage")
   - `battery` → DeviceMetrics (metric_type: "battery")
   - `wifi_status` → DeviceMetrics (metric_type: "wifi_status")
   - `mqtt_status` → DeviceMetrics (metric_type: "mqtt_status")
   - `uptime` → DeviceMetrics (metric_type: "uptime")

## 数据库存储

每个指标都会创建一条独立的 `DeviceMetrics` 记录：
- `device_id`: 设备的UUID（从数据库查询）
- `metric_type`: 指标类型（如 "temperature", "humidity" 等）
- `metrics`: JSON格式存储 `{"value": 25.5}`
- `timestamp`: 记录时间

## 验证消息接收

### 1. 使用监控脚本
```bash
./scripts/monitor_mqtt.sh
```

### 2. 检查后端日志
在后端运行终端中查找 `[MQTT]` 标记的日志：
- `[MQTT] Received message on topic: ...`
- `[MQTT Processor] Got message from queue: ...`
- `[MQTT] Parsed device_id: esp8266, message_type: sensor`
- `[MQTT] Saved X sensor metrics for device esp8266: ...`

### 3. 检查数据库
```sql
SELECT * FROM device_metrics 
WHERE device_id = (SELECT id FROM devices WHERE device_id = 'esp8266')
ORDER BY timestamp DESC 
LIMIT 10;
```

## 故障排查

如果消息没有保存到数据库：

1. **检查设备连接**
   - 确认设备连接到正确的MQTT服务器（10.42.0.1:8883）
   - 确认设备用户名密码正确（admin/admin）

2. **检查后端连接**
   - 确认后端连接到 localhost:1883
   - 确认后端订阅了 `devices/+/sensor` 主题

3. **检查设备ID匹配**
   - 确认数据库中有 `device_id = 'esp8266'` 的设备记录

4. **查看后端日志**
   - 查找错误信息
   - 确认消息是否被接收和处理


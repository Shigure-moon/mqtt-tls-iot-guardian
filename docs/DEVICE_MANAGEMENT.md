# ESP8266设备管理系统

## 概述

本系统支持多种ESP8266设备类型的管理和控制，包括：
- **智能门锁** (Door Lock)
- **智能窗帘** (Curtain)
- **传感器集成设备** (Sensor Hub)
- **智能开关** (Switch)
- **智能灯光** (Light)

系统会根据设备返回的信息自动识别设备类型和版本，并显示对应的控制界面。

## 设备类型识别

系统通过以下方式识别设备类型：

1. **设备类型字段** (`type`): 检查是否包含关键词（door_lock, curtain, sensor等）
2. **设备属性** (`attributes`): 检查是否有特定属性（如 `has_lock`, `position`, `temperature`等）
3. **设备描述** (`description`): 从描述文本中提取关键词

### 设备类型定义

```typescript
enum DeviceType {
  DOOR_LOCK = 'door_lock',        // 门锁
  CURTAIN = 'curtain',            // 窗帘
  SENSOR_HUB = 'sensor_hub',     // 传感器集成设备
  SWITCH = 'switch',             // 开关
  LIGHT = 'light',               // 灯光
  UNKNOWN = 'unknown'            // 未知类型
}
```

## 设备控制组件

### 1. 门锁控制 (DoorLockControl)

**功能特性：**
- 锁定/解锁控制
- 锁状态显示
- 电池电量监控
- 操作历史记录
- 高级设置（自动锁定、低电量提醒）

**支持的命令：**
- `lock` - 锁定门锁
- `unlock` - 解锁门锁
- `get_status` - 获取锁状态和电池电量
- `update_settings` - 更新设备设置

**MQTT主题：**
- 控制命令：`devices/{device_id}/control`
- 状态响应：`devices/{device_id}/status`

### 2. 窗帘控制 (CurtainControl)

**功能特性：**
- 打开/关闭/停止控制
- 位置滑块控制（0-100%）
- 实时位置显示

**支持的命令：**
- `open` - 打开窗帘
- `close` - 关闭窗帘
- `stop` - 停止窗帘
- `set_position` - 设置窗帘位置（0-100%）
- `get_status` - 获取当前位置

### 3. 传感器集成设备 (SensorHubControl)

**功能特性：**
- 实时传感器数据显示
- 支持多种传感器类型：
  - 温度 (temperature)
  - 湿度 (humidity)
  - 气压 (pressure)
  - 空气质量 (air_quality)

**支持的命令：**
- `read_sensors` - 读取所有传感器数据

## API端点

### 发送设备命令

**端点：** `POST /api/v1/devices/{device_id}/command`

**请求体：**
```json
{
  "command": "lock",           // 命令名称（必需）
  "topic": "devices/xxx/control",  // MQTT主题（可选，默认使用 devices/{device_id}/control）
  "payload": {                 // 额外参数（可选）
    "position": 50
  },
  "qos": 1                     // MQTT QoS级别（可选，默认1）
}
```

**响应：**
```json
{
  "success": true,
  "message": "命令已成功发送到设备",
  "topic": "devices/xxx/control",
  "command": "lock"
}
```

**支持的设备ID格式：**
- UUID格式（设备的数据库ID）
- 设备ID字符串（设备的device_id字段）

## MQTT消息格式

### 控制命令消息

设备订阅主题：`devices/{device_id}/control`

**消息格式：**
```json
{
  "command": "lock",
  "device_id": "esp8266-001",
  "timestamp": "2024-01-01T12:00:00Z",
  "position": 50  // 可选，根据命令类型
}
```

### 设备状态响应

设备发布主题：`devices/{device_id}/status`

**门锁状态格式：**
```json
{
  "device_id": "esp8266-001",
  "lock_status": "locked",  // "locked" | "unlocked"
  "battery": 85,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**窗帘状态格式：**
```json
{
  "device_id": "esp8266-001",
  "position": 50,  // 0-100
  "status": "stopped",  // "opening" | "closing" | "stopped"
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**传感器数据格式：**
```json
{
  "device_id": "esp8266-001",
  "temperature": 25.5,
  "humidity": 60,
  "pressure": 1013.25,
  "air_quality": "good",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 使用示例

### 1. 创建设备时指定类型

在创建设备时，可以通过以下方式指定设备类型：

```javascript
// 方式1：通过type字段
{
  device_id: "esp8266-lock-001",
  name: "智能门锁001",
  type: "door_lock_v2",  // 包含door_lock关键词
  description: "ESP8266智能门锁设备"
}

// 方式2：通过attributes字段
{
  device_id: "esp8266-lock-001",
  name: "智能门锁001",
  type: "ESP8266",
  attributes: {
    device_type: "door_lock",
    version: "v2",
    has_lock: true,
    battery: 85
  }
}
```

### 2. 设备详情页面

访问设备详情页面时，系统会：
1. 自动识别设备类型
2. 加载对应的控制组件
3. 显示设备特定的控制界面

**URL格式：** `/devices/{device_uuid}`

### 3. 发送控制命令

```javascript
// 锁定门锁
await request.post(`/devices/${deviceId}/command`, {
  command: 'lock'
})

// 设置窗帘位置
await request.post(`/devices/${deviceId}/command`, {
  command: 'set_position',
  payload: { position: 75 }
})

// 读取传感器数据
await request.post(`/devices/${deviceId}/command`, {
  command: 'read_sensors'
})
```

## 扩展新设备类型

### 1. 添加设备类型定义

在 `frontend/src/types/device-types.ts` 中添加新的设备类型：

```typescript
export enum DeviceType {
  // ... 现有类型
  NEW_DEVICE = 'new_device'
}
```

### 2. 更新识别逻辑

在 `identifyDeviceType` 函数中添加识别规则：

```typescript
if (typeLower.includes('new_device')) {
  return {
    type: DeviceType.NEW_DEVICE,
    capabilities: ['action1', 'action2'],
    attributes: device.attributes
  }
}
```

### 3. 创建控制组件

创建 `frontend/src/components/devices/NewDeviceControl.vue`：

```vue
<template>
  <el-card>
    <!-- 控制界面 -->
  </el-card>
</template>

<script setup lang="ts">
// 实现控制逻辑
</script>
```

### 4. 注册组件

在 `frontend/src/views/devices/detail.vue` 中注册新组件：

```typescript
import NewDeviceControl from '@/components/devices/NewDeviceControl.vue'

// 在 loadDeviceControlComponent 函数中添加：
case DeviceType.NEW_DEVICE:
  deviceControlComponent.value = NewDeviceControl
  break
```

## 注意事项

1. **设备ID格式**：API端点同时支持UUID和device_id字符串，系统会自动识别
2. **MQTT连接**：确保MQTT服务正常运行，否则无法发送控制命令
3. **状态同步**：设备状态需要通过MQTT订阅获取，控制命令只是发送指令
4. **错误处理**：所有控制操作都有完善的错误处理和用户提示

## 测试门锁控制

1. 创建一个类型为 `door_lock` 的设备
2. 访问设备详情页面
3. 系统会自动识别为门锁设备并显示门锁控制界面
4. 点击"锁定"或"解锁"按钮测试控制功能

## 文件结构

```
frontend/src/
├── types/
│   └── device-types.ts          # 设备类型定义和识别逻辑
├── components/
│   └── devices/
│       ├── DoorLockControl.vue  # 门锁控制组件
│       ├── CurtainControl.vue   # 窗帘控制组件
│       └── SensorHubControl.vue # 传感器控制组件
└── views/
    └── devices/
        └── detail.vue           # 设备详情页面（已更新）

backend/app/
└── api/
    └── api_v1/
        └── devices.py           # 设备API（已添加命令端点）
```


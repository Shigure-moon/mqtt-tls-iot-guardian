# API设计文档

## 一、API概述

### 1.1 基本信息
- 基础URL: `https://api.example.com/v1`
- 认证方式: Bearer Token (JWT)
- 响应格式: JSON
- API版本: v1
- 请求编码: UTF-8

### 1.2 通用规范

#### 1.2.1 请求头
```http
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
X-Request-ID: <uuid>
```

#### 1.2.2 响应格式
```json
{
    "code": 200,
    "message": "success",
    "data": {},
    "requestId": "xxx-xxx-xxx"
}
```

#### 1.2.3 错误码
```json
{
    "code": 400,
    "message": "错误描述",
    "errors": [{
        "field": "字段名",
        "message": "具体错误"
    }],
    "requestId": "xxx-xxx-xxx"
}
```

## 二、REST API接口

### 2.1 认证相关接口

#### 2.1.1 用户登录
```yaml
POST /auth/login
请求体:
  {
    "username": "string",
    "password": "string",
    "totp": "string"  # 可选，双因素认证
  }
响应:
  {
    "code": 200,
    "data": {
      "token": "string",
      "refreshToken": "string",
      "expiresIn": 3600
    }
  }
```

#### 2.1.2 刷新令牌
```yaml
POST /auth/refresh
请求头:
  Authorization: Bearer <refresh_token>
响应:
  {
    "code": 200,
    "data": {
      "token": "string",
      "refreshToken": "string",
      "expiresIn": 3600
    }
  }
```

### 2.2 设备管理接口

#### 2.2.1 设备注册
```yaml
POST /devices
请求体:
  {
    "deviceId": "string",
    "name": "string",
    "type": "string",
    "description": "string",
    "attributes": {
      "manufacturer": "string",
      "model": "string",
      "version": "string"
    }
  }
响应:
  {
    "code": 200,
    "data": {
      "id": "string",
      "certificate": "string",
      "privateKey": "string"
    }
  }
```

#### 2.2.2 获取设备列表
```yaml
GET /devices
参数:
  page: int
  size: int
  type: string
  status: string
响应:
  {
    "code": 200,
    "data": {
      "total": 100,
      "items": [{
        "id": "string",
        "deviceId": "string",
        "name": "string",
        "type": "string",
        "status": "string",
        "lastOnline": "datetime",
        "attributes": {}
      }]
    }
  }
```

#### 2.2.3 获取设备详情
```yaml
GET /devices/{deviceId}
响应:
  {
    "code": 200,
    "data": {
      "id": "string",
      "deviceId": "string",
      "name": "string",
      "type": "string",
      "status": "string",
      "lastOnline": "datetime",
      "attributes": {},
      "statistics": {
        "messagesSent": 0,
        "messagesReceived": 0,
        "lastMessageTime": "datetime"
      }
    }
  }
```

### 2.3 证书管理接口

#### 2.3.1 生成设备证书
```yaml
POST /devices/{deviceId}/certificates
请求体:
  {
    "validDays": 365,
    "algorithm": "SM2"  # 可选：SM2, RSA
  }
响应:
  {
    "code": 200,
    "data": {
      "certificateId": "string",
      "certificate": "string",
      "privateKey": "string",
      "expireTime": "datetime"
    }
  }
```

#### 2.3.2 吊销证书
```yaml
POST /devices/{deviceId}/certificates/{certificateId}/revoke
请求体:
  {
    "reason": "string"
  }
响应:
  {
    "code": 200,
    "data": {
      "revokeTime": "datetime",
      "status": "revoked"
    }
  }
```

### 2.4 安全策略接口

#### 2.4.1 设置访问控制策略
```yaml
POST /acl/policies
请求体:
  {
    "deviceId": "string",
    "topic": "string",
    "action": "publish|subscribe",
    "effect": "allow|deny",
    "conditions": {
      "timeRange": ["08:00-18:00"],
      "ipRange": ["192.168.1.0/24"]
    }
  }
响应:
  {
    "code": 200,
    "data": {
      "id": "string",
      "createdAt": "datetime"
    }
  }
```

### 2.5 监控告警接口

#### 2.5.1 获取实时监控数据
```yaml
GET /monitoring/devices/{deviceId}/metrics
参数:
  metric: string    # cpu, memory, network
  period: string    # 1m, 5m, 15m, 1h
响应:
  {
    "code": 200,
    "data": {
      "metric": "string",
      "timestamps": ["datetime"],
      "values": [0.0]
    }
  }
```

#### 2.5.2 配置告警规则
```yaml
POST /alerts/rules
请求体:
  {
    "name": "string",
    "deviceId": "string",
    "metric": "string",
    "condition": ">= 90",
    "duration": "5m",
    "severity": "high",
    "actions": [{
      "type": "email",
      "target": "admin@example.com"
    }]
  }
响应:
  {
    "code": 200,
    "data": {
      "id": "string",
      "status": "active"
    }
  }
```

## 三、MQTT主题设计

### 3.1 系统主题
```
sys/
  ├── heartbeat/          # 心跳消息
  │   └── {deviceId}
  ├── status/            # 设备状态
  │   └── {deviceId}
  └── monitor/           # 系统监控
      └── {deviceId}/
          ├── cpu
          ├── memory
          └── network
```

### 3.2 业务主题
```
devices/
  └── {deviceId}/
      ├── data          # 设备数据上报
      ├── config        # 配置下发
      ├── command       # 命令下发
      └── response      # 命令响应
```

### 3.3 告警主题
```
alerts/
  └── {deviceId}/
      ├── system       # 系统告警
      ├── security     # 安全告警
      └── business     # 业务告警
```

### 3.4 主题权限设计
```yaml
普通设备:
  发布:
    - devices/{deviceId}/data
    - devices/{deviceId}/response
    - sys/heartbeat/{deviceId}
    - sys/status/{deviceId}
  订阅:
    - devices/{deviceId}/config
    - devices/{deviceId}/command

管理设备:
  发布: [上述权限 +]
    - sys/monitor/{deviceId}/#
  订阅: [上述权限 +]
    - alerts/{deviceId}/#

系统服务:
  发布订阅:
    - $SYS/#
    - devices/+/config
    - devices/+/command
    - alerts/#
```

## 四、WebSocket接口

### 4.1 实时数据推送
```yaml
连接URL: ws://api.example.com/v1/ws
认证头:
  Authorization: Bearer <token>

消息格式:
  {
    "type": "data|alert|status",
    "deviceId": "string",
    "timestamp": "datetime",
    "payload": {}
  }
```

## 五、API安全设计

### 5.1 认证安全
- JWT + 签名验证
- Token轮换机制
- 访问频率限制
- IP白名单校验

### 5.2 通信安全
- TLS 1.3加密
- 证书双向认证
- 报文签名校验
- 时间戳防重放

### 5.3 数据安全
- 敏感数据加密
- 参数校验过滤
- 日志脱敏记录
- 审计追踪
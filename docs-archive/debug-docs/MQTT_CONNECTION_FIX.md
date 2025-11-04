# MQTT连接问题修复指南

## 问题分析

当前配置存在端口和认证不匹配的问题：

### 设备端配置（ESP8266）
- **服务器**: `10.42.0.1:8883` (TLS端口)
- **用户名**: `admin`
- **密码**: `admin`
- **协议**: MQTT over TLS

### 后端配置
- **服务器**: `localhost:1883` (非TLS端口)
- **用户名**: `admin`
- **密码**: `admin`
- **协议**: 普通MQTT

### 问题
1. 设备连接到8883端口（TLS），后端连接到1883端口（非TLS），消息无法互通
2. EMQX的8883端口可能没有正确配置TLS证书
3. 需要统一端口和认证配置

## 解决方案

### 方案1: 统一使用非TLS连接（推荐用于开发测试）

#### 步骤1: 修改设备固件
将 `shili_encrypted.ino` 中的配置改为：
```cpp
const char* mqtt_server = "10.42.0.1";   // 或 "localhost"
const int mqtt_port = 1883;              // 改为非TLS端口
#define USE_TLS false                     // 禁用TLS
```

#### 步骤2: 重新编译和烧录设备固件

#### 步骤3: 验证后端连接
确保后端配置正确：
```bash
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=admin
MQTT_PASSWORD=admin  # 或 public（取决于EMQX配置）
```

### 方案2: 统一使用TLS连接（推荐用于生产环境）

#### 步骤1: 配置EMQX TLS证书
需要在EMQX中配置TLS证书，参考EMQX文档。

#### 步骤2: 修改后端连接TLS端口
更新后端配置使用TLS端口（如果EMQX配置了TLS）：
```bash
MQTT_BROKER_PORT=18883  # 或容器映射的TLS端口
```

#### 步骤3: 修改后端代码支持TLS
需要在 `backend/app/core/events.py` 中添加TLS支持。

### 方案3: 使用EMQX的1883端口（最简单）

EMQX默认监听1883端口，可以直接使用：

1. **设备端**: 修改为 `mqtt_port = 1883` 和 `USE_TLS false`
2. **后端**: 保持 `MQTT_BROKER_PORT=1883`
3. **验证认证**: 确认EMQX的用户名密码是 `admin/admin` 还是 `admin/public`

## 快速修复步骤

### 1. 验证EMQX认证
```bash
# 测试不同密码
mosquitto_sub -h localhost -p 1883 -u admin -P admin -t "test" -v
mosquitto_sub -h localhost -p 1883 -u admin -P public -t "test" -v
```

### 2. 检查EMQX Web界面
访问 `http://localhost:18083` 查看：
- 连接数
- 订阅的主题
- 认证用户

### 3. 监控MQTT消息
```bash
# 使用正确密码监控
MQTT_PASS=admin ./scripts/monitor_mqtt.sh
# 或
MQTT_PASS=public ./scripts/monitor_mqtt.sh
```

## 当前配置检查清单

- [ ] 设备连接到哪个端口？（8883 TLS 或 1883 非TLS）
- [ ] 后端连接到哪个端口？（1883）
- [ ] EMQX用户名密码是什么？（admin/admin 或 admin/public）
- [ ] EMQX是否启用了TLS？（检查8883端口配置）
- [ ] 端口映射是否正确？（检查docker port emqx）

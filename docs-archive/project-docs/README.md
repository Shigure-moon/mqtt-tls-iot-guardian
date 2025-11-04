# 基于MQTT与TLS的物联网设备安全管理与入侵检测系统

## 项目概述
本项目旨在构建一个完整的物联网设备安全管理与入侵检测系统，通过MQTT协议和TLS加密确保设备通信安全，实现设备管理、数据采集、安全监控和入侵检测等功能。

## 系统架构
- 设备层：ESP8266物联网设备
- 通信层：MQTT+TLS安全传输
- 应用层：FastAPI后端+Vue3前端
- 存储层：PostgreSQL+Redis

## 主要功能
1. 设备管理与监控
2. 安全认证与加密通信
3. TLS证书管理系统
4. 入侵检测与告警
5. 数据采集与分析
6. 系统管理与配置

## 目录结构
```
mqtt-tls-iot-guardian/
├── docs/              # 项目文档
├── backend/           # 后端服务
├── frontend/          # 前端界面
├── device/            # 设备端程序
│   └── esp8266/       # ESP8266设备代码
├── scripts/           # 启动脚本
├── docker-compose.yml # Docker编排文件
└── README.md          # 本文件
```

## 技术栈
- 后端：Python 3.11+, FastAPI, SQLAlchemy, Paho-MQTT
- 前端：Vue 3, Element Plus, ECharts
- 数据库：PostgreSQL, Redis
- 通信：MQTT, TLS 1.3
- 部署：Docker, Nginx, RockyLinux 10

## 快速开始

### 环境要求
- Python 3.11+
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 14+
- Redis 7+

### 启动步骤

**方式一：一键启动（最简单）**

```bash
# 1. 启动Docker服务
./scripts/quick_start.sh

# 2. 启动后端（新终端）
./scripts/start_backend.sh

# 3. 启动前端（新终端）
./scripts/start_frontend.sh
```

**方式二：手动启动**

详细说明请查看 [启动脚本文档](scripts/README.md)

### ESP8266设备配置

烧录设备端代码：

1. 使用Arduino IDE打开 `device/esp8266/iot_guardian_device.ino`
2. 配置WiFi信息（SSID和密码）
3. 配置MQTT服务器地址
4. 编译并烧录到ESP8266设备

**当前配置**（TLS加密模式）：
- **WiFi SSID**: `huawei9930`
- **MQTT服务器**: `192.168.1.8`
- **MQTT端口**: `8883` (TLS加密)
- **TLS已启用**: `USE_TLS true`

### 默认账号
- **用户名**: `admin`
- **密码**: `admin123`

> ⚠️ 首次使用前必须运行初始化脚本创建管理员账号

### MQTT服务器配置

在添加设备并生成烧录代码时，**MQTT服务器**应填写：

- **局域网环境**: 填写运行后端服务的服务器的局域网IP地址
  - 例如：`192.168.1.8`
- **本地开发**: 可以填写 `localhost` 或 `127.0.0.1`
  - ⚠️ 注意：设备必须能够访问该地址，如果设备和服务器不在同一网络，请使用局域网IP

**查看服务器IP的方法**：
```bash
# Linux/macOS
hostname -I

# Windows
ipconfig
```

**端口配置**：
- 非TLS端口：1883
- TLS端口：8883

## 开发团队
- 项目负责人：[待定]
- 后端开发：[待定]
- 前端开发：[待定]
- 设备开发：[待定]
- 运维支持：[待定]

## 项目进度
详细进度请查看 `docs/PROJECT_STATUS.md`

当前完成度：**约 95%**

### 已完成功能
✅ 用户认证授权  
✅ 设备管理（后端+前端）  
✅ TLS证书管理  
✅ MQTT通信配置（TLS加密）  
✅ 实时数据采集与存储  
✅ 前端监控界面（Vue3 + ECharts）  
✅ 自动刷新与数据可视化  
✅ 监控告警框架  
✅ 设备详情页面  
✅ Docker容器化部署  
✅ 启动脚本自动化  

### 主要文档
- 📖 [启动脚本说明](scripts/README.md) - **重要！首先阅读**
- [项目计划](docs/PROJECT_PLAN.md)
- [架构设计](docs/ARCHITECTURE.md)
- [API设计](docs/API_DESIGN.md)
- [数据库设计](docs/DATABASE_DESIGN.md)
- [证书管理指南](docs/CERTIFICATE_GUIDE.md)
- [部署文档](docs/DEPLOYMENT.md)
- [安全设计](docs/SECURITY_DESIGN.md)
- [项目状态](docs/PROJECT_STATUS.md)
- 📝 [模板开发文档](docs/TEMPLATE_DEVELOPMENT.md) - **模板创建与使用指南**
- 🚀 [实施路线图](docs/IMPLEMENTATION_ROADMAP.md) - **Docker Swarm容灾与数据库管理实施计划**
- 🏗️ [Docker Swarm容灾规划](docs/DOCKER_SWARM_DISASTER_RECOVERY.md) - **高可用架构设计**
- 💾 [数据库管理框架](docs/DATABASE_MANAGEMENT_FRAMEWORK.md) - **数据库管理功能设计**

## 快速命令参考

```bash
# 启动所有Docker服务
./scripts/quick_start.sh

# 启动后端服务
./scripts/start_backend.sh

# 启动前端服务
./scripts/start_frontend.sh

# 停止所有服务
docker compose down

# 查看服务日志
docker compose logs -f mosquitto

# 查看MQTT连接
docker compose logs mosquitto | grep "New client"
```
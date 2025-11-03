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

1. **启动数据库服务**
   ```bash
   docker compose up -d
   ```

2. **初始化后端**
   ```bash
   cd backend
   pip install -r requirements.txt
   python scripts/init_admin.py  # 创建默认管理员账号
   # 运行数据库迁移
   alembic upgrade head
   ```

3. **启动后端服务**
   ```bash
   # 方式1：使用启动脚本（推荐）
   ./scripts/start_backend.sh
   
   # 方式2：手动启动
   cd backend
   python main.py
   ```
   > 后端将在 http://localhost:8000 运行，API文档: http://localhost:8000/docs

4. **启动前端服务**
   ```bash
   # 方式1：使用启动脚本（推荐）
   ./scripts/start_frontend.sh
   
   # 方式2：手动启动
   cd frontend
   npm install
   npm run dev
   ```
   > 前端将在 http://localhost:5173 运行

5. **烧录设备端代码**
   - 查看设备端烧录指南: `device/esp8266/README.md`
   - 使用Arduino IDE打开 `device/esp8266/iot_guardian_device.ino`
   - 配置WiFi和MQTT信息
   - 编译并烧录到ESP8266设备

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

当前完成度：**约 40-45%**

### 已完成功能
✅ 用户认证授权  
✅ 设备管理（后端+前端）  
✅ TLS证书管理  
✅ MQTT通信配置  
✅ 监控告警框架  

### 主要文档
- [项目计划](docs/PROJECT_PLAN.md)
- [架构设计](docs/ARCHITECTURE.md)
- [API设计](docs/API_DESIGN.md)
- [数据库设计](docs/DATABASE_DESIGN.md)
- [证书管理指南](docs/CERTIFICATE_GUIDE.md)
- [部署文档](docs/DEPLOYMENT.md)
- [安全设计](docs/SECURITY_DESIGN.md)
- [项目状态](docs/PROJECT_STATUS.md)
# MQTT TLS IoT Guardian

基于MQTT与TLS的物联网设备安全管理与入侵检测系统

## 项目简介

本系统是一个完整的IoT设备安全管理平台，提供：

- 🔐 **设备认证与授权** - 基于JWT和设备证书的双重认证
- 🔒 **TLS加密通信** - 端到端加密的MQTT通信
- 📦 **固件管理** - 固件模板管理、编译、加密和OTA更新
- 📊 **设备监控** - 实时设备状态监控和传感器数据采集
- 🛡️ **安全防护** - 证书管理、加密密钥管理、访问控制

## 技术栈

### 后端
- **FastAPI** - 异步Web框架
- **PostgreSQL** - 关系型数据库
- **Redis** - 缓存和会话存储
- **MQTT (EMQX)** - 消息代理
- **Arduino CLI** - 固件编译工具

### 前端
- **Vue 3** - 前端框架
- **Element Plus** - UI组件库
- **TypeScript** - 类型安全

### 设备端
- **ESP8266** - IoT设备
- **Arduino** - 开发框架
- **MQTT over TLS** - 安全通信

## 快速开始

### 前置要求

- Python 3.11+
- Node.js 18+
- PostgreSQL 14+
- Redis 6+
- EMQX 5.0+ (或Mosquitto)
- Arduino CLI (可选，用于固件编译)

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/Shigure-moon/mqtt-tls-iot-guardian.git
   cd mqtt-tls-iot-guardian
   ```

2. **配置环境变量**
   ```bash
   cd backend
   cp .env.example .env
   # 编辑 .env 文件，配置数据库、Redis、MQTT等
   ```

3. **启动服务**
   ```bash
   # 启动后端
   ./scripts/start_backend.sh
   
   # 启动前端（新终端）
   ./scripts/start_frontend.sh
   ```

4. **初始化数据库**
   ```bash
   cd backend
   alembic upgrade head
   python scripts/init_admin.py
   ```

5. **访问系统**
   - 前端: http://localhost:5173
   - API文档: http://localhost:8000/docs
   - 默认管理员: admin / admin123

## 项目结构

```
mqtt-tls-iot-guardian/
├── backend/              # 后端服务
│   ├── app/             # 应用代码
│   ├── alembic/         # 数据库迁移
│   └── data/            # 数据目录（证书、固件等）
├── frontend/             # 前端应用
├── device/               # 设备端代码
├── scripts/              # 工具脚本
├── docs/                 # 系统文档（技术文档）
└── docs-archive/         # 归档文档（测试、项目、调试文档）
    ├── test-docs/        # 测试文档
    ├── project-docs/     # 项目文档
    └── debug-docs/       # 调试文档
```

## 核心功能

### 1. 设备管理
- 设备注册和认证
- 设备状态监控
- 设备证书管理

### 2. 固件管理
- 固件模板管理（版本控制）
- 固件编译（Arduino CLI远程库管理）
- 固件加密（XOR掩码）
- OTA更新

### 3. 证书管理
- CA证书生成和管理
- 服务器证书生成和管理
- 设备客户端证书生成和管理

### 4. 安全通信
- MQTT over TLS
- 证书验证
- 加密密钥管理

## 文档

### 系统文档（docs/）
- `ARCHITECTURE.md` - 系统架构设计
- `API_DESIGN.md` - API设计文档
- `SECURITY_DESIGN.md` - 安全设计
- `DATABASE_DESIGN.md` - 数据库设计
- `DEPLOYMENT.md` - 部署指南

### 归档文档（docs-archive/）
- `test-docs/` - 测试说明文档
- `project-docs/` - 项目说明文档
- `debug-docs/` - 调试文档

## 许可证

详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交Issue和Pull Request！


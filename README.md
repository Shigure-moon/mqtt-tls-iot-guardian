# MQTT TLS IoT Guardian

基于MQTT与TLS的物联网设备安全管理与入侵检测系统

## 项目简介

本系统是一个完整的IoT设备安全管理平台，提供：

- 🔐 **设备认证与授权** - 基于JWT和设备证书的双重认证
- 🔒 **TLS加密通信** - 端到端加密的MQTT通信
- 📦 **固件管理** - 固件模板管理、编译、加密和OTA更新
- 📊 **设备监控** - 实时设备状态监控和传感器数据采集
- 🛡️ **安全防护** - 证书管理、加密密钥管理、访问控制
- 🤖 **智能入侵检测** - 基于LLM的智能入侵检测与自适应防御系统

## 技术栈

### 后端
- **FastAPI** - 异步Web框架
- **PostgreSQL** - 关系型数据库（支持 pgvector 向量扩展）
- **Redis** - 缓存和会话存储
- **MQTT (Mosquitto)** - 消息代理，支持TLS加密
- **Arduino CLI** - 固件编译工具

### 前端
- **Vue 3** - 前端框架
- **Element Plus** - UI组件库
- **TypeScript** - 类型安全

### 设备端
- **ESP8266** - IoT设备
- **Arduino** - 开发框架
- **MQTT over TLS** - 安全通信

### 安全与入侵检测
- **LLM-IDS-Agent** - 基于大型语言模型的智能入侵检测代理
- **CyberSentinal** - 多智能体AI系统，实时日志分析、威胁检测和自主缓解
- **ELK Stack** - 日志收集与分析（可选）

## 快速开始

### 前置要求

- Python 3.11+
- Node.js 18+
- Docker & Docker Compose (推荐)
- PostgreSQL 14+ (或使用Docker)
- Redis 6+ (或使用Docker)
- Mosquitto MQTT Broker (或使用Docker)
- Arduino CLI (可选，用于固件编译)

### 安装步骤

#### 方式一：使用 Docker Compose（推荐）

1. **克隆仓库**
   ```bash
   git clone https://github.com/Shigure-moon/mqtt-tls-iot-guardian.git
   cd mqtt-tls-iot-guardian
   ```

2. **一键启动 Docker 服务**
   ```bash
   ./scripts/quick_start.sh
   ```
   或手动启动：
   ```bash
   docker compose up -d
   ```

3. **配置环境变量**
   ```bash
   cd backend
   cp .env.example .env
   # 编辑 .env 文件，配置数据库、Redis、MQTT等
   ```
   
   注意：使用 Docker 时，确保 `.env` 中的端口配置正确：
   - PostgreSQL: `DB_PORT=5434` (容器映射端口)
   - Redis: `REDIS_PORT=6381` (容器映射端口)
   - MQTT: `MQTT_BROKER_PORT=1883` (非TLS) 或 `8883` (TLS)

4. **启动后端服务**
   ```bash
   ./scripts/start_backend.sh
   ```
   脚本会自动：
   - 检查 Docker 服务状态
   - 运行数据库迁移
   - 初始化管理员账户
   - 启动 FastAPI 服务

5. **启动前端服务**（新终端）
   ```bash
   ./scripts/start_frontend.sh
   ```

6. **访问系统**
   - 前端: http://localhost:5173
   - API文档: http://localhost:8000/docs
   - 默认管理员: admin / admin123

#### 方式二：手动安装

1. **克隆仓库**
   ```bash
   git clone https://github.com/Shigure-moon/mqtt-tls-iot-guardian.git
   cd mqtt-tls-iot-guardian
   ```

2. **安装 PostgreSQL 和 Redis**
   - 安装 PostgreSQL 14+ 和 Redis 6+
   - 或使用 Docker: `docker compose up -d postgres redis`

3. **配置环境变量**
   ```bash
   cd backend
   cp .env.example .env
   # 编辑 .env 文件，配置数据库、Redis、MQTT等
   ```

4. **安装 Python 依赖**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

5. **初始化数据库**
   ```bash
   alembic upgrade head
   python scripts/init_admin.py
   ```

6. **启动后端服务**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

7. **启动前端服务**（新终端）
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

8. **启动 MQTT Broker**（如果未使用 Docker）
   ```bash
   # 使用 Mosquitto
   mosquitto -c backend/config/mqtt/mosquitto.conf
   ```

### 服务端口

- **PostgreSQL**: 5434 (Docker) 或 5432 (本地)
- **Redis**: 6381 (Docker) 或 6379 (本地)
- **MQTT**: 
  - 1883 (非TLS MQTT)
  - 8883 (TLS加密MQTT)
  - 9001 (WebSocket)
  - 9443 (TLS WebSocket)
- **后端API**: 8000
- **前端**: 5173

## 项目结构

```
mqtt-tls-iot-guardian/
├── backend/              # 后端服务
│   ├── app/             # 应用代码
│   │   ├── api/         # API路由
│   │   ├── core/        # 核心配置
│   │   ├── models/      # 数据模型
│   │   ├── schemas/     # Pydantic模式
│   │   └── services/    # 业务逻辑
│   ├── alembic/         # 数据库迁移
│   ├── config/          # 配置文件
│   ├── data/            # 数据目录（证书、固件等）
│   ├── scripts/         # 工具脚本
│   └── templates/       # 固件模板
├── frontend/             # 前端应用（Vue 3 + TypeScript）
├── device/               # 设备端代码
│   └── esp8266/         # ESP8266设备固件
├── scripts/              # 启动和工具脚本
├── docker-stack/         # Docker Swarm配置
├── data/                 # 共享数据目录
│   ├── certs/           # TLS证书
│   └── firmware/        # 固件文件
├── LLM-IDS-Agent/        # LLM驱动的入侵检测代理
├── CyberSentinal/        # 多智能体安全系统
│   ├── threat_detection/ # 威胁检测模块
│   ├── realtime_agent/   # 实时代理
│   └── integrations/     # 集成模块
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

### 5. 入侵检测与防御
- **LLM-IDS-Agent**: 基于大型语言模型的智能入侵检测
  - 混合分析模型（网络流量 + 主机日志）
  - 联动分析机制（多源异构情报交叉验证）
  - 自适应防御决策
- **CyberSentinal**: 多智能体AI安全系统
  - 实时日志分析
  - 威胁检测与评分
  - 自主缓解响应
  - ELK Stack集成（可选）

## 文档

### 系统文档（docs/）
- `ARCHITECTURE.md` - 系统架构设计
- `API_DESIGN.md` - API设计文档
- `SECURITY_DESIGN.md` - 安全设计
- `DATABASE_DESIGN.md` - 数据库设计
- `DEPLOYMENT.md` - 部署指南
- `MQTT_TLS_SETUP.md` - MQTT TLS配置指南
- `FIRMWARE_ENCRYPTION.md` - 固件加密说明
- `DEVICE_MANAGEMENT.md` - 设备管理文档

### 启动脚本（scripts/）
- `quick_start.sh` - 一键启动所有服务
- `start_backend.sh` - 启动后端服务
- `start_frontend.sh` - 启动前端服务
- `start_llm_security.sh` - 启动LLM安全服务
- 详细说明请查看 `scripts/README.md`

### 归档文档（docs-archive/）
- `test-docs/` - 测试说明文档
- `project-docs/` - 项目说明文档
- `debug-docs/` - 调试文档

## Docker 部署

项目提供了完整的 Docker Compose 配置，可以快速启动所有依赖服务：

```bash
# 启动所有服务（PostgreSQL、Redis、Mosquitto）
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f

# 停止服务
docker compose down
```

详细配置请查看 `docker-compose.yml` 文件。

## 入侵检测系统

### LLM-IDS-Agent

基于大型语言模型的智能入侵检测代理，提供：
- 混合分析：结合网络流量分析和主机日志分析
- 联动分析：多源异构情报交叉验证
- 智能决策：LLM驱动的自适应防御

启动方式：
```bash
./scripts/start_llm_security.sh
```

详细文档请查看 `LLM-IDS-Agent/README.md`

### CyberSentinal

多智能体AI系统，提供：
- 实时日志分析
- 威胁检测与评分
- 自主缓解响应
- ELK Stack集成

详细文档请查看 `CyberSentinal/README.md`

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

本项目采用 [MIT License](LICENSE) 开源许可证。

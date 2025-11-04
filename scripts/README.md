# 启动脚本说明

## 快速启动

### 方式一：一键启动（最简单）

```bash
./scripts/quick_start.sh
```

这个脚本会：
1. 启动所有Docker服务（PostgreSQL、Redis、Mosquitto）
2. 检查服务状态
3. 显示后续启动说明

### 方式二：使用启动脚本（推荐）

#### 启动后端

```bash
./scripts/start_backend.sh
```

这个脚本会：
1. 启动所有Docker服务（PostgreSQL、Redis、MQTT）
2. 检查服务状态和端口
3. 运行数据库迁移
4. 启动后端服务

#### 启动前端

```bash
./scripts/start_frontend.sh
```

这个脚本会：
1. 检查Node.js环境
2. 安装依赖（如需要）
3. 启动Vite开发服务器

### 方式三：手动启动

#### 1. 启动Docker服务

```bash
cd /home/shigure/mqtt-tls-iot-guardian
docker compose up -d
```

#### 2. 检查服务状态

```bash
docker compose ps
```

#### 3. 运行数据库迁移（首次启动）

```bash
cd backend
alembic upgrade head
```

#### 4. 启动后端服务

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

或者直接运行：

```bash
cd backend
python main.py
```

#### 5. 启动前端服务

```bash
cd frontend
npm install  # 首次运行
npm run dev
```

## 服务端口

- **PostgreSQL**: 5433 (容器内: 5432)
- **Redis**: 6380 (容器内: 6379)
- **MQTT**: 
  - 1883 (非TLS MQTT协议)
  - 8883 (TLS加密MQTT协议)
  - 9001 (WebSocket协议)
  - 9443 (TLS加密WebSocket协议)
- **后端API**: 8000
- **前端**: 5173

## 环境变量配置

确保 `backend/.env` 文件包含以下配置：

```env
# 数据库配置
# Docker容器端口映射: 5434:5432
DB_HOST=localhost
DB_PORT=5434
DB_NAME=iot_security
DB_USER=postgres
DB_PASSWORD=password

# Redis配置
# Docker容器端口映射: 6381:6379
REDIS_HOST=localhost
REDIS_PORT=6381
REDIS_DB=0

# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_CLIENT_ID=iot_backend
MQTT_USERNAME=admin
MQTT_PASSWORD=admin

# JWT配置
JWT_SECRET_KEY=your-secret-key-change-this-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**注意**: 项目默认使用非TLS模式（1883端口）。如需启用TLS加密，请：
1. 修改ESP8266设备代码：将`USE_TLS`设为`true`，端口改为`8883`
2. 确保Mosquitto配置正确加载TLS证书

## 停止服务

```bash
docker compose down
```

## 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f mosquitto
docker compose logs -f postgres
docker compose logs -f redis

# 查看实时MQTT连接
docker compose logs -f mosquitto | grep "New client"
```

## TLS证书配置

项目包含自签名CA证书用于TLS加密通信：

- **CA证书**: `data/certs/ca.crt`
- **服务器证书**: `data/certs/server.crt`
- **服务器私钥**: `data/certs/server.key`

证书已配置在Mosquitto容器中，ESP8266设备需要加载CA证书以验证服务器身份。

## 项目结构

```
mqtt-tls-iot-guardian/
├── backend/              # FastAPI后端服务
├── frontend/             # Vue3前端应用
├── device/              # ESP8266设备固件
│   └── esp8266/
├── data/                # 数据目录
│   └── certs/           # TLS证书
├── scripts/             # 启动脚本
└── docker-compose.yml   # Docker编排配置
```


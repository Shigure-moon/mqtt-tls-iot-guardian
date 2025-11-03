# 启动脚本说明

## 快速启动

### 方式一：使用启动脚本（推荐）

```bash
./scripts/start_backend.sh
```

这个脚本会：
1. 启动所有Docker服务（PostgreSQL、Redis、MQTT）
2. 检查服务状态
3. 运行数据库迁移
4. 启动后端服务

### 方式二：手动启动

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
python main.py
```

或者使用uvicorn：

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 服务端口

- **PostgreSQL**: 5433 (容器内: 5432)
- **Redis**: 6380 (容器内: 6379)
- **MQTT**: 1883 (MQTT协议), 9001 (WebSocket)
- **后端API**: 8000

## 环境变量配置

确保 `backend/.env` 文件包含以下配置：

```env
# 数据库配置
DB_HOST=localhost
DB_PORT=5433
DB_NAME=iot_security
DB_USER=postgres
DB_PASSWORD=password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6380
REDIS_DB=0

# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_CLIENT_ID=iot_backend_server
MQTT_USERNAME=
MQTT_PASSWORD=

# JWT配置
JWT_SECRET_KEY=your-secret-key-change-this-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

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
```


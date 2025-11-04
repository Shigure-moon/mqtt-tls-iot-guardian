# 端口配置说明

## 当前端口配置

为了避免与系统服务冲突，项目使用了以下端口：

### Docker服务端口映射

| 服务 | 主机端口 | 容器端口 | 说明 |
|------|---------|---------|------|
| PostgreSQL | 5434 | 5432 | 避免与系统PostgreSQL (5432)冲突 |
| Redis | 6381 | 6379 | 避免与系统Redis (6379/6380)冲突 |
| Mosquitto | 1883, 8883, 9001, 9443 | 同上 | 使用系统上的Mosquitto服务 |

### 应用服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| 后端API | 8000 | FastAPI服务 |
| 前端开发服务器 | 5173 | Vite开发服务器 |

## 环境变量配置

在 `backend/.env` 文件中，确保使用以下端口配置：

```env
# 数据库配置
DB_HOST=localhost
DB_PORT=5434          # 对应Docker映射的5434端口
DB_NAME=iot_security
DB_USER=postgres
DB_PASSWORD=password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6381        # 对应Docker映射的6381端口
REDIS_DB=0
```

## 修改端口

如果需要修改端口，请按以下步骤操作：

### 1. 修改 docker-compose.yml

```yaml
services:
  postgres:
    ports:
      - "新端口:5432"  # 例如: "5435:5432"
  
  redis:
    ports:
      - "新端口:6379"  # 例如: "6382:6379"
```

### 2. 更新后端环境变量

编辑 `backend/.env` 文件，更新对应的端口：

```env
DB_PORT=新端口          # 与docker-compose.yml中的主机端口一致
REDIS_PORT=新端口       # 与docker-compose.yml中的主机端口一致
```

### 3. 重启服务

```bash
# 停止现有服务
docker compose down

# 重新启动
docker compose up -d
```

## 检查端口占用

```bash
# 检查PostgreSQL端口
sudo lsof -i :5434

# 检查Redis端口
sudo lsof -i :6381

# 或使用ss命令
ss -tlnp | grep -E ":5434|:6381"
```

## 常见问题

### Q: docker-pr 进程是什么？

A: `docker-pr` 是Docker的代理进程（proxy process），用于在主机端口和容器端口之间转发流量。这是Docker网络栈的正常组成部分。

### Q: 为什么选择5434和6381？

A: 
- 5434: 避免与系统PostgreSQL默认端口5432冲突，且5433也可能被其他服务使用
- 6381: 避免与系统Redis默认端口6379和常用端口6380冲突

### Q: 如何避免开机时的端口冲突？

A: 使用非标准端口（如5434和6381）可以避免与系统服务冲突。如果仍有冲突，可以：
1. 检查并停止占用端口的其他服务
2. 修改为其他端口（如5435、6382等）
3. 确保旧的Docker容器已清理：`docker compose down`


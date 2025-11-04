#!/bin/bash

# IoT安全管理系统 - 快速启动脚本

# 不要因为某些检查失败而退出
set +e

echo "==================================="
echo "IoT安全管理系统 - 快速启动"
echo "==================================="

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查端口是否被占用
echo ""
echo "🔍 检查端口占用情况..."
PORT_CONFLICTS=0

# 检查PostgreSQL端口（使用5434）
if lsof -i :5434 > /dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":5434" || netstat -tlnp 2>/dev/null | grep -q ":5434"; then
    echo "⚠️  端口 5434 (PostgreSQL) 已被占用"
    PORT_CONFLICTS=$((PORT_CONFLICTS + 1))
    echo "   占用进程信息："
    (lsof -i :5434 2>/dev/null || ss -tlnp 2>/dev/null | grep ":5434" || netstat -tlnp 2>/dev/null | grep ":5434") | head -3
    echo "   解决方案："
    echo "   1. 停止占用端口的服务"
    echo "   2. 或修改 docker-compose.yml 中的端口映射"
fi

# 检查Redis端口（使用6381）
if lsof -i :6381 > /dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":6381" || netstat -tlnp 2>/dev/null | grep -q ":6381"; then
    echo "⚠️  端口 6381 (Redis) 已被占用"
    PORT_CONFLICTS=$((PORT_CONFLICTS + 1))
    echo "   占用进程信息："
    (lsof -i :6381 2>/dev/null || ss -tlnp 2>/dev/null | grep ":6381" || netstat -tlnp 2>/dev/null | grep ":6381") | head -3
    echo "   解决方案："
    echo "   1. 停止占用端口的服务"
    echo "   2. 或修改 docker-compose.yml 中的端口映射"
fi

if [ $PORT_CONFLICTS -gt 0 ]; then
    echo ""
    echo "❌ 检测到端口冲突！"
    echo ""
    
    # 检查是否已有Docker容器（包括已停止的）
    EXISTING_POSTGRES=$(docker ps -a --filter "name=iot_postgres" --format "{{.Names}}" 2>/dev/null)
    EXISTING_REDIS=$(docker ps -a --filter "name=iot_redis" --format "{{.Names}}" 2>/dev/null)
    
    if [ -n "$EXISTING_POSTGRES" ] || [ -n "$EXISTING_REDIS" ]; then
        echo "检测到已有Docker容器，清理并重新启动..."
        # 停止并删除容器
        docker compose stop postgres redis 2>/dev/null || true
        docker compose rm -f postgres redis 2>/dev/null || true
        # 也尝试直接删除容器
        docker rm -f iot_postgres iot_redis 2>/dev/null || true
        sleep 3
    else
        echo "尝试停止占用端口的进程..."
        # 尝试停止PostgreSQL端口
        if lsof -i :5434 > /dev/null 2>&1; then
            PIDS=$(lsof -ti :5434 2>/dev/null)
            if [ -n "$PIDS" ]; then
                for PID in $PIDS; do
                    echo "   停止占用5434端口的进程 (PID: $PID)..."
                    kill $PID 2>/dev/null || sudo kill $PID 2>/dev/null
                done
                sleep 2
            fi
        fi
        # 尝试停止Redis端口
        if lsof -i :6381 > /dev/null 2>&1; then
            PIDS=$(lsof -ti :6381 2>/dev/null)
            if [ -n "$PIDS" ]; then
                for PID in $PIDS; do
                    echo "   停止占用6381端口的进程 (PID: $PID)..."
                    kill $PID 2>/dev/null || sudo kill $PID 2>/dev/null
                done
                sleep 2
            fi
        fi
    fi
    
    # 再次检查端口
    echo ""
    echo "🔍 再次检查端口占用情况..."
    REMAINING_CONFLICTS=0
    if lsof -i :5434 > /dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":5434" || netstat -tlnp 2>/dev/null | grep -q ":5434"; then
        echo "⚠️  端口 5434 仍然被占用"
        REMAINING_CONFLICTS=$((REMAINING_CONFLICTS + 1))
    fi
    if lsof -i :6381 > /dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":6381" || netstat -tlnp 2>/dev/null | grep -q ":6381"; then
        echo "⚠️  端口 6381 仍然被占用"
        REMAINING_CONFLICTS=$((REMAINING_CONFLICTS + 1))
    fi
    
    if [ $REMAINING_CONFLICTS -gt 0 ]; then
        echo ""
        echo "❌ 端口冲突仍未解决！"
        echo ""
        echo "请手动处理："
        echo "  1. 查看占用端口的进程："
        echo "     sudo lsof -i :5434"
        echo "     sudo lsof -i :6381"
        echo ""
        echo "  2. 停止占用端口的服务，或"
        echo ""
        echo "  3. 修改 docker-compose.yml 使用其他端口："
        echo "     - 将 5434:5432 改为其他端口（如 5435:5432）"
        echo "     - 将 6381:6379 改为其他端口（如 6382:6379）"
        echo ""
        echo "  4. 同时更新后端配置中的数据库连接信息"
        echo ""
        exit 1
    else
        echo "✅ 端口冲突已解决"
    fi
fi

# 检查本地Mosquitto是否运行
echo ""
echo "🔍 检查本地Mosquitto服务..."
if pgrep -x "mosquitto" > /dev/null; then
    echo "✅ 本地Mosquitto服务正在运行"
    MOSQUITTO_RUNNING=true
else
    echo "⚠️  本地Mosquitto服务未运行"
    echo "   请先启动Mosquitto: sudo systemctl start mosquitto"
    echo "   或手动启动: mosquitto -c /etc/mosquitto/mosquitto.conf"
    MOSQUITTO_RUNNING=false
fi

# 启动Docker服务（排除Mosquitto，因为使用系统上的Mosquitto）
echo ""
echo "📦 启动Docker服务（PostgreSQL、Redis）..."
# 只启动postgres和redis服务，排除mosquitto
# 如果compose文件中有mosquitto服务，它会被忽略
docker compose up -d postgres redis 2>&1 | grep -v "mosquitto" || true

# 等待服务就绪
echo ""
echo "⏳ 等待服务就绪..."
sleep 5

# 检查服务状态
echo ""
echo "📊 Docker服务状态检查："
echo "==================================="
docker compose ps
echo "==================================="

# 检查Mosquitto状态
echo ""
if [ "$MOSQUITTO_RUNNING" = true ]; then
    echo "📊 本地Mosquitto状态："
    echo "==================================="
    if command -v mosquitto_sub > /dev/null 2>&1; then
        # 尝试测试Mosquitto连接
        timeout 2 mosquitto_sub -t '$SYS/#' -C 1 > /dev/null 2>&1 && echo "✅ Mosquitto连接正常" || echo "⚠️  Mosquitto连接测试失败"
    fi
    # 显示Mosquitto端口监听状态
    if command -v lsof > /dev/null 2>&1; then
        echo "   端口监听状态："
        (sudo lsof -i :1883 -i :8883 2>/dev/null | grep -E "LISTEN|mosquitto") || \
        (lsof -i :1883 -i :8883 2>/dev/null | grep -E "LISTEN|mosquitto") || \
        echo "   未检测到监听端口（需要sudo权限查看）"
    elif command -v ss > /dev/null 2>&1; then
        echo "   端口监听状态："
        ss -tlnp | grep -E ":1883|:8883" || echo "   未检测到监听端口"
    elif command -v netstat > /dev/null 2>&1; then
        echo "   端口监听状态："
        netstat -tlnp 2>/dev/null | grep -E ":1883|:8883" || echo "   未检测到监听端口"
    fi
    echo "==================================="
else
    echo "⚠️  本地Mosquitto未运行，请手动启动"
fi

echo ""
if [ "$MOSQUITTO_RUNNING" = true ]; then
echo "✅ 所有服务已启动！"
else
    echo "⚠️  Docker服务已启动，但Mosquitto未运行"
fi
echo ""
echo "🚀 启动说明："
echo ""
echo "   1. 启动后端服务："
echo "      ./scripts/start_backend.sh"
echo ""
echo "   2. 启动前端服务（新终端）："
echo "      ./scripts/start_frontend.sh"
echo ""
echo "   3. 访问应用："
echo "      前端: http://localhost:5173"
echo "      后端API: http://localhost:8000"
echo "      API文档: http://localhost:8000/docs"
echo ""
echo "   4. ESP8266设备配置："
echo "      - WiFi: 配置SSID和密码"
echo "      - MQTT: localhost:8883 (TLS) 或 localhost:1883 (非TLS)"
echo "      - 注意: 使用系统上的Mosquitto服务"
echo ""
echo "   5. 管理服务："
echo "      - 停止Docker服务: docker compose down"
echo "      - 启动Mosquitto: sudo systemctl start mosquitto"
echo "      - 停止Mosquitto: sudo systemctl stop mosquitto"
echo "      - 查看Mosquitto状态: sudo systemctl status mosquitto"
echo "      - 查看Mosquitto日志: sudo journalctl -u mosquitto -f"
echo ""




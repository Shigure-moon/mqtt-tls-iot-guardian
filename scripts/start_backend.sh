#!/bin/bash

# IoT安全管理系统 - 后端启动脚本

# 不使用 set -e，因为某些非关键步骤失败不应该阻止服务启动

echo "==================================="
echo "启动IoT安全管理系统后端服务"
echo "==================================="

# 获取项目根目录（绝对路径）
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 启动Docker服务（数据库、Redis，排除MQTT，使用系统上的Mosquitto）
echo ""
echo "📦 启动Docker服务（PostgreSQL、Redis）..."
# 只启动postgres和redis服务，排除mosquitto
docker compose up -d postgres redis

echo ""
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo ""
echo "📊 服务状态："
docker compose ps

# 检查数据库连接
echo ""
echo "🔍 检查数据库连接..."
if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL 已就绪"
else
    echo "❌ PostgreSQL 未就绪"
fi

# 检查Redis连接
echo ""
echo "🔍 检查Redis连接..."
if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis 已就绪"
else
    echo "❌ Redis 未就绪"
fi

# 检查本地Mosquitto服务（系统服务，非容器）
echo ""
echo "🔍 检查本地Mosquitto服务..."
if systemctl is-active --quiet mosquitto 2>/dev/null || pgrep -x mosquitto > /dev/null; then
    echo "✅ 本地Mosquitto服务正在运行"
    # 尝试连接测试非TLS端口
    if timeout 3 bash -c 'exec 3<>/dev/tcp/127.0.0.1/1883' 2>/dev/null; then
        exec 3>&-
        exec 3<&-
        echo "✅ Mosquitto 非TLS端口 1883 可连接"
    else
        echo "⚠️  Mosquitto 运行中但端口1883未响应"
    fi
    # 检查TLS端口
    if timeout 3 bash -c 'exec 3<>/dev/tcp/127.0.0.1/8883' 2>/dev/null; then
        exec 3>&-
        exec 3<&-
        echo "✅ Mosquitto TLS端口 8883 可连接"
    else
        echo "⚠️  Mosquitto 运行中但TLS端口8883未响应"
        echo "   请检查Mosquitto TLS配置和证书"
    fi
else
    echo "⚠️  本地Mosquitto服务未运行"
    echo "   启动服务: sudo systemctl start mosquitto"
    echo "   查看状态: sudo systemctl status mosquitto"
    echo "   查看日志: sudo journalctl -u mosquitto -f"
fi

# 获取backend目录（绝对路径）
BACKEND_DIR="$PROJECT_ROOT/backend"

# 切换到后端目录
cd "$BACKEND_DIR"

# 检查环境变量文件
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  未找到 .env 文件"
    echo "请确保已创建 backend/.env 文件并配置必要的环境变量"
    exit 1
fi

# 检查Python依赖
echo ""
echo "🔍 检查Python依赖..."
if ! python -c "import fastapi" 2>/dev/null; then
    echo "⚠️  缺少依赖，正在安装..."
    cd "$BACKEND_DIR"
    pip install -r requirements.txt
fi

# 运行数据库迁移
echo ""
echo "🗄️  运行数据库迁移..."
if command -v alembic &> /dev/null; then
    # 在backend目录下运行alembic，确保路径正确
    (cd "$BACKEND_DIR" && alembic upgrade head) || echo "⚠️  数据库迁移失败或已是最新版本"
else
    echo "⚠️  Alembic未安装，跳过数据库迁移"
fi

# 启动后端服务
echo ""
echo "🚀 启动后端服务..."
echo "   服务将在 http://localhost:8000 运行"
echo "   API文档可在 http://localhost:8000/docs 访问"
echo ""
echo "   MQTT监听主题："
echo "   - devices/+/status"
echo "   - devices/+/data"
echo "   - devices/+/sensor"
echo "   - devices/+/heartbeat"
echo ""
echo "   按 Ctrl+C 停止服务"
echo ""

cd "$BACKEND_DIR"
uvicorn main:app --reload --host 0.0.0.0 --port 8000


#!/bin/bash

# IoT安全管理系统 - 快速启动脚本

set -e

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

# 启动Docker服务
echo ""
echo "📦 启动Docker服务（PostgreSQL、Redis、Mosquitto）..."
docker compose up -d

# 等待服务就绪
echo ""
echo "⏳ 等待服务就绪..."
sleep 5

# 检查服务状态
echo ""
echo "📊 服务状态检查："
echo "==================================="
docker compose ps
echo "==================================="

echo ""
echo "✅ 所有服务已启动！"
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
echo "      - MQTT: 192.168.1.8:8883 (TLS)"
echo "      - 或: 192.168.1.8:1883 (非TLS)"
echo ""
echo "   5. 停止服务："
echo "      docker compose down"
echo ""


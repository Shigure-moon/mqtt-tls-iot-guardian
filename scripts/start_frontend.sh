#!/bin/bash

# IoT安全管理系统 - 前端启动脚本

echo "==================================="
echo "启动IoT安全管理系统前端服务"
echo "==================================="

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# 切换到前端目录
cd "$FRONTEND_DIR"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装，请先安装Node.js"
    exit 1
fi

# 检查依赖是否安装
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
fi

# 启动开发服务器
echo ""
echo "🚀 启动前端开发服务器..."
echo "   服务将在 http://localhost:5173 运行"
echo ""
echo "   按 Ctrl+C 停止服务"
echo ""

npm run dev


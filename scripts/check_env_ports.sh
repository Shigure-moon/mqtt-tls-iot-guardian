#!/bin/bash
# 检查并提示更新.env文件中的端口配置

ENV_FILE="backend/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️  未找到 $ENV_FILE 文件"
    echo "   请运行: cd backend && cp .env.example .env (如果存在)"
    echo "   或手动创建 .env 文件"
    exit 1
fi

echo "🔍 检查环境变量端口配置..."
echo ""

# 检查PostgreSQL端口
CURRENT_DB_PORT=$(grep "^DB_PORT=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ' || echo "")
if [ -n "$CURRENT_DB_PORT" ]; then
    if [ "$CURRENT_DB_PORT" != "5434" ]; then
        echo "⚠️  DB_PORT 当前为 $CURRENT_DB_PORT，建议改为 5434"
        echo "   以匹配 docker-compose.yml 中的端口映射 (5434:5432)"
    else
        echo "✅ DB_PORT 配置正确: $CURRENT_DB_PORT"
    fi
else
    echo "⚠️  未找到 DB_PORT 配置"
fi

# 检查Redis端口
CURRENT_REDIS_PORT=$(grep "^REDIS_PORT=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ' || echo "")
if [ -n "$CURRENT_REDIS_PORT" ]; then
    if [ "$CURRENT_REDIS_PORT" != "6381" ]; then
        echo "⚠️  REDIS_PORT 当前为 $CURRENT_REDIS_PORT，建议改为 6381"
        echo "   以匹配 docker-compose.yml 中的端口映射 (6381:6379)"
    else
        echo "✅ REDIS_PORT 配置正确: $CURRENT_REDIS_PORT"
    fi
else
    echo "⚠️  未找到 REDIS_PORT 配置"
fi

echo ""
echo "📝 如果需要更新，请编辑 $ENV_FILE 文件："
echo ""
echo "   DB_PORT=5434"
echo "   REDIS_PORT=6381"
echo ""


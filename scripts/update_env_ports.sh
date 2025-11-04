#!/bin/bash
# 更新后端.env文件中的端口配置

ENV_FILE="backend/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 未找到 $ENV_FILE 文件"
    exit 1
fi

echo "🔧 更新后端环境变量端口配置..."

# 更新PostgreSQL端口
if grep -q "^DB_PORT=5433" "$ENV_FILE"; then
    sed -i 's/^DB_PORT=5433$/DB_PORT=5434/' "$ENV_FILE"
    echo "✅ 已更新 DB_PORT: 5433 → 5434"
elif grep -q "^DB_PORT=5434" "$ENV_FILE"; then
    echo "✅ DB_PORT 已是正确值: 5434"
else
    echo "⚠️  未找到 DB_PORT 配置，请手动添加: DB_PORT=5434"
fi

# 更新Redis端口
if grep -q "^REDIS_PORT=6380" "$ENV_FILE"; then
    sed -i 's/^REDIS_PORT=6380$/REDIS_PORT=6381/' "$ENV_FILE"
    echo "✅ 已更新 REDIS_PORT: 6380 → 6381"
elif grep -q "^REDIS_PORT=6381" "$ENV_FILE"; then
    echo "✅ REDIS_PORT 已是正确值: 6381"
else
    echo "⚠️  未找到 REDIS_PORT 配置，请手动添加: REDIS_PORT=6381"
fi

echo ""
echo "📝 当前配置："
grep -E "^DB_PORT|^REDIS_PORT" "$ENV_FILE" || echo "未找到端口配置"
echo ""
echo "⚠️  注意：如果后端服务正在运行，请重启后端服务使配置生效"
echo "   重启命令: 停止后端服务后重新运行 ./scripts/start_backend.sh"


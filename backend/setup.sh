#!/bin/bash

# 创建 Conda 环境
echo "正在创建 Conda 环境..."
conda env create -f environment.yml

# 激活环境
echo "正在激活环境..."
conda activate iot-security

# 创建必要的目录
echo "正在创建项目目录..."
mkdir -p logs
mkdir -p data
mkdir -p certs

# 检查环境变量
if [ ! -f .env ]; then
    echo "创建环境变量文件..."
    cat > .env << EOF
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=iot_security
DB_USER=postgres
DB_PASSWORD=password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_CLIENT_ID=backend-service
MQTT_USERNAME=admin
MQTT_PASSWORD=password

# JWT配置
JWT_SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 服务配置
API_PORT=8000
DEBUG=True
EOF
fi

echo "环境设置完成！"
echo "使用 'conda activate iot-security' 激活环境"
echo "使用 'python main.py' 启动服务"
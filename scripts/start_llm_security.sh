#!/bin/bash

# LLM安全服务启动脚本
# 用于启动LLM-IDS-Agent和CyberSentinal

echo "==================================="
echo "启动LLM安全检测服务"
echo "==================================="

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 检查并激活conda环境
if command -v conda &> /dev/null; then
    eval "$(conda shell.bash hook)"
    if conda env list | grep -q "cyber_sentinal"; then
        echo "📦 激活conda环境: cyber_sentinal"
        conda activate cyber_sentinal 2>/dev/null || echo "⚠️  无法激活cyber_sentinal环境"
    fi
fi

# 检查LLM-IDS-Agent
echo ""
echo "🔍 检查LLM-IDS-Agent..."
LLM_IDS_DIR="$PROJECT_ROOT/LLM-IDS-Agent"
if [ -d "$LLM_IDS_DIR" ]; then
    echo "✅ LLM-IDS-Agent目录存在"
    
    # 检查配置文件
    if [ -f "$LLM_IDS_DIR/.env" ] || [ -n "$DEEPSEEK_API_KEY" ]; then
        echo "✅ DeepSeek API密钥已配置"
    else
        echo "⚠️  DeepSeek API密钥未配置"
        echo "   请设置环境变量: export DEEPSEEK_API_KEY='your_key'"
        echo "   或创建文件: $LLM_IDS_DIR/.env"
    fi
    
    # 检查依赖
    if [ -f "$LLM_IDS_DIR/requirement.txt" ]; then
        if ! python -c "import openai, scapy" 2>/dev/null; then
            echo "📦 安装LLM-IDS-Agent依赖..."
            cd "$LLM_IDS_DIR"
            pip install -r requirement.txt
        fi
    fi
else
    echo "⚠️  LLM-IDS-Agent目录不存在"
fi

# 检查CyberSentinal
echo ""
echo "🔍 检查CyberSentinal..."
CYBER_DIR="$PROJECT_ROOT/CyberSentinal"
if [ -d "$CYBER_DIR" ]; then
    echo "✅ CyberSentinal目录存在"
    
    # 检查配置文件
    if [ -f "$CYBER_DIR/.env" ]; then
        echo "✅ CyberSentinal配置文件存在"
    else
        echo "⚠️  CyberSentinal配置文件不存在"
        echo "   请创建: $CYBER_DIR/.env"
    fi
    
    # 检查依赖
    if [ -f "$CYBER_DIR/requirements.txt" ]; then
        if ! python -c "import groq, elasticsearch" 2>/dev/null; then
            echo "📦 安装CyberSentinal依赖..."
            cd "$CYBER_DIR"
            pip install -r requirements.txt
        fi
    fi
    
    # 检查Elasticsearch
    echo ""
    echo "🔍 检查Elasticsearch服务..."
    if docker ps | grep -q elasticsearch; then
        echo "✅ Elasticsearch容器正在运行"
    else
        echo "⚠️  Elasticsearch容器未运行"
        echo "   启动ELK Stack: cd $CYBER_DIR/elk && docker-compose up -d"
    fi
else
    echo "⚠️  CyberSentinal目录不存在"
fi

# 启动选项
echo ""
echo "==================================="
echo "启动选项"
echo "==================================="
echo ""
echo "1. 启动LLM-IDS-Agent（需要sudo权限）"
echo "   cd $LLM_IDS_DIR"
echo "   sudo python agent_hybrid_analyst.py"
echo ""
echo "2. 启动CyberSentinal"
echo "   cd $CYBER_DIR"
echo "   python realtime_agent/agent.py"
echo ""
echo "3. 同时启动两个服务（在不同终端）"
echo "   终端1: cd $LLM_IDS_DIR && sudo python agent_hybrid_analyst.py"
echo "   终端2: cd $CYBER_DIR && python realtime_agent/agent.py"
echo ""
echo "==================================="
echo "提示："
echo "- LLM-IDS-Agent需要sudo权限进行网络流量捕获"
echo "- 确保已配置相应的API密钥（DeepSeek/Groq）"
echo "- 确保MQTT Broker日志已启用（用于CyberSentinal）"
echo "==================================="


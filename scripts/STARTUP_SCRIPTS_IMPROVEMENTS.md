# 启动脚本改进说明

## 📋 改进概述

针对LLM安全集成和conda环境使用，对启动脚本进行了以下改进。

---

## 🔧 start_backend.sh 改进

### ✅ 新增功能

1. **Conda环境自动检测和激活**
   - 自动检测conda是否安装
   - 优先激活 `cyber_sentinal` 环境
   - 如果不存在，尝试激活 `iot-security` 环境
   - 如果已在conda环境中，显示当前环境名称

2. **改进的数据库迁移**
   - 优先使用 `python -m alembic`（更可靠，不依赖PATH）
   - 如果不可用，回退到 `alembic` 命令
   - 提供更清晰的错误提示

3. **日志目录检查**
   - 检查 `/var/log/iot-guardian` 目录是否存在
   - 检查目录写入权限
   - 如果无法创建系统日志目录，自动使用本地 `logs` 目录

4. **LLM集成配置检查**
   - 检查 `LLM_IDS_AGENT_ENABLED` 配置
   - 检查 DeepSeek API密钥配置
   - 检查 `CYBERSENTINAL_ENABLED` 配置
   - 检查 CyberSentinal 配置文件

5. **增强的启动信息**
   - 添加健康检查端点提示
   - 添加威胁响应API端点提示
   - 更清晰的服务信息展示

### 📝 改进的代码片段

```bash
# Conda环境检测和激活
if command -v conda &> /dev/null; then
    eval "$(conda shell.bash hook)"
    if [ -z "$CONDA_DEFAULT_ENV" ]; then
        if conda env list | grep -q "cyber_sentinal"; then
            conda activate cyber_sentinal
        fi
    fi
fi

# 改进的数据库迁移
if python -c "import alembic" 2>/dev/null; then
    python -m alembic upgrade head
elif command -v alembic &> /dev/null; then
    alembic upgrade head
fi
```

---

## 🆕 新增脚本：start_llm_security.sh

### 功能说明

专门用于启动LLM安全检测服务的辅助脚本，提供：

1. **环境检查**
   - 检查LLM-IDS-Agent目录和配置
   - 检查CyberSentinal目录和配置
   - 检查Elasticsearch服务状态

2. **依赖检查**
   - 检查并安装LLM-IDS-Agent依赖
   - 检查并安装CyberSentinal依赖

3. **启动指导**
   - 提供清晰的启动命令
   - 说明权限要求（sudo）
   - 提供多终端启动建议

### 使用方法

```bash
./scripts/start_llm_security.sh
```

---

## 📊 改进对比

### 改进前的问题

1. ❌ 不检查conda环境，可能导致依赖问题
2. ❌ 直接调用 `alembic` 命令，可能找不到
3. ❌ 不检查日志目录权限
4. ❌ 不检查LLM集成配置
5. ❌ 缺少威胁响应API提示

### 改进后的优势

1. ✅ 自动检测和激活conda环境
2. ✅ 使用 `python -m alembic` 更可靠
3. ✅ 自动处理日志目录权限问题
4. ✅ 检查LLM集成配置状态
5. ✅ 提供完整的API端点信息

---

## 🚀 使用建议

### 标准启动流程

1. **启动后端服务**
   ```bash
   ./scripts/start_backend.sh
   ```
   脚本会自动：
   - 启动Docker服务（PostgreSQL、Redis）
   - 检查并激活conda环境
   - 运行数据库迁移
   - 检查LLM集成配置
   - 启动FastAPI服务

2. **启动前端服务**（新终端）
   ```bash
   ./scripts/start_frontend.sh
   ```

3. **启动LLM安全服务**（可选，新终端）
   ```bash
   ./scripts/start_llm_security.sh
   # 然后按照提示启动LLM-IDS-Agent和CyberSentinal
   ```

### Conda环境使用

如果使用conda环境（如 `cyber_sentinal`），脚本会自动检测和激活。也可以手动激活：

```bash
conda activate cyber_sentinal
./scripts/start_backend.sh
```

---

## ⚠️ 注意事项

1. **数据库迁移**
   - 脚本现在使用 `python -m alembic`，更可靠
   - 如果迁移失败，会显示警告但不会阻止服务启动

2. **日志目录**
   - 如果无法创建 `/var/log/iot-guardian`，会自动使用 `backend/logs`
   - 建议手动创建并设置权限：
     ```bash
     sudo mkdir -p /var/log/iot-guardian
     sudo chown $USER:$USER /var/log/iot-guardian
     ```

3. **LLM集成**
   - LLM集成检查是可选的，不会阻止服务启动
   - 如果未启用，会显示提示信息

4. **Conda环境**
   - 脚本会尝试自动激活，但如果失败会继续使用当前环境
   - 建议手动激活conda环境后再运行脚本

---

## 🔍 故障排查

### 问题1：alembic命令找不到

**解决方案**：脚本已改进，优先使用 `python -m alembic`

### 问题2：conda环境未激活

**解决方案**：
```bash
# 手动激活
conda activate cyber_sentinal
# 然后运行脚本
./scripts/start_backend.sh
```

### 问题3：日志目录权限问题

**解决方案**：
```bash
sudo mkdir -p /var/log/iot-guardian
sudo chown $USER:$USER /var/log/iot-guardian
```

### 问题4：数据库连接失败

**解决方案**：
1. 检查PostgreSQL容器是否运行：`docker ps | grep postgres`
2. 检查端口配置：`.env` 文件中的 `DB_PORT=5434`
3. 检查容器端口映射：`docker port iot_postgres`

---

## 📝 后续改进建议

1. **健康检查端点**
   - 添加 `/api/v1/health` 端点实现
   - 检查数据库、Redis、MQTT连接状态

2. **服务管理**
   - 创建systemd服务文件
   - 支持后台运行和自动重启

3. **监控集成**
   - 添加Prometheus指标
   - 集成Grafana仪表板

---

**更新日期**: 2024年11月12日  
**版本**: v2.0


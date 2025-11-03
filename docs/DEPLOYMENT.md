# 部署文档

## 一、环境要求

### 1.1 服务器要求
```yaml
操作系统:
  - RockyLinux 10.x
  - 最小配置: 4核8G
  - 推荐配置: 8核16G
  - 存储: 100GB+ SSD

网络要求:
  - 公网IP
  - 80/443端口开放
  - 1883/8883端口(MQTT)开放
  
软件要求:
  - Docker 24.x+
  - Docker Compose 2.x+
  - Nginx 1.24+
```

### 1.2 域名与证书
```yaml
域名要求:
  - api.example.com (API服务)
  - mqtt.example.com (MQTT服务)
  - console.example.com (管理控制台)

证书要求:
  - Let's Encrypt 通配符证书
  - 自签CA证书(设备认证)
```

## 二、基础环境配置

### 2.1 系统优化
```bash
# 系统参数优化
cat > /etc/sysctl.d/99-sysctl.conf << EOF
# 网络优化
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 1

# 文件句柄
fs.file-max = 1000000
fs.inotify.max_user_watches = 524288

# 内存配置
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
EOF

sysctl -p /etc/sysctl.d/99-sysctl.conf

# 系统限制
cat > /etc/security/limits.d/20-nproc.conf << EOF
*         soft    nproc     unlimited
*         hard    nproc     unlimited
*         soft    nofile    1000000
*         hard    nofile    1000000
root      soft    nproc     unlimited
root      hard    nproc     unlimited
root      soft    nofile    1000000
root      hard    nofile    1000000
EOF
```

### 2.2 Docker安装
```bash
# 添加Docker仓库
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker
systemctl enable --now docker

# 创建Docker网络
docker network create iot-network
```

### 2.3 Nginx安装
```bash
# 安装Nginx
dnf install -y nginx

# 配置Nginx
cat > /etc/nginx/conf.d/iot-security.conf << EOF
# API服务
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    location / {
        proxy_pass http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

# 前端控制台
server {
    listen 443 ssl http2;
    server_name console.example.com;
    
    root /usr/share/nginx/html;
    index index.html;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# 启动Nginx
systemctl enable --now nginx
```

## 三、Docker Compose配置

### 3.1 基础目录结构
```bash
mkdir -p /opt/iot-security/{config,data,certs,logs}
```

### 3.2 Docker Compose文件
```yaml
version: '3.8'

services:
  # PostgreSQL数据库
  postgres:
    image: postgres:14-alpine
    container_name: iot-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: iot_security
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./config/postgres:/docker-entrypoint-initdb.d
    networks:
      - iot-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d iot_security"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis缓存
  redis:
    image: redis:7-alpine
    container_name: iot-redis
    restart: unless-stopped
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - ./config/redis/redis.conf:/usr/local/etc/redis/redis.conf
      - ./data/redis:/data
    networks:
      - iot-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MQTT Broker
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: iot-mosquitto
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "8883:8883"
    volumes:
      - ./config/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - ./config/mosquitto/passwd:/mosquitto/config/passwd
      - ./config/mosquitto/acl:/mosquitto/config/acl
      - ./certs/mqtt:/mosquitto/certs
      - ./data/mosquitto:/mosquitto/data
      - ./logs/mosquitto:/mosquitto/log
    networks:
      - iot-network
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_sub -t '$$SYS/#' -C 1 | grep -v Error || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  # 后端API服务
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    container_name: iot-backend
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/iot_security
      - REDIS_URL=redis://redis:6379/0
      - MQTT_BROKER_URL=mqtt://mosquitto:1883
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - ./certs:/app/certs
      - ./logs/backend:/app/logs
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      mosquitto:
        condition: service_healthy
    networks:
      - iot-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 前端服务
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: iot-frontend
    restart: unless-stopped
    volumes:
      - ./dist:/usr/share/nginx/html
    networks:
      - iot-network

networks:
  iot-network:
    external: true
```

## 四、部署步骤

### 4.1 准备工作
```bash
# 克隆代码
git clone https://github.com/your-repo/iot-security.git
cd iot-security

# 创建环境变量文件
cat > .env << EOF
POSTGRES_USER=iot_admin
POSTGRES_PASSWORD=secure_password
JWT_SECRET=your_jwt_secret
EOF

# 生成证书
./scripts/generate-certs.sh
```

### 4.2 配置文件准备
```bash
# Mosquitto配置
cat > config/mosquitto/mosquitto.conf << EOF
listener 1883
protocol mqtt

listener 8883
protocol mqtt
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate true
use_identity_as_username true

allow_anonymous false
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl

connection_messages true
log_dest file /mosquitto/log/mosquitto.log
log_type all
EOF

# Redis配置
cat > config/redis/redis.conf << EOF
bind 0.0.0.0
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ./
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
replica-priority 100
maxmemory 2gb
maxmemory-policy allkeys-lru
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
EOF
```

### 4.3 部署服务
```bash
# 构建并启动服务
docker compose up -d --build

# 检查服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 4.4 初始化数据
```bash
# 创建数据库表
docker compose exec backend python manage.py migrate

# 创建管理员用户
docker compose exec backend python manage.py createsuperuser

# 导入初始数据
docker compose exec backend python manage.py loaddata initial_data.json
```

## 五、监控和维护

### 5.1 监控配置
```yaml
# Prometheus配置
scrape_configs:
  - job_name: 'iot-backend'
    static_configs:
      - targets: ['backend:8000']
  - job_name: 'mqtt'
    static_configs:
      - targets: ['mosquitto:9001']

# Grafana仪表板
- name: IOT Dashboard
  panels:
    - Device Status
    - MQTT Connections
    - System Metrics
    - Security Events
```

### 5.2 日志管理
```bash
# 日志轮转配置
cat > /etc/logrotate.d/iot-security << EOF
/opt/iot-security/logs/*/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        docker compose restart
    endscript
}
EOF
```

### 5.3 备份策略
```bash
# 创建备份脚本
cat > scripts/backup.sh << EOF
#!/bin/bash
BACKUP_DIR="/opt/backups/iot-security"
DATE=\$(date +%Y%m%d)

# 数据库备份
docker compose exec -T postgres pg_dump -U \$POSTGRES_USER iot_security > \
    "\$BACKUP_DIR/db_\${DATE}.sql"

# 配置文件备份
tar czf "\$BACKUP_DIR/config_\${DATE}.tar.gz" /opt/iot-security/config

# 证书备份
tar czf "\$BACKUP_DIR/certs_\${DATE}.tar.gz" /opt/iot-security/certs

# 保留30天备份
find \$BACKUP_DIR -name "*.sql" -mtime +30 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x scripts/backup.sh

# 添加到crontab
echo "0 2 * * * /opt/iot-security/scripts/backup.sh" >> /var/spool/cron/root
```

## 六、故障处理

### 6.1 常见问题处理
```yaml
数据库连接失败:
  - 检查PostgreSQL容器状态
  - 验证数据库凭证
  - 检查网络连接

MQTT连接失败:
  - 检查证书配置
  - 验证ACL规则
  - 检查防火墙设置

服务无响应:
  - 检查容器资源使用
  - 查看服务日志
  - 重启相关服务
```

### 6.2 恢复流程
```bash
# 服务恢复
docker compose down
docker compose up -d

# 数据恢复
# 1. 停止服务
docker compose down

# 2. 恢复数据
gunzip < backup_xxx.sql.gz | docker compose exec -T postgres psql -U $POSTGRES_USER iot_security

# 3. 重启服务
docker compose up -d
```

## 七、安全加固

### 7.1 系统加固
```bash
# 禁用不必要的服务
systemctl disable --now postfix

# 配置防火墙
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=1883/tcp
firewall-cmd --permanent --add-port=8883/tcp
firewall-cmd --reload

# 设置SELinux
semanage port -a -t http_port_t -p tcp 8883
```

### 7.2 Docker安全配置
```yaml
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "userns-remap": "default",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
```

### 7.3 证书管理
```bash
# 自动更新Let's Encrypt证书
cat > /etc/cron.d/certbot << EOF
0 0 1 * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# 证书权限设置
chmod 600 /opt/iot-security/certs/*
chown -R root:root /opt/iot-security/certs
```
# Docker Swarm 容灾技术规划文档

## 目录

1. [概述](#概述)
2. [架构设计](#架构设计)
3. [服务编排](#服务编排)
4. [数据持久化](#数据持久化)
5. [高可用配置](#高可用配置)
6. [容灾策略](#容灾策略)
7. [部署方案](#部署方案)
8. [监控与告警](#监控与告警)
9. [备份与恢复](#备份与恢复)
10. [迁移指南](#迁移指南)

## 概述

### 目标

- **高可用性**：确保服务在节点故障时自动切换
- **负载均衡**：自动分发请求到多个实例
- **数据安全**：确保数据持久化和备份
- **快速恢复**：最小化故障恢复时间
- **零停机部署**：支持滚动更新

### 技术选型

- **编排工具**：Docker Swarm Mode
- **负载均衡**：Swarm内置负载均衡器
- **数据存储**：PostgreSQL主从复制 + Redis哨兵模式
- **监控**：Prometheus + Grafana
- **日志**：ELK Stack 或 Loki

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Swarm Cluster                  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Manager Node │  │ Manager Node │  │ Manager Node │   │
│  │   (Leader)   │  │  (Replica)   │  │  (Replica)   │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                  │                  │          │
│  ┌──────┴──────────────────┴──────────────────┴──────┐  │
│  │           Swarm Overlay Network                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Worker Node  │  │ Worker Node  │  │ Worker Node  │   │
│  │              │  │              │  │              │   │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │
│  │ │Backend   │ │  │ │Backend   │ │  │ │Backend   │ │   │
│  │ │Service   │ │  │ │Service   │ │  │ │Service   │ │   │
│  │ │(3 replicas)│ │  │ │(3 replicas)│ │  │ │(3 replicas)│ │   │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │   │
│  │              │  │              │  │              │   │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │
│  │ │Frontend  │ │  │ │Frontend  │ │  │ │Frontend  │ │   │
│  │ │Service   │ │  │ │Service   │ │  │ │Service   │ │   │
│  │ │(2 replicas)│ │  │ │(2 replicas)│ │  │ │(2 replicas)│ │   │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ PostgreSQL  │  │ PostgreSQL  │  │ PostgreSQL   │   │
│  │   (Primary)  │  │  (Replica)  │  │  (Replica)   │   │
│  │              │  │             │  │              │   │
│  │  ┌────────┐  │  │  ┌────────┐ │  │  ┌────────┐  │   │
│  │  │Volume  │  │  │  │Volume │ │  │  │Volume │  │   │
│  │  │(Local) │  │  │  │(Local)│ │  │  │(Local)│  │   │
│  │  └────────┘  │  │  └────────┘ │  │  └────────┘  │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Redis Master │  │ Redis Slave  │  │ Redis Slave  │   │
│  │              │  │              │  │              │   │
│  │  ┌────────┐  │  │  ┌────────┐ │  │  ┌────────┐  │   │
│  │  │Volume  │  │  │  │Volume │ │  │  │Volume │  │   │
│  │  └────────┘  │  │  └────────┘ │  │  └────────┘  │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │   Nginx      │  │   Nginx      │                     │
│  │ LoadBalancer │  │ LoadBalancer │                     │
│  │  (2 replicas) │  │  (2 replicas) │                     │
│  └──────────────┘  └──────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### 节点角色

#### Manager节点（管理节点）
- **数量**：3个（奇数，保证Raft一致性）
- **职责**：
  - 集群管理
  - 服务编排
  - 负载均衡
  - 健康检查
- **要求**：
  - 稳定的网络连接
  - 充足的计算资源

#### Worker节点（工作节点）
- **数量**：3-5个
- **职责**：
  - 运行应用服务
  - 数据存储
- **要求**：
  - 可根据负载动态扩展

### 网络架构

#### Overlay网络
- **服务网络**：`iot_guardian_network`
- **数据网络**：`iot_guardian_data_network`
- **管理网络**：`iot_guardian_management_network`

#### 端口映射

| 服务 | 内部端口 | 外部端口 | 说明 |
|------|---------|---------|------|
| 后端API | 8000 | 8000 | HTTP API |
| 前端 | 5173 | 5173 | 开发环境 |
| PostgreSQL | 5432 | 5434 | 主数据库 |
| Redis | 6379 | 6381 | 缓存 |
| Nginx | 80 | 80 | HTTP |
| Nginx | 443 | 443 | HTTPS |

## 服务编排

### Stack文件结构

```
docker-stack/
├── docker-stack.yml          # 主Stack文件
├── configs/
│   ├── postgres-primary.conf
│   ├── postgres-replica.conf
│   ├── redis.conf
│   └── nginx.conf
├── secrets/
│   ├── postgres_password
│   ├── redis_password
│   └── jwt_secret
└── volumes/
    ├── postgres-data/
    ├── redis-data/
    └── logs/
```

### 服务定义

#### 后端服务

```yaml
backend:
  image: iot-guardian-backend:latest
  deploy:
    replicas: 3
    update_config:
      parallelism: 1
      delay: 10s
      failure_action: rollback
    restart_policy:
      condition: on-failure
      delay: 5s
      max_attempts: 3
    placement:
      constraints:
        - node.role == worker
    resources:
      limits:
        cpus: '1'
        memory: 1G
      reservations:
        cpus: '0.5'
        memory: 512M
  networks:
    - iot_guardian_network
  environment:
    - DATABASE_URL=postgresql://user:pass@postgres:5432/iot_db
    - REDIS_URL=redis://redis:6379/0
  depends_on:
    - postgres
    - redis
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

#### 前端服务

```yaml
frontend:
  image: iot-guardian-frontend:latest
  deploy:
    replicas: 2
    update_config:
      parallelism: 1
      delay: 10s
    restart_policy:
      condition: on-failure
  networks:
    - iot_guardian_network
  depends_on:
    - backend
```

#### PostgreSQL主从复制

```yaml
postgres-primary:
  image: postgres:14-alpine
  deploy:
    replicas: 1
    placement:
      constraints:
        - node.labels.db == primary
    restart_policy:
      condition: on-failure
  networks:
    - iot_guardian_data_network
  volumes:
    - postgres-primary-data:/var/lib/postgresql/data
  environment:
    - POSTGRES_DB=iot_db
    - POSTGRES_USER=iot_user
    - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
    - POSTGRES_REPLICATION_USER=replicator
    - POSTGRES_REPLICATION_PASSWORD_FILE=/run/secrets/postgres_replication_password
  secrets:
    - postgres_password
    - postgres_replication_password
  command:
    - "postgres"
    - "-c"
    - "wal_level=replica"
    - "-c"
    - "max_wal_senders=3"
    - "-c"
    - "max_replication_slots=3"

postgres-replica:
  image: postgres:14-alpine
  deploy:
    replicas: 2
    placement:
      constraints:
        - node.labels.db == replica
    restart_policy:
      condition: on-failure
  networks:
    - iot_guardian_data_network
  volumes:
    - postgres-replica-data:/var/lib/postgresql/data
  environment:
    - PGUSER=postgres
    - POSTGRES_MASTER_SERVICE=postgres-primary
  command:
    - "bash"
    - "-c"
    - |
      until pg_basebackup -h postgres-primary -D /var/lib/postgresql/data -U replicator -v -P -W; do
        echo "Waiting for primary database..."
        sleep 2s
      done
      echo "standby_mode = 'on'" >> /var/lib/postgresql/data/postgresql.conf
      echo "primary_conninfo = 'host=postgres-primary port=5432 user=replicator'" >> /var/lib/postgresql/data/postgresql.conf
      postgres
```

#### Redis哨兵模式

```yaml
redis-master:
  image: redis:7-alpine
  deploy:
    replicas: 1
    placement:
      constraints:
        - node.labels.redis == master
  networks:
    - iot_guardian_data_network
  volumes:
    - redis-master-data:/data
  command: redis-server --requirepass ${REDIS_PASSWORD}

redis-slave:
  image: redis:7-alpine
  deploy:
    replicas: 2
  networks:
    - iot_guardian_data_network
  volumes:
    - redis-slave-data:/data
  command: redis-server --slaveof redis-master 6379 --requirepass ${REDIS_PASSWORD}

redis-sentinel:
  image: redis:7-alpine
  deploy:
    replicas: 3
  networks:
    - iot_guardian_data_network
  command: redis-sentinel /etc/redis/sentinel.conf
  volumes:
    - ./configs/redis-sentinel.conf:/etc/redis/sentinel.conf
```

#### Nginx负载均衡

```yaml
nginx:
  image: nginx:alpine
  deploy:
    replicas: 2
    placement:
      constraints:
        - node.role == manager
  ports:
    - "80:80"
    - "443:443"
  networks:
    - iot_guardian_network
  configs:
    - source: nginx_config
      target: /etc/nginx/nginx.conf
  depends_on:
    - backend
    - frontend
```

## 数据持久化

### 存储策略

#### PostgreSQL存储

```yaml
volumes:
  postgres-primary-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres/primary
  
  postgres-replica-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres/replica
```

#### Redis存储

```yaml
volumes:
  redis-master-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/redis/master
  
  redis-slave-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/redis/slave
```

### 备份策略

#### 自动备份

```yaml
postgres-backup:
  image: postgres:14-alpine
  deploy:
    replicas: 1
    restart_policy:
      condition: on-failure
  networks:
    - iot_guardian_data_network
  volumes:
    - postgres-backup:/backup
  environment:
    - PGHOST=postgres-primary
    - PGDATABASE=iot_db
    - PGUSER=backup_user
    - PGPASSWORD_FILE=/run/secrets/postgres_backup_password
  command:
    - "bash"
    - "-c"
    - |
      while true; do
        pg_dump -Fc -f /backup/backup_$(date +%Y%m%d_%H%M%S).dump
        # 保留最近7天的备份
        find /backup -name "*.dump" -mtime +7 -delete
        sleep 86400
      done
  secrets:
    - postgres_backup_password
```

## 高可用配置

### 服务高可用

#### 健康检查

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

#### 自动重启

```yaml
restart_policy:
  condition: on-failure
  delay: 5s
  max_attempts: 3
  window: 120s
```

#### 滚动更新

```yaml
update_config:
  parallelism: 1
  delay: 10s
  failure_action: rollback
  monitor: 60s
  max_failure_ratio: 0.3
```

### 数据库高可用

#### PostgreSQL主从切换

```yaml
# 使用Patroni或pg_auto_failover进行自动故障转移
postgres-consul:
  image: consul:latest
  deploy:
    replicas: 3
  networks:
    - iot_guardian_management_network
  command: consul agent -server -bootstrap-expect=3
```

#### Redis故障转移

使用Redis Sentinel实现自动故障转移：

```conf
# redis-sentinel.conf
sentinel monitor mymaster redis-master 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
```

## 容灾策略

### 故障场景与应对

#### 1. 单节点故障

**场景**：单个Worker节点宕机

**应对**：
- Swarm自动将服务迁移到其他节点
- 数据服务使用副本保证可用性
- 预计恢复时间：< 30秒

#### 2. Manager节点故障

**场景**：Manager节点宕机

**应对**：
- Raft算法自动选举新Leader
- 剩余Manager节点继续管理集群
- 需要至少2个Manager节点在线
- 预计恢复时间：< 10秒

#### 3. 数据库主节点故障

**场景**：PostgreSQL主节点故障

**应对**：
- 使用Patroni或pg_auto_failover自动切换
- 从节点自动提升为主节点
- 应用自动重连新主节点
- 预计恢复时间：< 60秒

#### 4. Redis主节点故障

**场景**：Redis主节点故障

**应对**：
- Sentinel自动故障转移
- 从节点自动提升为主节点
- 客户端自动重连
- 预计恢复时间：< 30秒

#### 5. 网络分区

**场景**：集群网络分裂

**应对**：
- Swarm使用Raft算法保证一致性
- 多数派继续服务
- 少数派暂停服务等待恢复
- 自动恢复连接

### RTO/RPO目标

| 服务类型 | RTO（恢复时间目标） | RPO（恢复点目标） |
|---------|-------------------|------------------|
| 后端API | < 30秒 | 0（无数据丢失） |
| 前端 | < 30秒 | 0 |
| PostgreSQL | < 60秒 | < 5分钟 |
| Redis | < 30秒 | < 1分钟 |
| 整体系统 | < 2分钟 | < 5分钟 |

## 部署方案

### 初始化Swarm集群

```bash
# 在第一个Manager节点
docker swarm init --advertise-addr <MANAGER_IP>

# 获取加入令牌
docker swarm join-token manager
docker swarm join-token worker

# 在其他节点加入
docker swarm join --token <TOKEN> <MANAGER_IP>:2377
```

### 部署Stack

```bash
# 创建网络
docker network create --driver overlay --attachable iot_guardian_network
docker network create --driver overlay iot_guardian_data_network
docker network create --driver overlay iot_guardian_management_network

# 创建Secrets
echo "your_password" | docker secret create postgres_password -
echo "your_redis_password" | docker secret create redis_password -
echo "your_jwt_secret" | docker secret create jwt_secret -

# 部署Stack
docker stack deploy -c docker-stack.yml iot-guardian

# 查看服务状态
docker stack services iot-guardian
docker service ls
docker service ps iot-guardian_backend
```

### 滚动更新

```bash
# 更新服务
docker service update --image iot-guardian-backend:v2.0 iot-guardian_backend

# 回滚
docker service rollback iot-guardian_backend

# 查看更新进度
docker service ps iot-guardian_backend
```

## 监控与告警

### 监控指标

#### 服务级别
- 服务副本数量
- 服务健康状态
- 服务响应时间
- 服务错误率

#### 节点级别
- CPU使用率
- 内存使用率
- 磁盘使用率
- 网络流量

#### 数据库级别
- 连接池状态
- 查询性能
- 复制延迟
- 备份状态

### 监控工具

#### Prometheus + Grafana

```yaml
prometheus:
  image: prom/prometheus:latest
  deploy:
    replicas: 1
  networks:
    - iot_guardian_management_network
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana:latest
  deploy:
    replicas: 1
  networks:
    - iot_guardian_management_network
  volumes:
    - grafana-data:/var/lib/grafana
  ports:
    - "3000:3000"
```

### 告警规则

```yaml
# prometheus告警规则
groups:
  - name: iot_guardian_alerts
    rules:
      - alert: ServiceDown
        expr: up{job="backend"} == 0
        for: 1m
        annotations:
          summary: "后端服务下线"
      
      - alert: HighMemoryUsage
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
        for: 5m
        annotations:
          summary: "内存使用率过高"
      
      - alert: DatabaseConnectionPoolExhausted
        expr: db_pool_active_connections / db_pool_max_connections > 0.9
        for: 2m
        annotations:
          summary: "数据库连接池即将耗尽"
```

## 备份与恢复

### 备份策略

#### 数据库备份

```bash
# 每日全量备份
pg_dump -Fc -f backup_$(date +%Y%m%d).dump iot_db

# 持续归档（WAL）
# 在postgresql.conf中启用
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
```

#### 配置文件备份

```bash
# 备份Docker Swarm配置
docker config ls > configs_backup.txt
docker secret ls > secrets_backup.txt
```

### 恢复流程

#### 数据库恢复

```bash
# 停止服务
docker service scale iot-guardian_backend=0

# 恢复数据库
pg_restore -d iot_db backup_20240101.dump

# 重启服务
docker service scale iot-guardian_backend=3
```

## 迁移指南

### 从单机部署迁移到Swarm

#### 步骤1：准备环境

```bash
# 1. 准备3个Manager节点和3个Worker节点
# 2. 初始化Swarm集群
# 3. 配置网络和存储
```

#### 步骤2：迁移数据

```bash
# 1. 备份现有数据库
pg_dump -Fc -f backup.dump iot_db

# 2. 停止现有服务
docker-compose down

# 3. 在新的PostgreSQL集群恢复数据
pg_restore -d iot_db backup.dump
```

#### 步骤3：部署Stack

```bash
# 1. 部署新Stack
docker stack deploy -c docker-stack.yml iot-guardian

# 2. 验证服务状态
docker service ls
docker service ps iot-guardian_backend

# 3. 测试功能
curl http://localhost:8000/health
```

## 实施计划

### 阶段1：基础架构（1-2周）

1. 准备3个Manager节点和3个Worker节点
2. 初始化Docker Swarm集群
3. 配置网络和存储
4. 部署监控系统

### 阶段2：数据库高可用（1周）

1. 配置PostgreSQL主从复制
2. 部署自动故障转移
3. 测试主从切换
4. 配置备份策略

### 阶段3：应用服务高可用（1周）

1. 将后端服务迁移到Swarm
2. 配置多副本部署
3. 配置健康检查和自动重启
4. 测试故障恢复

### 阶段4：Redis高可用（3天）

1. 配置Redis哨兵模式
2. 部署Redis主从
3. 测试故障转移

### 阶段5：负载均衡（3天）

1. 部署Nginx负载均衡
2. 配置SSL证书
3. 测试负载均衡

### 阶段6：测试与优化（1周）

1. 压力测试
2. 故障演练
3. 性能优化
4. 文档完善

## 注意事项

1. **数据一致性**：确保主从复制延迟在可接受范围内
2. **网络带宽**：确保节点间有足够的网络带宽
3. **存储性能**：使用SSD存储提升数据库性能
4. **安全配置**：使用Secrets管理敏感信息
5. **监控告警**：建立完善的监控和告警机制

## 相关文档

- [Docker Swarm官方文档](https://docs.docker.com/engine/swarm/)
- [PostgreSQL高可用方案](https://www.postgresql.org/docs/current/high-availability.html)
- [Redis哨兵模式](https://redis.io/docs/management/sentinel/)


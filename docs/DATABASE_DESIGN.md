# 数据库设计文档

## 一、数据库架构

### 1.1 数据库选型
```yaml
关系型数据库:
  - 类型: PostgreSQL 14+
  - 用途: 业务数据持久化
  - 特性:
    - 主从复制
    - 数据加密
    - JSON支持
    - 分区表

缓存数据库:
  - 类型: Redis 7+
  - 用途: 会话管理、实时数据
  - 特性:
    - 集群部署
    - 持久化
    - 过期策略

时序数据库:
  - 类型: InfluxDB
  - 用途: 监控指标、设备数据
  - 特性:
    - 高性能写入
    - 数据压缩
    - 自动分区
```

## 二、PostgreSQL表设计

### 2.1 用户认证相关表

#### 2.1.1 users（用户表）
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mobile VARCHAR(20),
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    totp_secret VARCHAR(32),
    failed_attempts INT DEFAULT 0,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
```

#### 2.1.2 roles（角色表）
```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.1.3 user_roles（用户角色关联表）
```sql
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);
```

### 2.2 设备管理相关表

#### 2.2.1 devices（设备表）
```sql
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'inactive',
    attributes JSONB,
    last_online_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT devices_status_check CHECK (status IN ('active', 'inactive', 'disabled', 'maintenance'))
);

CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_type ON devices(type);
CREATE INDEX idx_devices_status ON devices(status);
```

#### 2.2.2 device_certificates（设备证书表）
```sql
CREATE TABLE device_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    certificate TEXT NOT NULL,
    private_key TEXT,
    certificate_type VARCHAR(20) NOT NULL,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoke_reason VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT certificates_type_check CHECK (certificate_type IN ('sign', 'encrypt'))
);

CREATE INDEX idx_certificates_device ON device_certificates(device_id);
CREATE INDEX idx_certificates_serial ON device_certificates(serial_number);
```

### 2.3 安全审计相关表

#### 2.3.1 audit_logs（审计日志表）
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    actor_id UUID,
    actor_type VARCHAR(20),
    target_id UUID,
    target_type VARCHAR(20),
    action VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_logs_status_check CHECK (status IN ('success', 'failure', 'error'))
);

CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_actor_id ON audit_logs(actor_id);
```

#### 2.3.2 security_events（安全事件表）
```sql
CREATE TABLE security_events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    source_ip INET,
    device_id UUID REFERENCES devices(id),
    description TEXT,
    raw_data JSONB,
    handled BOOLEAN DEFAULT false,
    handler_id UUID REFERENCES users(id),
    handled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT security_events_severity_check CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);

CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_created_at ON security_events(created_at);
```

### 2.4 消息管理相关表

#### 2.4.1 mqtt_messages（MQTT消息记录表）
```sql
CREATE TABLE mqtt_messages (
    id BIGSERIAL PRIMARY KEY,
    message_id VARCHAR(100) NOT NULL,
    device_id UUID REFERENCES devices(id),
    topic VARCHAR(255) NOT NULL,
    qos SMALLINT NOT NULL,
    payload JSONB,
    published_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mqtt_messages_qos_check CHECK (qos IN (0, 1, 2))
);

CREATE INDEX idx_mqtt_messages_device ON mqtt_messages(device_id);
CREATE INDEX idx_mqtt_messages_topic ON mqtt_messages(topic);
CREATE INDEX idx_mqtt_messages_published_at ON mqtt_messages(published_at);
```

## 三、Redis数据结构设计

### 3.1 会话管理
```yaml
# 用户会话
key: "session:{userId}"
type: hash
fields:
  token: "jwt token"
  refreshToken: "refresh token"
  loginTime: "timestamp"
  deviceInfo: "user agent info"
expiry: 24h

# 设备会话
key: "device:session:{deviceId}"
type: hash
fields:
  connected: "1/0"
  lastHeartbeat: "timestamp"
  clientId: "mqtt client id"
  ipAddress: "ip address"
expiry: 1h
```

### 3.2 频率限制
```yaml
# API访问限制
key: "ratelimit:api:{ip}"
type: string
value: "counter"
expiry: 1m

# 失败尝试计数
key: "failedAttempts:{username}"
type: string
value: "counter"
expiry: 15m
```

### 3.3 实时数据缓存
```yaml
# 设备状态缓存
key: "device:status:{deviceId}"
type: hash
fields:
  status: "online/offline"
  lastUpdate: "timestamp"
  metrics: "json string"
expiry: 5m

# 设备遥测数据
key: "device:telemetry:{deviceId}"
type: list
value: "json string"
maxLength: 100
expiry: 1h
```

### 3.4 安全相关
```yaml
# 证书黑名单
key: "cert:blacklist"
type: set
members: "serial numbers"

# 设备令牌
key: "device:token:{deviceId}"
type: string
value: "token"
expiry: 1h
```

## 四、数据库安全设计

### 4.1 访问控制
```sql
-- 创建只读用户
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'xxx';
GRANT CONNECT ON DATABASE iot_security TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- 创建应用用户
CREATE ROLE app_user WITH LOGIN PASSWORD 'xxx';
GRANT CONNECT ON DATABASE iot_security TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
```

### 4.2 数据加密
```sql
-- 使用pgcrypto扩展
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 加密敏感数据
UPDATE users SET 
    email = pgp_sym_encrypt(email::text, current_setting('app.crypto_key'))::text
WHERE email IS NOT NULL;
```

### 4.3 审计日志
```sql
-- 创建审计触发器
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs(
        event_type,
        target_type,
        target_id,
        action,
        details
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        NEW.id,
        current_setting('app.current_user'),
        row_to_json(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 五、数据备份策略

### 5.1 PostgreSQL备份
```bash
# 每日全量备份
pg_dump -Fc iot_security > backup_$(date +%Y%m%d).dump

# 保留近30天备份
find /backup -name "backup_*.dump" -mtime +30 -delete

# WAL归档
archive_command = 'cp %p /archive/%f'
```

### 5.2 Redis备份
```yaml
# RDB配置
save:
  - 900 1    # 900秒内有1个改动
  - 300 10   # 300秒内有10个改动
  - 60 10000 # 60秒内有10000个改动

# AOF配置
appendonly: yes
appendfsync: everysec
```
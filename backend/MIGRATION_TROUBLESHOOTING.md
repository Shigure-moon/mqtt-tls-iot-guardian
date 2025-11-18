# 数据库迁移故障排查

## 当前问题

数据库连接失败，错误信息：
```
connection to server at "localhost" (127.0.0.1), port 5434 failed: Connection refused
```

## 可能的原因

1. **PostgreSQL服务未运行**
2. **端口配置错误**（尝试连接5434，但PostgreSQL默认端口是5432）
3. **数据库配置不正确**（.env文件中的配置）

## 解决步骤

### 1. 检查PostgreSQL服务状态

```bash
# 检查PostgreSQL是否运行
sudo systemctl status postgresql
# 或
sudo service postgresql status

# 如果未运行，启动服务
sudo systemctl start postgresql
# 或
sudo service postgresql start
```

### 2. 检查PostgreSQL端口

```bash
# 检查PostgreSQL监听的端口
sudo netstat -tlnp | grep postgres
# 或
sudo ss -tlnp | grep postgres
```

默认端口应该是 **5432**，不是 5434。

### 3. 检查.env文件配置

确保 `.env` 文件中的数据库配置正确：

```bash
cd backend
cat .env | grep -E "DB_|DATABASE"
```

应该包含：
```env
DB_HOST=localhost
DB_PORT=5432  # 注意：应该是5432，不是5434
DB_NAME=your_database_name
DB_USER=your_username
DB_PASSWORD=your_password
```

### 4. 测试数据库连接

```bash
# 使用psql测试连接
psql -h localhost -p 5432 -U your_username -d your_database_name

# 或使用环境变量
export PGPASSWORD=your_password
psql -h localhost -p 5432 -U your_username -d your_database_name
```

### 5. 创建数据库（如果不存在）

```bash
# 连接到PostgreSQL
psql -U postgres

# 创建数据库
CREATE DATABASE your_database_name;

# 创建用户（如果需要）
CREATE USER your_username WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE your_database_name TO your_username;
```

### 6. 更新.env文件

如果端口配置错误，编辑 `.env` 文件：

```bash
nano backend/.env
```

确保 `DB_PORT=5432`（不是5434）

### 7. 重新运行迁移

配置正确后，重新运行：

```bash
cd backend
source /home/shigure/miniconda3/bin/activate cyber_sentinal
alembic upgrade head
```

## 常见问题

### Q: 如何找到PostgreSQL的配置文件？

A: 通常在 `/etc/postgresql/<version>/main/postgresql.conf`

### Q: 如何修改PostgreSQL端口？

A: 编辑配置文件中的 `port = 5432`，然后重启服务

### Q: 忘记数据库密码怎么办？

A: 可以重置PostgreSQL用户密码：
```bash
sudo -u postgres psql
ALTER USER your_username WITH PASSWORD 'new_password';
```

---

**提示**: 如果问题仍然存在，请检查：
1. PostgreSQL服务是否正在运行
2. 防火墙是否阻止了连接
3. .env文件中的配置是否正确
4. 数据库用户是否有足够的权限


# 数据库管理功能框架设计

## 目录

1. [概述](#概述)
2. [功能需求](#功能需求)
3. [架构设计](#架构设计)
4. [API设计](#api设计)
5. [前端界面设计](#前端界面设计)
6. [安全考虑](#安全考虑)
7. [实施计划](#实施计划)

## 概述

数据库管理功能将集成到安全管理页面，为超级管理员提供数据库监控、管理和维护工具。

### 目标

- **实时监控**：数据库连接池、查询性能、资源使用
- **数据管理**：查看表结构、数据统计、执行查询
- **维护操作**：备份、恢复、优化、清理
- **安全审计**：操作日志、访问记录

### 权限要求

- **查看权限**：超级管理员
- **操作权限**：超级管理员（需要二次确认）

## 功能需求

### 1. 数据库概览

#### 1.1 连接池监控
- 当前连接数
- 最大连接数
- 活跃连接数
- 等待连接数
- 连接池使用率

#### 1.2 数据库统计
- 数据库大小
- 表数量
- 索引数量
- 总记录数
- 最近更新时间

#### 1.3 性能指标
- 查询响应时间
- 慢查询数量
- 缓存命中率
- 锁等待情况

### 2. 表管理

#### 2.1 表列表
- 显示所有表
- 表大小
- 记录数
- 最后更新时间
- 操作按钮（查看、优化、清理）

#### 2.2 表详情
- 表结构
- 索引信息
- 外键约束
- 数据统计
- 最近数据

### 3. 查询执行器

#### 3.1 SQL编辑器
- 语法高亮
- 自动补全
- 查询历史
- 结果导出

#### 3.2 查询限制
- 只读查询（SELECT）
- 结果集限制（最多1000行）
- 执行超时（30秒）
- 禁止危险操作（DROP, TRUNCATE等）

### 4. 备份与恢复

#### 4.1 备份管理
- 创建备份
- 备份列表
- 备份下载
- 备份删除

#### 4.2 恢复操作
- 选择备份文件
- 预览恢复内容
- 执行恢复（需要确认）

### 5. 维护操作

#### 5.1 数据库优化
- VACUUM操作
- ANALYZE操作
- REINDEX操作
- 表统计信息更新

#### 5.2 数据清理
- 清理过期数据
- 清理日志表
- 清理临时数据

### 6. 监控与告警

#### 6.1 实时监控
- 连接池状态
- 查询性能
- 资源使用
- 错误日志

#### 6.2 告警配置
- 连接池告警阈值
- 慢查询阈值
- 磁盘空间告警
- 告警通知设置

## 架构设计

### 后端架构

```
┌─────────────────────────────────────────────────┐
│           数据库管理API层                        │
│  ┌──────────────┐  ┌──────────────┐          │
│  │ 监控API      │  │ 管理API       │          │
│  │ - 连接池状态 │  │ - 备份/恢复   │          │
│  │ - 性能指标   │  │ - 维护操作    │          │
│  │ - 实时数据   │  │ - 查询执行    │          │
│  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│           数据库管理服务层                       │
│  ┌──────────────┐  ┌──────────────┐          │
│  │ 监控服务     │  │ 管理服务      │          │
│  │ - 连接池监控 │  │ - 备份服务    │          │
│  │ - 性能分析   │  │ - 查询服务    │          │
│  │ - 数据收集   │  │ - 维护服务    │          │
│  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│           数据库连接层                           │
│  ┌──────────────┐  ┌──────────────┐          │
│  │ 主数据库     │  │ 只读副本     │          │
│  │ - 读写操作   │  │ - 查询操作   │          │
│  │ - 管理操作   │  │ - 监控查询   │          │
│  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────┘
```

### 数据流

```
前端请求 → API层（权限验证） → 服务层（业务逻辑） → 数据库连接层 → PostgreSQL
                                                          │
                                                          ▼
                                                      监控数据收集
                                                          │
                                                          ▼
                                                      Redis缓存
```

## API设计

### 监控API

#### 获取数据库概览

```http
GET /api/v1/database/overview
Authorization: Bearer {token}

Response:
{
  "connection_pool": {
    "current": 10,
    "max": 20,
    "active": 8,
    "idle": 2,
    "usage_percent": 50
  },
  "database_stats": {
    "size": "1.2 GB",
    "table_count": 15,
    "index_count": 45,
    "total_rows": 1000000,
    "last_update": "2024-01-01T12:00:00Z"
  },
  "performance": {
    "avg_query_time": 0.05,
    "slow_queries": 5,
    "cache_hit_rate": 0.95,
    "lock_waits": 0
  }
}
```

#### 获取表列表

```http
GET /api/v1/database/tables?skip=0&limit=100
Authorization: Bearer {token}

Response:
[
  {
    "name": "devices",
    "size": "500 MB",
    "row_count": 10000,
    "index_count": 3,
    "last_update": "2024-01-01T12:00:00Z"
  },
  ...
]
```

#### 获取表详情

```http
GET /api/v1/database/tables/{table_name}
Authorization: Bearer {token}

Response:
{
  "name": "devices",
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "nullable": false,
      "default": null,
      "primary_key": true
    },
    ...
  ],
  "indexes": [
    {
      "name": "ix_devices_device_id",
      "columns": ["device_id"],
      "unique": true
    },
    ...
  ],
  "foreign_keys": [...],
  "stats": {
    "size": "500 MB",
    "row_count": 10000,
    "index_size": "50 MB"
  }
}
```

### 管理API

#### 执行SQL查询

```http
POST /api/v1/database/query
Authorization: Bearer {token}
Content-Type: application/json

{
  "sql": "SELECT * FROM devices LIMIT 10",
  "timeout": 30
}

Response:
{
  "columns": ["id", "device_id", "name", ...],
  "rows": [
    ["uuid1", "esp8266-001", "设备1", ...],
    ...
  ],
  "row_count": 10,
  "execution_time": 0.05
}
```

#### 创建备份

```http
POST /api/v1/database/backup
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "backup_20240101",
  "format": "custom",
  "compress": true
}

Response:
{
  "backup_id": "uuid",
  "name": "backup_20240101",
  "size": "1.2 GB",
  "created_at": "2024-01-01T12:00:00Z",
  "status": "completed"
}
```

#### 恢复备份

```http
POST /api/v1/database/restore
Authorization: Bearer {token}
Content-Type: application/json

{
  "backup_id": "uuid",
  "confirm": true
}

Response:
{
  "task_id": "uuid",
  "status": "running",
  "message": "恢复任务已启动"
}
```

#### 执行维护操作

```http
POST /api/v1/database/maintenance/{operation}
Authorization: Bearer {token}
Content-Type: application/json

{
  "table_name": "devices",  // 可选
  "confirm": true
}

// operations: vacuum, analyze, reindex, update_stats
```

## 前端界面设计

### 页面结构

```
安全管理页面
├── 服务器证书管理（Tab 1）
├── 模板管理（Tab 2）
└── 数据库管理（Tab 3） ← 新增
    ├── 概览面板
    │   ├── 连接池状态卡片
    │   ├── 数据库统计卡片
    │   └── 性能指标卡片
    ├── 表管理
    │   ├── 表列表
    │   └── 表详情对话框
    ├── 查询执行器
    │   ├── SQL编辑器
    │   └── 结果展示
    ├── 备份管理
    │   ├── 备份列表
    │   └── 创建备份对话框
    └── 维护操作
        ├── 优化操作
        └── 清理操作
```

### 界面组件

#### 1. 概览面板

```vue
<el-card>
  <template #header>
    <span>数据库概览</span>
    <el-button @click="refreshOverview">刷新</el-button>
  </template>
  
  <el-row :gutter="20">
    <el-col :span="8">
      <el-card>
        <h3>连接池状态</h3>
        <el-progress :percentage="connectionPoolUsage" />
        <p>当前连接: {{ currentConnections }} / {{ maxConnections }}</p>
      </el-card>
    </el-col>
    
    <el-col :span="8">
      <el-card>
        <h3>数据库统计</h3>
        <p>大小: {{ databaseSize }}</p>
        <p>表数量: {{ tableCount }}</p>
        <p>总记录数: {{ totalRows }}</p>
      </el-card>
    </el-col>
    
    <el-col :span="8">
      <el-card>
        <h3>性能指标</h3>
        <p>平均查询时间: {{ avgQueryTime }}ms</p>
        <p>慢查询: {{ slowQueries }}</p>
        <p>缓存命中率: {{ cacheHitRate }}%</p>
      </el-card>
    </el-col>
  </el-row>
</el-card>
```

#### 2. 表管理

```vue
<el-card>
  <template #header>
    <span>表管理</span>
    <el-input v-model="searchTable" placeholder="搜索表名" style="width: 200px" />
  </template>
  
  <el-table :data="tables" v-loading="loading">
    <el-table-column prop="name" label="表名" />
    <el-table-column prop="size" label="大小" />
    <el-table-column prop="row_count" label="记录数" />
    <el-table-column prop="last_update" label="最后更新" />
    <el-table-column label="操作">
      <template #default="{ row }">
        <el-button @click="viewTable(row)">查看</el-button>
        <el-button @click="optimizeTable(row)">优化</el-button>
      </template>
    </el-table-column>
  </el-table>
</el-card>
```

#### 3. SQL查询执行器

```vue
<el-card>
  <template #header>
    <span>SQL查询执行器</span>
    <el-button type="primary" @click="executeQuery">执行</el-button>
    <el-button @click="clearQuery">清空</el-button>
  </template>
  
  <el-input
    v-model="sqlQuery"
    type="textarea"
    :rows="10"
    placeholder="输入SQL查询（仅支持SELECT语句）"
  />
  
  <el-table v-if="queryResult" :data="queryResult.rows" style="margin-top: 20px">
    <el-table-column
      v-for="col in queryResult.columns"
      :key="col"
      :prop="col"
      :label="col"
    />
  </el-table>
</el-card>
```

## 安全考虑

### 1. 权限控制

- 所有API端点需要超级管理员权限
- 危险操作需要二次确认
- 操作日志记录

### 2. SQL注入防护

- 只允许SELECT查询
- 参数化查询
- SQL关键字过滤
- 结果集限制

### 3. 资源限制

- 查询超时限制（30秒）
- 结果集大小限制（1000行）
- 并发查询限制

### 4. 审计日志

- 记录所有数据库操作
- 记录操作人、时间、操作内容
- 定期归档日志

## 实施计划

### 阶段1：后端API开发（1周）

1. **数据库监控API**
   - 连接池状态查询
   - 数据库统计查询
   - 性能指标查询

2. **表管理API**
   - 表列表查询
   - 表详情查询
   - 表结构查询

### 阶段2：查询执行器（3天）

1. **SQL查询API**
   - SQL解析和验证
   - 查询执行
   - 结果格式化

2. **安全控制**
   - SQL注入防护
   - 权限验证
   - 资源限制

### 阶段3：备份恢复（3天）

1. **备份API**
   - 创建备份
   - 备份列表
   - 备份下载

2. **恢复API**
   - 恢复操作
   - 恢复状态查询

### 阶段4：前端界面（1周）

1. **概览面板**
   - 连接池监控
   - 数据库统计
   - 性能指标

2. **表管理界面**
   - 表列表
   - 表详情对话框

3. **查询执行器界面**
   - SQL编辑器
   - 结果展示

4. **备份管理界面**
   - 备份列表
   - 创建备份对话框

### 阶段5：测试与优化（3天）

1. 功能测试
2. 性能测试
3. 安全测试
4. 用户体验优化

## 技术实现

### 后端实现

#### 数据库监控服务

```python
# backend/app/services/database_monitor.py
class DatabaseMonitorService:
    async def get_connection_pool_stats(self, db: AsyncSession) -> dict:
        """获取连接池统计"""
        # 查询pg_stat_activity
        # 查询pg_settings
        pass
    
    async def get_database_stats(self, db: AsyncSession) -> dict:
        """获取数据库统计"""
        # 查询pg_database_size
        # 查询pg_stat_user_tables
        pass
    
    async def get_performance_metrics(self, db: AsyncSession) -> dict:
        """获取性能指标"""
        # 查询pg_stat_statements
        # 查询慢查询日志
        pass
```

#### 数据库管理服务

```python
# backend/app/services/database_manager.py
class DatabaseManagerService:
    async def execute_query(self, sql: str, timeout: int = 30) -> dict:
        """执行SQL查询（只读）"""
        # 验证SQL（只允许SELECT）
        # 执行查询
        # 返回结果
        pass
    
    async def get_table_list(self, db: AsyncSession) -> List[dict]:
        """获取表列表"""
        pass
    
    async def get_table_details(self, table_name: str, db: AsyncSession) -> dict:
        """获取表详情"""
        # 查询表结构
        # 查询索引信息
        # 查询统计信息
        pass
    
    async def create_backup(self, name: str, format: str = "custom") -> dict:
        """创建备份"""
        # 使用pg_dump创建备份
        pass
    
    async def restore_backup(self, backup_id: str, confirm: bool) -> dict:
        """恢复备份"""
        # 验证确认
        # 执行pg_restore
        pass
```

### 前端实现

#### 数据库管理组件

```typescript
// frontend/src/views/security/components/DatabaseManagement.vue
// 概览、表管理、查询执行器、备份管理等组件
```

## 注意事项

1. **性能影响**：监控查询不应影响正常业务
2. **数据安全**：确保备份数据安全存储
3. **操作审计**：记录所有管理操作
4. **错误处理**：完善的错误提示和恢复机制
5. **用户体验**：清晰的操作流程和反馈


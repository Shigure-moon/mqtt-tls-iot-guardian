from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, inspect
from datetime import datetime
from app.api.api_v1.auth import get_current_admin_user
from app.core.database import get_db, engine
from app.core.config import settings
from app.schemas.user import User
from pydantic import BaseModel
import logging
import os
import asyncio
from pathlib import Path

logger = logging.getLogger(__name__)

# 备份目录
BACKUP_DIR = Path("/var/backups/iot-guardian")
try:
    # 尝试创建系统备份目录
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    # 检查写入权限
    test_file = BACKUP_DIR / ".test_write"
    test_file.touch()
    test_file.unlink()
except (PermissionError, OSError):
    # 如果系统目录不可用，使用项目目录
    BACKUP_DIR = Path(__file__).parent.parent.parent.parent / "backups"
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    logger.info(f"使用项目备份目录: {BACKUP_DIR}")

router = APIRouter()

# 数据库概览响应模型
class ConnectionPoolStats(BaseModel):
    current: int
    max: int
    active: int
    idle: int
    usage_percent: float

class DatabaseStats(BaseModel):
    size: str
    table_count: int
    index_count: int
    total_rows: int
    last_update: str

class PerformanceMetrics(BaseModel):
    avg_query_time: float
    slow_queries: int
    cache_hit_rate: float
    lock_waits: int

class DatabaseOverview(BaseModel):
    connection_pool: ConnectionPoolStats
    database_stats: DatabaseStats
    performance: PerformanceMetrics

# 表信息响应模型
class TableInfo(BaseModel):
    name: str
    size: str
    row_count: int
    index_count: int
    last_update: str

class TableColumn(BaseModel):
    name: str
    type: str
    nullable: bool
    default: Optional[str]
    primary_key: bool

class TableIndex(BaseModel):
    name: str
    columns: str
    unique: bool

class TableDetail(BaseModel):
    name: str
    size: str
    row_count: int
    index_count: int
    last_update: str
    columns: List[TableColumn]
    indexes: List[TableIndex]

# SQL查询响应模型
class QueryResult(BaseModel):
    columns: List[str]
    rows: List[Dict[str, Any]]
    execution_time: float
    row_count: int

# 备份信息响应模型
class BackupInfo(BaseModel):
    id: str
    name: str
    size: str
    created_at: str
    status: str

class BackupCreateRequest(BaseModel):
    name: Optional[str] = None

class BackupRestoreRequest(BaseModel):
    confirm: bool = True

# 维护操作响应模型
class MaintenanceResult(BaseModel):
    success: bool
    message: str
    execution_time: float

# 获取数据库概览
@router.get("/overview", response_model=DatabaseOverview)
async def get_database_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> DatabaseOverview:
    """获取数据库概览信息"""
    try:
        # 获取连接池统计（使用配置值，因为asyncpg连接池的内部结构可能不同）
        pool_size = settings.DB_POOL_SIZE
        max_overflow = settings.DB_MAX_OVERFLOW
        max_connections = pool_size + max_overflow
        
        # 尝试从PostgreSQL获取实际连接数
        active_connections = 0
        try:
            conn_count_result = await db.execute(text("""
                SELECT count(*) as count
                FROM pg_stat_activity
                WHERE datname = current_database()
                AND state = 'active'
            """))
            active_connections = conn_count_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取活跃连接数: {e}")
            active_connections = 0
        
        # 估算连接池使用情况（简化处理）
        current_connections = min(active_connections, max_connections)
        idle_connections = max(0, pool_size - active_connections)
        usage_percent = (current_connections / max_connections * 100) if max_connections > 0 else 0
        
        # 获取数据库统计信息
        # 数据库大小
        db_size = "0 MB"
        try:
            size_result = await db.execute(text("""
                SELECT pg_size_pretty(pg_database_size(current_database())) as size
            """))
            db_size = size_result.scalar() or "0 MB"
        except Exception as e:
            logger.warning(f"无法获取数据库大小: {e}")
            db_size = "0 MB"
        
        # 表数量
        table_count = 0
        try:
            table_count_result = await db.execute(text("""
                SELECT COUNT(*) FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            """))
            table_count = table_count_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取表数量: {e}")
            table_count = 0
        
        # 索引数量
        index_count = 0
        try:
            index_count_result = await db.execute(text("""
                SELECT COUNT(*) FROM pg_indexes 
                WHERE schemaname = 'public'
            """))
            index_count = index_count_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取索引数量: {e}")
            index_count = 0
        
        # 总记录数（所有表）
        total_rows = 0
        try:
            total_rows_result = await db.execute(text("""
                SELECT COALESCE(SUM(n_live_tup), 0)::bigint as total_rows
                FROM pg_stat_user_tables
            """))
            total_rows = total_rows_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取总记录数: {e}")
            total_rows = 0
        
        # 最后更新时间
        last_update_str = datetime.utcnow().isoformat()
        try:
            last_update_result = await db.execute(text("""
                SELECT GREATEST(
                    COALESCE(MAX(last_autovacuum), '1970-01-01'::timestamp),
                    COALESCE(MAX(last_vacuum), '1970-01-01'::timestamp),
                    COALESCE(MAX(last_analyze), '1970-01-01'::timestamp)
                ) as last_update
                FROM pg_stat_user_tables
            """))
            last_update = last_update_result.scalar()
            if last_update:
                last_update_str = last_update.isoformat()
        except Exception as e:
            logger.warning(f"无法获取最后更新时间: {e}")
            last_update_str = datetime.utcnow().isoformat()
        
        # 获取性能指标
        # 平均查询时间（从pg_stat_statements，如果可用）
        avg_query_time = 0.0
        try:
            # 检查pg_stat_statements扩展是否可用
            ext_check = await db.execute(text("""
                SELECT EXISTS(
                    SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'
                ) as exists
            """))
            if ext_check.scalar():
                avg_query_time_result = await db.execute(text("""
                    SELECT COALESCE(AVG(mean_exec_time), 0) as avg_time
                    FROM pg_stat_statements
                """))
                avg_query_time = avg_query_time_result.scalar() or 0.0
        except Exception as e:
            logger.warning(f"无法获取平均查询时间: {e}")
            avg_query_time = 0.0
        
        # 慢查询（超过1秒的查询）
        slow_queries = 0
        try:
            ext_check = await db.execute(text("""
                SELECT EXISTS(
                    SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'
                ) as exists
            """))
            if ext_check.scalar():
                slow_queries_result = await db.execute(text("""
                    SELECT COUNT(*) FROM pg_stat_statements
                    WHERE mean_exec_time > 1000
                """))
                slow_queries = slow_queries_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取慢查询统计: {e}")
            slow_queries = 0
        
        # 缓存命中率
        cache_hit_rate = 0.0
        try:
            cache_hit_result = await db.execute(text("""
                SELECT 
                    CASE 
                        WHEN COALESCE(sum(heap_blks_hit), 0) + COALESCE(sum(heap_blks_read), 0) = 0 THEN 0
                        ELSE COALESCE(sum(heap_blks_hit), 0)::float / 
                             NULLIF(COALESCE(sum(heap_blks_hit), 0) + COALESCE(sum(heap_blks_read), 0), 0)
                    END as cache_hit_rate
                FROM pg_statio_user_tables
            """))
            cache_hit_rate = cache_hit_result.scalar() or 0.0
        except Exception as e:
            logger.warning(f"无法获取缓存命中率: {e}")
            cache_hit_rate = 0.0
        
        # 锁等待
        lock_waits = 0
        try:
            lock_waits_result = await db.execute(text("""
                SELECT COUNT(*) FROM pg_locks
                WHERE NOT granted
            """))
            lock_waits = lock_waits_result.scalar() or 0
        except Exception as e:
            logger.warning(f"无法获取锁等待统计: {e}")
            lock_waits = 0
        
        return DatabaseOverview(
            connection_pool=ConnectionPoolStats(
                current=current_connections,
                max=max_connections,
                active=active_connections,
                idle=idle_connections,
                usage_percent=round(usage_percent, 2)
            ),
            database_stats=DatabaseStats(
                size=db_size,
                table_count=table_count,
                index_count=index_count,
                total_rows=total_rows,
                last_update=last_update_str
            ),
            performance=PerformanceMetrics(
                avg_query_time=round(avg_query_time, 2),
                slow_queries=slow_queries,
                cache_hit_rate=round(cache_hit_rate, 4),
                lock_waits=lock_waits
            )
        )
    except Exception as e:
        logger.error(f"获取数据库概览失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取数据库概览失败: {str(e)}"
        )

# 获取表列表
@router.get("/tables", response_model=List[TableInfo])
async def get_tables(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> List[TableInfo]:
    """获取所有表的信息"""
    try:
        result = await db.execute(text("""
            SELECT 
                t.table_name as name,
                pg_size_pretty(pg_total_relation_size(quote_ident(t.table_schema)||'.'||quote_ident(t.table_name))) as size,
                COALESCE(s.n_tup_ins - s.n_tup_del, 0)::bigint as row_count,
                (SELECT COUNT(*) FROM pg_indexes WHERE tablename = t.table_name AND schemaname = 'public') as index_count,
                COALESCE(s.last_autovacuum, s.last_vacuum, s.last_analyze)::text as last_update
            FROM information_schema.tables t
            LEFT JOIN pg_stat_user_tables s ON s.relname = t.table_name
            WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
            ORDER BY t.table_name
        """))
        
        tables = []
        for row in result:
            tables.append(TableInfo(
                name=row.name,
                size=row.size or "0 MB",
                row_count=row.row_count or 0,
                index_count=row.index_count or 0,
                last_update=row.last_update or datetime.utcnow().isoformat()
            ))
        
        return tables
    except Exception as e:
        logger.error(f"获取表列表失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取表列表失败: {str(e)}"
        )

# 获取表详情
@router.get("/tables/{table_name}", response_model=TableDetail)
async def get_table_detail(
    table_name: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> TableDetail:
    """获取表的详细信息"""
    try:
        # 验证表名（防止SQL注入）
        if not table_name.replace('_', '').replace('.', '').isalnum():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="无效的表名"
            )
        
        # 获取表基本信息
        table_info_result = await db.execute(text(f"""
            SELECT 
                '{table_name}' as name,
                pg_size_pretty(pg_total_relation_size('public.{table_name}')) as size,
                COALESCE(s.n_tup_ins - s.n_tup_del, 0)::bigint as row_count,
                (SELECT COUNT(*) FROM pg_indexes WHERE tablename = '{table_name}' AND schemaname = 'public') as index_count,
                COALESCE(s.last_autovacuum, s.last_vacuum, s.last_analyze)::text as last_update
            FROM pg_stat_user_tables s
            WHERE s.relname = '{table_name}'
        """))
        
        table_info = table_info_result.first()
        if not table_info:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"表 '{table_name}' 不存在"
            )
        
        # 获取列信息
        columns_result = await db.execute(text(f"""
            SELECT 
                c.column_name as name,
                c.data_type || 
                CASE 
                    WHEN c.character_maximum_length IS NOT NULL THEN '(' || c.character_maximum_length || ')'
                    WHEN c.numeric_precision IS NOT NULL THEN '(' || c.numeric_precision || ',' || COALESCE(c.numeric_scale, 0) || ')'
                    ELSE ''
                END as type,
                c.is_nullable = 'YES' as nullable,
                c.column_default as default,
                CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END as primary_key
            FROM information_schema.columns c
            LEFT JOIN (
                SELECT ku.table_name, ku.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage ku
                    ON tc.constraint_name = ku.constraint_name
                WHERE tc.constraint_type = 'PRIMARY KEY'
            ) pk ON c.table_name = pk.table_name AND c.column_name = pk.column_name
            WHERE c.table_schema = 'public' AND c.table_name = '{table_name}'
            ORDER BY c.ordinal_position
        """))
        
        columns = []
        for row in columns_result:
            columns.append(TableColumn(
                name=row.name,
                type=row.type,
                nullable=row.nullable,
                default=row.default,
                primary_key=row.primary_key
            ))
        
        # 获取索引信息
        indexes_result = await db.execute(text(f"""
            SELECT 
                i.indexname as name,
                string_agg(a.attname, ', ' ORDER BY array_position(ix.indkey, a.attnum)) as columns,
                i.indexdef LIKE '%UNIQUE%' as unique
            FROM pg_indexes i
            JOIN pg_index ix ON i.indexname = (SELECT relname FROM pg_class WHERE oid = ix.indexrelid)
            JOIN pg_attribute a ON a.attrelid = ix.indrelid AND a.attnum = ANY(ix.indkey)
            WHERE i.schemaname = 'public' AND i.tablename = '{table_name}'
            GROUP BY i.indexname, i.indexdef
            ORDER BY i.indexname
        """))
        
        indexes = []
        for row in indexes_result:
            indexes.append(TableIndex(
                name=row.name,
                columns=row.columns,
                unique=row.unique
            ))
        
        return TableDetail(
            name=table_name,
            size=table_info.size or "0 MB",
            row_count=table_info.row_count or 0,
            index_count=table_info.index_count or 0,
            last_update=table_info.last_update or datetime.utcnow().isoformat(),
            columns=columns,
            indexes=indexes
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取表详情失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取表详情失败: {str(e)}"
        )

# SQL查询请求模型
class QueryRequest(BaseModel):
    query: str
    limit: int = 1000

# 执行SQL查询（仅SELECT）
@router.post("/query", response_model=QueryResult)
async def execute_query(
    request: QueryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> QueryResult:
    """执行SQL查询（仅支持SELECT）"""
    try:
        query = request.query
        limit = request.limit
        
        # 验证查询类型（仅允许SELECT）
        query_upper = query.strip().upper()
        if not query_upper.startswith('SELECT'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="仅支持SELECT查询（只读操作）"
            )
        
        # 添加LIMIT限制
        if 'LIMIT' not in query_upper:
            query = f"{query.rstrip(';')} LIMIT {limit}"
        
        start_time = datetime.utcnow()
        result = await db.execute(text(query))
        execution_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        # 获取列名
        columns = list(result.keys()) if result.keys() else []
        
        # 获取行数据
        rows = []
        for row in result:
            row_dict = {}
            for col in columns:
                value = getattr(row, col, None)
                # 处理特殊类型
                if isinstance(value, datetime):
                    value = value.isoformat()
                elif isinstance(value, (bytes, bytearray)):
                    value = value.hex()
                row_dict[col] = value
            rows.append(row_dict)
        
        return QueryResult(
            columns=columns,
            rows=rows,
            execution_time=round(execution_time, 2),
            row_count=len(rows)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"执行SQL查询失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"执行SQL查询失败: {str(e)}"
        )

# 优化表
@router.post("/tables/{table_name}/optimize", response_model=MaintenanceResult)
async def optimize_table(
    table_name: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> MaintenanceResult:
    """优化表（VACUUM ANALYZE）"""
    try:
        # 验证表名
        if not table_name.replace('_', '').replace('.', '').isalnum():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="无效的表名"
            )
        
        start_time = datetime.utcnow()
        await db.execute(text(f"VACUUM ANALYZE {table_name}"))
        await db.commit()
        execution_time = (datetime.utcnow() - start_time).total_seconds()
        
        return MaintenanceResult(
            success=True,
            message=f"表 '{table_name}' 优化完成",
            execution_time=round(execution_time, 2)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"优化表失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"优化表失败: {str(e)}"
        )

# 数据库维护操作
@router.post("/maintenance/vacuum", response_model=MaintenanceResult)
async def vacuum_database(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> MaintenanceResult:
    """执行VACUUM操作"""
    try:
        start_time = datetime.utcnow()
        await db.execute(text("VACUUM"))
        await db.commit()
        execution_time = (datetime.utcnow() - start_time).total_seconds()
        
        return MaintenanceResult(
            success=True,
            message="VACUUM操作完成",
            execution_time=round(execution_time, 2)
        )
    except Exception as e:
        logger.error(f"VACUUM操作失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"VACUUM操作失败: {str(e)}"
        )

@router.post("/maintenance/analyze", response_model=MaintenanceResult)
async def analyze_database(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> MaintenanceResult:
    """执行ANALYZE操作"""
    try:
        start_time = datetime.utcnow()
        await db.execute(text("ANALYZE"))
        await db.commit()
        execution_time = (datetime.utcnow() - start_time).total_seconds()
        
        return MaintenanceResult(
            success=True,
            message="ANALYZE操作完成",
            execution_time=round(execution_time, 2)
        )
    except Exception as e:
        logger.error(f"ANALYZE操作失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"ANALYZE操作失败: {str(e)}"
        )

@router.post("/maintenance/reindex", response_model=MaintenanceResult)
async def reindex_database(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> MaintenanceResult:
    """执行REINDEX操作"""
    try:
        start_time = datetime.utcnow()
        await db.execute(text("REINDEX DATABASE current_database()"))
        await db.commit()
        execution_time = (datetime.utcnow() - start_time).total_seconds()
        
        return MaintenanceResult(
            success=True,
            message="REINDEX操作完成",
            execution_time=round(execution_time, 2)
        )
    except Exception as e:
        logger.error(f"REINDEX操作失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"REINDEX操作失败: {str(e)}"
        )

# 数据库备份管理
@router.get("/backups", response_model=List[BackupInfo])
async def list_backups(
    current_user: User = Depends(get_current_admin_user)
) -> List[BackupInfo]:
    """获取备份列表"""
    try:
        backups = []
        if BACKUP_DIR.exists():
            for backup_file in BACKUP_DIR.glob("*.sql"):
                stat = backup_file.stat()
                size_mb = stat.st_size / (1024 * 1024)
                size_str = f"{size_mb:.2f} MB" if size_mb < 1024 else f"{size_mb / 1024:.2f} GB"
                
                backups.append(BackupInfo(
                    id=backup_file.stem,
                    name=backup_file.name,
                    size=size_str,
                    created_at=datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    status="completed"
                ))
        
        # 按创建时间倒序排列
        backups.sort(key=lambda x: x.created_at, reverse=True)
        return backups
    except Exception as e:
        logger.error(f"获取备份列表失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取备份列表失败: {str(e)}"
        )

@router.post("/backups", response_model=BackupInfo)
async def create_backup(
    request: BackupCreateRequest,
    current_user: User = Depends(get_current_admin_user)
) -> BackupInfo:
    """创建数据库备份"""
    try:
        # 生成备份文件名
        if request.name:
            # 验证备份名称（只允许字母、数字、下划线和连字符）
            if not all(c.isalnum() or c in ['_', '-'] for c in request.name):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="备份名称只能包含字母、数字、下划线和连字符"
                )
            backup_name = f"{request.name}.sql"
        else:
            backup_name = f"backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.sql"
        
        backup_path = BACKUP_DIR / backup_name
        
        # 检查文件是否已存在
        if backup_path.exists():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"备份文件 '{backup_name}' 已存在"
            )
        
        # 检查是否在Docker容器中（通过检查DB_HOST和端口）
        # 也检查Docker容器是否存在
        use_docker = False
        if settings.DB_HOST in ["localhost", "127.0.0.1"] and settings.DB_PORT == 5434:
            # 检查Docker容器是否存在
            try:
                check_docker = await asyncio.create_subprocess_exec(
                    "docker", "ps", "--format", "{{.Names}}",
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                stdout, _ = await check_docker.communicate()
                if check_docker.returncode == 0:
                    container_names = stdout.decode().strip().split('\n')
                    if "iot_postgres" in container_names:
                        use_docker = True
            except Exception as e:
                logger.warning(f"检查Docker容器失败: {e}，将尝试直接连接")
        
        if use_docker:
            # 使用Docker exec在容器内执行pg_dump
            docker_cmd = [
                "docker", "exec", "iot_postgres",
                "pg_dump",
                "-U", settings.DB_USER,
                "-d", settings.DB_NAME,
                "-F", "p"  # 纯文本格式
            ]
            
            # 设置环境变量（密码）
            env = os.environ.copy()
            env["PGPASSWORD"] = settings.DB_PASSWORD
            
            # 执行备份（异步执行）
            process = await asyncio.create_subprocess_exec(
                *docker_cmd,
                env=env,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "未知错误"
                logger.error(f"备份失败: {error_msg}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"备份失败: {error_msg}"
                )
            
            # 将输出写入文件
            with open(backup_path, 'wb') as f:
                f.write(stdout)
        else:
            # 直接使用pg_dump（假设已安装postgresql-client）
            pg_dump_cmd = [
                "pg_dump",
                "-h", settings.DB_HOST,
                "-p", str(settings.DB_PORT),
                "-U", settings.DB_USER,
                "-d", settings.DB_NAME,
                "-F", "p",  # 纯文本格式
                "-f", str(backup_path)
            ]
            
            # 设置环境变量（密码）
            env = os.environ.copy()
            env["PGPASSWORD"] = settings.DB_PASSWORD
            
            # 执行备份（异步执行）
            process = await asyncio.create_subprocess_exec(
                *pg_dump_cmd,
                env=env,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "未知错误"
                logger.error(f"备份失败: {error_msg}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"备份失败: {error_msg}"
                )
        
        # 获取备份文件信息
        stat = backup_path.stat()
        size_mb = stat.st_size / (1024 * 1024)
        size_str = f"{size_mb:.2f} MB" if size_mb < 1024 else f"{size_mb / 1024:.2f} GB"
        
        return BackupInfo(
            id=backup_path.stem,
            name=backup_name,
            size=size_str,
            created_at=datetime.fromtimestamp(stat.st_mtime).isoformat(),
            status="completed"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"创建备份失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"创建备份失败: {str(e)}"
        )

@router.get("/backups/{backup_id}/download")
async def download_backup(
    backup_id: str,
    current_user: User = Depends(get_current_admin_user)
):
    """下载备份文件"""
    try:
        # 查找备份文件
        backup_path = None
        for backup_file in BACKUP_DIR.glob("*.sql"):
            if backup_file.stem == backup_id:
                backup_path = backup_file
                break
        
        if not backup_path or not backup_path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="备份文件不存在"
            )
        
        return FileResponse(
            path=str(backup_path),
            filename=backup_path.name,
            media_type="application/sql"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"下载备份失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"下载备份失败: {str(e)}"
        )

@router.post("/backups/{backup_id}/restore", response_model=MaintenanceResult)
async def restore_backup(
    backup_id: str,
    request: BackupRestoreRequest,
    current_user: User = Depends(get_current_admin_user)
) -> MaintenanceResult:
    """恢复数据库备份"""
    try:
        if not request.confirm:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="必须确认才能恢复备份"
            )
        
        # 查找备份文件
        backup_path = None
        for backup_file in BACKUP_DIR.glob("*.sql"):
            if backup_file.stem == backup_id:
                backup_path = backup_file
                break
        
        if not backup_path or not backup_path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="备份文件不存在"
            )
        
        # 检查是否在Docker容器中
        use_docker = False
        if settings.DB_HOST in ["localhost", "127.0.0.1"] and settings.DB_PORT == 5434:
            # 检查Docker容器是否存在
            try:
                check_docker = await asyncio.create_subprocess_exec(
                    "docker", "ps", "--format", "{{.Names}}",
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                stdout, _ = await check_docker.communicate()
                if check_docker.returncode == 0:
                    container_names = stdout.decode().strip().split('\n')
                    if "iot_postgres" in container_names:
                        use_docker = True
            except Exception as e:
                logger.warning(f"检查Docker容器失败: {e}，将尝试直接连接")
        
        start_time = datetime.utcnow()
        
        if use_docker:
            # 使用Docker exec在容器内执行psql
            # 先将备份文件复制到容器中，或直接通过stdin传递
            with open(backup_path, 'rb') as f:
                backup_content = f.read()
            
            docker_cmd = [
                "docker", "exec", "-i", "iot_postgres",
                "psql",
                "-U", settings.DB_USER,
                "-d", settings.DB_NAME
            ]
            
            # 设置环境变量（密码）
            env = os.environ.copy()
            env["PGPASSWORD"] = settings.DB_PASSWORD
            
            # 执行恢复（通过stdin传递SQL内容）
            process = await asyncio.create_subprocess_exec(
                *docker_cmd,
                env=env,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate(input=backup_content)
            
            execution_time = (datetime.utcnow() - start_time).total_seconds()
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "未知错误"
                logger.error(f"恢复备份失败: {error_msg}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"恢复备份失败: {error_msg}"
                )
        else:
            # 直接使用psql
            psql_cmd = [
                "psql",
                "-h", settings.DB_HOST,
                "-p", str(settings.DB_PORT),
                "-U", settings.DB_USER,
                "-d", settings.DB_NAME,
                "-f", str(backup_path)
            ]
            
            # 设置环境变量（密码）
            env = os.environ.copy()
            env["PGPASSWORD"] = settings.DB_PASSWORD
            
            # 执行恢复（异步执行）
            process = await asyncio.create_subprocess_exec(
                *psql_cmd,
                env=env,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            execution_time = (datetime.utcnow() - start_time).total_seconds()
            
            if process.returncode != 0:
                error_msg = stderr.decode() if stderr else "未知错误"
                logger.error(f"恢复备份失败: {error_msg}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"恢复备份失败: {error_msg}"
                )
        
        return MaintenanceResult(
            success=True,
            message=f"备份 '{backup_path.name}' 恢复完成",
            execution_time=round(execution_time, 2)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"恢复备份失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"恢复备份失败: {str(e)}"
        )

@router.delete("/backups/{backup_id}")
async def delete_backup(
    backup_id: str,
    current_user: User = Depends(get_current_admin_user)
):
    """删除备份文件"""
    try:
        # 查找备份文件
        backup_path = None
        for backup_file in BACKUP_DIR.glob("*.sql"):
            if backup_file.stem == backup_id:
                backup_path = backup_file
                break
        
        if not backup_path or not backup_path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="备份文件不存在"
            )
        
        # 删除文件
        backup_path.unlink()
        
        return {"success": True, "message": f"备份 '{backup_path.name}' 已删除"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"删除备份失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"删除备份失败: {str(e)}"
        )


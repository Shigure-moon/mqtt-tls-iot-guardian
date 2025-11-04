#!/usr/bin/env python3
"""
设置admin用户为超级管理员
"""
import asyncio
import sys
from pathlib import Path

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.core.config import settings
from app.models.user import User

async def set_admin_super_admin():
    """设置admin用户为超级管理员"""
    # 创建异步引擎
    engine = create_async_engine(
        settings.DATABASE_URL_ASYNC,
        echo=False,
    )
    
    # 创建会话工厂
    async_session = sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    
    async with async_session() as session:
        try:
            # 查找admin用户
            result = await session.execute(
                select(User).filter(User.username == 'admin')
            )
            user = result.scalar_one_or_none()
            
            if not user:
                print("❌ 未找到admin用户")
                return
            
            # 设置为超级管理员
            user.is_admin = True
            session.add(user)
            await session.commit()
            
            print(f"✅ 已将用户 '{user.username}' 设置为超级管理员")
        except Exception as e:
            await session.rollback()
            print(f"❌ 设置失败: {e}")
            raise
        finally:
            await engine.dispose()

if __name__ == "__main__":
    asyncio.run(set_admin_super_admin())


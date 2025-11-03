import sys
from pathlib import Path

# 添加backend目录到Python路径，以便能够导入app模块
backend_dir = Path(__file__).parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_admin(db: Session):
    try:
        # 检查管理员是否已存在
        admin = db.query(User).filter(User.username == "admin").first()
        if admin:
            logger.info("管理员用户已存在")
            return
        
        # 创建管理员用户
        admin = User(
            username="admin",
            email="admin@example.com",
            hashed_password=get_password_hash("admin123"),
            is_active=True,
            is_admin=True
        )
        db.add(admin)
        db.commit()
        logger.info("管理员用户创建成功！")
        logger.info("用户名: admin")
        logger.info("密码: admin123")
    except Exception as e:
        db.rollback()
        logger.error(f"创建管理员用户失败: {str(e)}")
        raise

def main():
    """主函数"""
    try:
        db = SessionLocal()
        try:
            init_admin(db)
        finally:
            db.close()
    except Exception as e:
        logger.error(f"程序执行失败: {str(e)}")
        logger.error("请确保:")
        logger.error("1. 数据库服务已启动")
        logger.error("2. 环境变量已正确配置")
        logger.error("3. 数据库表已创建（运行 alembic upgrade head）")
        sys.exit(1)

if __name__ == "__main__":
    main()
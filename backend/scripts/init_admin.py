from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.security import get_password_hash
from app.models.user import User
import uuid

# 数据库连接配置
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:password@localhost:5433/iot_security"

# 创建数据库引擎
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_admin():
    db = SessionLocal()
    try:
        # 检查管理员是否已存在
        admin = db.query(User).filter(User.username == "admin").first()
        if admin:
            print("管理员用户已存在")
            return
        
        # 创建管理员用户
        admin = User(
            id=uuid.uuid4(),
            username="admin",
            email="admin@example.com",
            hashed_password=get_password_hash("Admin123!@#"),
            full_name="System Administrator",
            is_active=True,
            is_admin=True
        )
        
        db.add(admin)
        db.commit()
        print("管理员用户创建成功")
        print("用户名: admin")
        print("密码: Admin123!@#")
        
    except Exception as e:
        print(f"创建管理员用户失败: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_admin()
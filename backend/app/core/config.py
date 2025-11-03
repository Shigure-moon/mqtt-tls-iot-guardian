from typing import List
from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl, validator

class Settings(BaseSettings):
    # 项目信息
    PROJECT_NAME: str = "IoT Security Platform"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "基于MQTT与TLS的物联网设备安全管理与入侵检测系统"
    
    # API配置
    API_V1_STR: str = "/api/v1"
    API_PORT: int = 8000
    DEBUG: bool = True
    
    # CORS配置
    CORS_ORIGINS: List[AnyHttpUrl] = []
    
    @validator("CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v: str | List[str]) -> List[AnyHttpUrl]:
        if isinstance(v, str) and not v.startswith("["):
            return [v]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # 数据库配置
    DB_HOST: str
    DB_PORT: int
    DB_NAME: str
    DB_USER: str
    DB_PASSWORD: str
    
    # 数据库连接池配置
    DB_POOL_SIZE: int = 10  # 连接池大小
    DB_MAX_OVERFLOW: int = 20  # 最大溢出连接数
    DB_POOL_TIMEOUT: int = 30  # 连接池超时时间（秒）
    DB_POOL_RECYCLE: int = 3600  # 连接回收时间（秒），1小时
    DB_POOL_PRE_PING: bool = True  # 连接前验证连接是否有效
    DB_ECHO: bool = False  # 是否回显SQL语句
    
    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
    
    @property
    def DATABASE_URL_ASYNC(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
    
    # Redis配置
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_DB: int
    
    @property
    def REDIS_URL(self) -> str:
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
    
    # MQTT配置
    MQTT_BROKER_HOST: str
    MQTT_BROKER_PORT: int
    MQTT_CLIENT_ID: str
    MQTT_USERNAME: str
    MQTT_PASSWORD: str
    
    # JWT配置
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
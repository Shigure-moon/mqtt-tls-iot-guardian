import asyncio
from paho.mqtt import client as mqtt_client
from app.core.config import settings
import redis.asyncio as redis
import logging

# 初始化日志
logger = logging.getLogger(__name__)

# MQTT客户端
mqtt = None

# Redis客户端
redis_client = None

async def startup_handler():
    """应用启动时的处理函数"""
    await init_redis()
    await init_mqtt()

async def shutdown_handler():
    """应用关闭时的处理函数"""
    if redis_client:
        await redis_client.close()
    
    if mqtt:
        mqtt.disconnect()

async def init_redis():
    """初始化Redis连接"""
    global redis_client
    redis_client = redis.from_url(settings.REDIS_URL)
    try:
        await redis_client.ping()
        logger.info("Redis connection established")
    except redis.ConnectionError as e:
        logger.error(f"Redis connection failed: {e}")
        raise

async def init_mqtt():
    """初始化MQTT客户端"""
    global mqtt
    
    def on_connect(client, userdata, flags, rc, properties=None):
        if rc == 0:
            logger.info("Connected to MQTT broker")
            # 订阅必要的主题
            client.subscribe("devices/+/status")
            client.subscribe("devices/+/data")
        else:
            logger.error(f"Failed to connect to MQTT broker with code: {rc}")
    
    def on_message(client, userdata, msg):
        logger.debug(f"Received message on topic: {msg.topic}")
        # 处理消息的逻辑
        asyncio.create_task(handle_mqtt_message(msg))
    
    mqtt = mqtt_client.Client(client_id=settings.MQTT_CLIENT_ID, protocol=mqtt_client.MQTTv5)
    mqtt.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
    mqtt.on_connect = on_connect
    mqtt.on_message = on_message
    
    try:
        mqtt.connect(settings.MQTT_BROKER_HOST, settings.MQTT_BROKER_PORT)
        mqtt.loop_start()
        logger.info("MQTT client initialized")
    except Exception as e:
        logger.error(f"MQTT connection failed: {e}")
        raise

async def handle_mqtt_message(message):
    """处理MQTT消息"""
    try:
        topic = message.topic
        payload = message.payload.decode()
        logger.debug(f"Processing message from topic {topic}: {payload}")
        # TODO: 实现消息处理逻辑
    except Exception as e:
        logger.error(f"Error processing MQTT message: {e}")
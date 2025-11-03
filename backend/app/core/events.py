import asyncio
import json
from paho.mqtt import client as mqtt_client
from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.services.device import DeviceService
import redis.asyncio as redis
import logging
from queue import Queue
import threading

# 初始化日志
logger = logging.getLogger(__name__)

# MQTT客户端
mqtt = None

# Redis客户端
redis_client = None

# MQTT消息队列
mqtt_message_queue = Queue()

async def startup_handler():
    """应用启动时的处理函数"""
    # Redis和MQTT连接失败不应该阻止应用启动
    # 这样可以先测试API功能，MQTT可以稍后配置
    try:
        await init_redis()
    except Exception as e:
        logger.warning(f"Redis connection failed, continuing without Redis: {e}")
    
    try:
        await init_mqtt()
        # 启动MQTT消息处理线程
        start_mqtt_message_processor()
    except Exception as e:
        logger.warning(f"MQTT connection failed, continuing without MQTT: {e}")
        logger.warning("MQTT features will be unavailable until broker is configured")

async def shutdown_handler():
    """应用关闭时的处理函数"""
    if redis_client:
        try:
            await redis_client.close()
            logger.info("Redis connection closed")
        except Exception as e:
            logger.warning(f"Error closing Redis connection: {e}")
    
    if mqtt:
        try:
            mqtt.loop_stop()
            mqtt.disconnect()
            logger.info("MQTT client disconnected")
        except Exception as e:
            logger.warning(f"Error disconnecting MQTT client: {e}")

async def init_redis():
    """初始化Redis连接"""
    global redis_client
    try:
        redis_client = redis.from_url(settings.REDIS_URL)
        await redis_client.ping()
        logger.info("Redis connection established")
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        redis_client = None
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
            client.subscribe("devices/+/sensor")
            client.subscribe("devices/+/heartbeat")
        else:
            logger.error(f"Failed to connect to MQTT broker with code: {rc}")
    
    def on_message(client, userdata, msg):
        logger.info(f"Received message on topic: {msg.topic}")
        # 将消息添加到队列，由专门的处理线程处理
        mqtt_message_queue.put(msg)
    
    mqtt = mqtt_client.Client(client_id=settings.MQTT_CLIENT_ID, protocol=mqtt_client.MQTTv5)
    mqtt.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
    mqtt.on_connect = on_connect
    mqtt.on_message = on_message
    
    try:
        mqtt.connect(settings.MQTT_BROKER_HOST, settings.MQTT_BROKER_PORT)
        mqtt.loop_start()
        logger.info("MQTT client initialized and connected")
    except Exception as e:
        logger.error(f"MQTT connection failed: {e}")
        mqtt = None
        raise

def mqtt_message_processor():
    """MQTT消息处理线程"""
    import queue
    while True:
        try:
            message = mqtt_message_queue.get(timeout=1)
            # 在新事件循环中处理
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(handle_mqtt_message(message))
            loop.close()
        except queue.Empty:
            # 超时是正常的，继续轮询
            pass
        except Exception as e:
            logger.error(f"Error in message processor: {e}")
    
def start_mqtt_message_processor():
    """启动MQTT消息处理线程"""
    thread = threading.Thread(target=mqtt_message_processor, daemon=True)
    thread.start()
    logger.info("MQTT message processor thread started")

async def handle_mqtt_message(message):
    """处理MQTT消息"""
    try:
        topic = message.topic
        payload = message.payload.decode()
        logger.debug(f"Processing message from topic {topic}: {payload}")
        
        # 解析topic获取device_id
        topic_parts = topic.split('/')
        if len(topic_parts) >= 2 and topic_parts[0] == 'devices':
            device_id = topic_parts[1]
            message_type = topic_parts[2] if len(topic_parts) > 2 else None
            
            # 根据消息类型处理
            if message_type in ['status', 'heartbeat', 'sensor']:
                # 更新设备状态为在线
                async with AsyncSessionLocal() as db:
                    device_service = DeviceService(db)
                    device = await device_service.get_by_device_id(device_id)
                    if device:
                        await device_service.update_status(device, "online")
                        logger.info(f"Device {device_id} status updated to online")
                        
                        # 如果是传感器数据，保存到监控表
                        if message_type == 'sensor':
                            try:
                                from app.models.monitoring import DeviceMetrics
                                from datetime import datetime
                                import uuid
                                
                                # 解析JSON数据
                                sensor_data = json.loads(payload) if payload else {}
                                
                                # 提取温度、湿度等指标
                                metrics = {}
                                if 'temperature' in sensor_data:
                                    metrics['temperature'] = sensor_data['temperature']
                                if 'humidity' in sensor_data:
                                    metrics['humidity'] = sensor_data['humidity']
                                if 'air_quality' in sensor_data:
                                    metrics['air_quality'] = sensor_data['air_quality']
                                if 'battery' in sensor_data:
                                    metrics['battery'] = sensor_data['battery']
                                
                                # 保存每种指标的记录
                                for metric_name, metric_value in metrics.items():
                                    metric_record = DeviceMetrics(
                                        device_id=device.id,
                                        metric_type=metric_name,
                                        metrics={'value': metric_value},
                                        timestamp=datetime.utcnow()
                                    )
                                    db.add(metric_record)
                                
                                await db.commit()
                                logger.info(f"Saved sensor metrics for device {device_id}: {metrics}")
                            except Exception as e:
                                logger.error(f"Error saving sensor metrics: {e}")
                                await db.rollback()
                    else:
                        logger.warning(f"Device {device_id} not found in database")
    except Exception as e:
        logger.error(f"Error processing MQTT message: {e}")
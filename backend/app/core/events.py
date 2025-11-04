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

# 主事件循环引用（用于在新线程中运行异步任务）
main_event_loop = None

async def startup_handler():
    """应用启动时的处理函数"""
    global main_event_loop
    # 保存主事件循环引用，供MQTT消息处理线程使用
    main_event_loop = asyncio.get_event_loop()
    
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
        logger.info("[MQTT] MQTT client and message processor initialized successfully")
    except Exception as e:
        logger.warning(f"[MQTT] MQTT connection failed, continuing without MQTT: {e}")
        logger.warning("[MQTT] MQTT features will be unavailable until broker is configured")
        import traceback
        logger.error(f"[MQTT] MQTT initialization error traceback: {traceback.format_exc()}")

    # 启动设备状态检查任务（无论MQTT是否连接成功都启动）
    try:
        # 在后台任务中启动状态检查器
        asyncio.create_task(device_status_checker())
    except Exception as e:
        logger.warning(f"Failed to start device status checker: {e}")

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
        # MQTTv5回调函数签名：支持可变参数
        if rc == 0:
            logger.info(f"[MQTT] Connected to broker at {settings.MQTT_BROKER_HOST}:{settings.MQTT_BROKER_PORT}")
            # 订阅必要的主题
            topics = [
                ("devices/+/status", 0),
                ("devices/+/data", 0),
                ("devices/+/sensor", 0),
                ("devices/+/heartbeat", 0)
            ]
            for topic, qos in topics:
                result = client.subscribe(topic, qos)
                logger.info(f"[MQTT] Subscribed to {topic} with QoS {qos}, result: {result}")
        else:
            logger.error(f"[MQTT] Failed to connect to broker with code: {rc}")
    
    def on_message(client, userdata, msg):
        logger.info(f"[MQTT] Received message on topic: {msg.topic}, qos: {msg.qos}, payload length: {len(msg.payload)}")
        # 将消息添加到队列，由专门的处理线程处理
        try:
            mqtt_message_queue.put(msg, timeout=5)
            logger.debug(f"[MQTT] Message queued successfully: {msg.topic}")
        except Exception as e:
            logger.error(f"[MQTT] Failed to queue message: {e}")
            import traceback
            logger.error(f"[MQTT] Queue error traceback: {traceback.format_exc()}")
    
    mqtt = mqtt_client.Client(client_id=settings.MQTT_CLIENT_ID, protocol=mqtt_client.MQTTv5)
    mqtt.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
    mqtt.on_connect = on_connect
    mqtt.on_message = on_message
    
    # 如果端口是8883或18883，使用TLS连接
    use_tls = settings.MQTT_BROKER_PORT in [8883, 18883]
    if use_tls:
        import ssl
        import os
        from pathlib import Path
        
        # 获取CA证书路径
        cert_dir = Path(__file__).parent.parent.parent / "data" / "certs"
        ca_cert_path = cert_dir / "ca.crt"
        
        if ca_cert_path.exists():
            logger.info(f"[MQTT] Using TLS connection with CA certificate: {ca_cert_path}")
            mqtt.tls_set(ca_certs=str(ca_cert_path), tls_version=ssl.PROTOCOL_TLSv1_2)
            # 禁用主机名验证（因为使用IP地址连接）
            mqtt.tls_insecure_set(True)
        else:
            logger.warning(f"[MQTT] CA certificate not found at {ca_cert_path}, using insecure TLS")
            mqtt.tls_set(tls_version=ssl.PROTOCOL_TLSv1_2)
            mqtt.tls_insecure_set(True)
    
    try:
        logger.info(f"[MQTT] Attempting to connect to {settings.MQTT_BROKER_HOST}:{settings.MQTT_BROKER_PORT} (TLS: {use_tls})")
        mqtt.connect(settings.MQTT_BROKER_HOST, settings.MQTT_BROKER_PORT)
        mqtt.loop_start()
        logger.info(f"[MQTT] MQTT client loop started, waiting for connection...")
        # 等待连接建立
        import time
        for i in range(10):  # 等待最多2秒
            if mqtt.is_connected():
                logger.info(f"[MQTT] MQTT client connected successfully")
                break
            time.sleep(0.2)
        else:
            logger.warning(f"[MQTT] MQTT client connection timeout, may still be connecting...")
    except Exception as e:
        logger.error(f"[MQTT] MQTT connection failed: {e}")
        import traceback
        logger.error(f"[MQTT] Connection error traceback: {traceback.format_exc()}")
        mqtt = None
        raise

def mqtt_message_processor():
    """MQTT消息处理线程"""
    import queue
    import traceback
    while True:
        try:
            message = mqtt_message_queue.get(timeout=1)
            logger.info(f"[MQTT Processor] Got message from queue: {message.topic}")
            
            # 使用主事件循环来运行异步任务，而不是创建新的事件循环
            # 这样可以避免数据库连接池的事件循环冲突
            if main_event_loop and main_event_loop.is_running():
                # 将任务提交到主事件循环
                future = asyncio.run_coroutine_threadsafe(
                    handle_mqtt_message(message),
                    main_event_loop
                )
                # 等待任务完成（最多30秒）
                try:
                    future.result(timeout=30)
                except Exception as e:
                    logger.error(f"[MQTT Processor] Error waiting for message handling: {e}")
                    logger.error(f"[MQTT Processor] Traceback: {traceback.format_exc()}")
            else:
                logger.error("[MQTT Processor] Main event loop not available, cannot process message")
                
        except queue.Empty:
            # 超时是正常的，继续轮询
            pass
        except Exception as e:
            logger.error(f"[MQTT Processor] Error in message processor: {e}")
            logger.error(f"[MQTT Processor] Traceback: {traceback.format_exc()}")
    
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
        logger.info(f"[MQTT] Received message on topic: {topic}, payload: {payload[:200]}")  # 限制日志长度
        
        # 解析topic获取device_id
        topic_parts = topic.split('/')
        if len(topic_parts) >= 2 and topic_parts[0] == 'devices':
            device_id = topic_parts[1]
            message_type = topic_parts[2] if len(topic_parts) > 2 else None
            logger.info(f"[MQTT] Parsed device_id: {device_id}, message_type: {message_type}")
            
            # 根据消息类型处理
            if message_type in ['status', 'heartbeat', 'sensor']:
                # 更新设备状态为在线
                async with AsyncSessionLocal() as db:
                    device_service = DeviceService(db)
                    device = await device_service.get_by_device_id(device_id)
                    if device:
                        logger.info(f"[MQTT] Found device in database: {device.name} (id: {device.id})")
                        await device_service.update_status(device, "online")
                        logger.info(f"[MQTT] Device {device_id} status updated to online")
                        
                        # 如果是传感器数据，保存到监控表
                        if message_type == 'sensor':
                            try:
                                from app.models.monitoring import DeviceMetrics
                                from datetime import datetime
                                import uuid
                                
                                # 解析JSON数据
                                sensor_data = json.loads(payload) if payload else {}
                                logger.info(f"[MQTT] Parsed sensor data: {sensor_data}")
                                
                                # 提取温度、湿度等指标（支持设备发送的所有字段）
                                metrics = {}
                                # 基础传感器数据
                                if 'temperature' in sensor_data:
                                    metrics['temperature'] = sensor_data['temperature']
                                if 'humidity' in sensor_data:
                                    metrics['humidity'] = sensor_data['humidity']
                                if 'voltage' in sensor_data:
                                    metrics['voltage'] = sensor_data['voltage']
                                if 'battery' in sensor_data:
                                    metrics['battery'] = sensor_data['battery']
                                # 其他可选指标
                                if 'air_quality' in sensor_data:
                                    metrics['air_quality'] = sensor_data['air_quality']
                                # 状态信息（如果有）
                                if 'status' in sensor_data and isinstance(sensor_data['status'], dict):
                                    if 'wifi' in sensor_data['status']:
                                        metrics['wifi_status'] = sensor_data['status']['wifi']
                                    if 'mqtt' in sensor_data['status']:
                                        metrics['mqtt_status'] = sensor_data['status']['mqtt']
                                    if 'uptime' in sensor_data['status']:
                                        metrics['uptime'] = sensor_data['status']['uptime']
                                
                                # 保存每种指标的记录
                                saved_count = 0
                                for metric_name, metric_value in metrics.items():
                                    metric_record = DeviceMetrics(
                                        device_id=device.id,
                                        metric_type=metric_name,
                                        metrics={'value': metric_value},
                                        timestamp=datetime.utcnow()
                                    )
                                    db.add(metric_record)
                                    saved_count += 1
                                
                                await db.commit()
                                logger.info(f"[MQTT] Saved {saved_count} sensor metrics for device {device_id}: {metrics}")
                            except json.JSONDecodeError as e:
                                logger.error(f"[MQTT] Failed to parse JSON payload: {e}, payload: {payload}")
                                await db.rollback()
                            except Exception as e:
                                logger.error(f"[MQTT] Error saving sensor metrics: {e}", exc_info=True)
                                await db.rollback()
                        elif message_type == 'heartbeat':
                            logger.info(f"[MQTT] Heartbeat received from device {device_id}, status updated")
                    else:
                        logger.warning(f"[MQTT] Device {device_id} not found in database")
            else:
                logger.debug(f"[MQTT] Unhandled message type: {message_type}")
    except UnicodeDecodeError as e:
        logger.error(f"[MQTT] Failed to decode message payload: {e}")
    except Exception as e:
        logger.error(f"[MQTT] Error processing MQTT message: {e}", exc_info=True)

async def device_status_checker():
    """定期检查设备在线状态，将超时的设备标记为离线"""
    from datetime import datetime, timedelta, timezone
    from sqlalchemy import select
    
    # 设备离线超时时间：90秒（心跳间隔30秒 + 60秒容差）
    OFFLINE_TIMEOUT = timedelta(seconds=90)
    
    logger.info("Device status checker started")
    
    # 等待一下，确保数据库连接已建立
    await asyncio.sleep(5)
    
    while True:
        try:
            # 每30秒检查一次
            await asyncio.sleep(30)
            
            async with AsyncSessionLocal() as db:
                device_service = DeviceService(db)
                
                # 获取所有状态为online的设备
                from app.models.device import Device
                result = await db.execute(
                    select(Device).filter(Device.status == "online")
                )
                online_devices = result.scalars().all()
                
                now = datetime.now(timezone.utc)
                offline_count = 0
                
                for device in online_devices:
                    # 如果设备没有last_online_at时间，或者超过超时时间，标记为离线
                    if device.last_online_at is None:
                        await device_service.update_status(device, "offline")
                        offline_count += 1
                        logger.info(f"Device {device.device_id} marked offline (no last_online_at)")
                    else:
                        # 处理时区问题：确保last_online_at是timezone-aware的
                        last_online = device.last_online_at
                        if last_online.tzinfo is None:
                            # 如果是naive datetime，假设是UTC
                            last_online = last_online.replace(tzinfo=timezone.utc)
                        
                        time_diff = now - last_online
                        if time_diff > OFFLINE_TIMEOUT:
                            await device_service.update_status(device, "offline")
                            offline_count += 1
                            logger.info(f"Device {device.device_id} marked offline (timeout: {time_diff.total_seconds():.0f}s)")
                
                if offline_count > 0:
                    logger.info(f"Marked {offline_count} device(s) as offline")
        except Exception as e:
            logger.error(f"Error in device status checker: {e}", exc_info=True)
            # 出错后等待更长时间再重试
            await asyncio.sleep(60)
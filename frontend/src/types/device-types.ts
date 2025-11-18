/**
 * ESP8266设备类型定义
 * 根据设备返回的信息识别设备类型和版本
 */

export enum DeviceType {
  DOOR_LOCK = 'door_lock',        // 门锁
  CURTAIN = 'curtain',            // 窗帘
  SENSOR_HUB = 'sensor_hub',      // 传感器集成设备
  SWITCH = 'switch',              // 开关
  LIGHT = 'light',               // 灯光
  UNKNOWN = 'unknown'             // 未知类型
}

export interface DeviceTypeInfo {
  type: DeviceType
  version?: string
  capabilities?: string[]
  attributes?: Record<string, any>
}

/**
 * 根据设备信息识别设备类型
 * @param device 设备对象
 * @returns 设备类型信息
 */
export function identifyDeviceType(device: {
  device_id?: string
  name?: string
  type?: string
  attributes?: Record<string, any>
  description?: string
}): DeviceTypeInfo {
  // 优先从 device_id 识别（如果包含设备类型关键词）
  if (device.device_id) {
    const deviceIdLower = device.device_id.toLowerCase()
    
    if (deviceIdLower.includes('door_lock') || deviceIdLower.includes('door-lock')) {
      return {
        type: DeviceType.DOOR_LOCK,
        version: extractVersion(device.type || device.device_id, device.attributes),
        capabilities: ['lock', 'unlock', 'status'],
        attributes: device.attributes
      }
    }
    
    if (deviceIdLower.includes('curtain') || deviceIdLower.includes('窗帘')) {
      return {
        type: DeviceType.CURTAIN,
        version: extractVersion(device.type || device.device_id, device.attributes),
        capabilities: ['open', 'close', 'stop', 'position'],
        attributes: device.attributes
      }
    }
    
    if (deviceIdLower.includes('sensor') || deviceIdLower.includes('传感器')) {
      return {
        type: DeviceType.SENSOR_HUB,
        version: extractVersion(device.type || device.device_id, device.attributes),
        capabilities: ['read', 'monitor'],
        attributes: device.attributes
      }
    }
  }
  
  // 从 name 字段识别
  if (device.name) {
    const nameLower = device.name.toLowerCase()
    
    if (nameLower.includes('door') || nameLower.includes('lock') || nameLower.includes('门锁')) {
      return {
        type: DeviceType.DOOR_LOCK,
        version: extractVersion(device.type || device.name, device.attributes),
        capabilities: ['lock', 'unlock', 'status'],
        attributes: device.attributes
      }
    }
    
    if (nameLower.includes('curtain') || nameLower.includes('窗帘')) {
      return {
        type: DeviceType.CURTAIN,
        version: extractVersion(device.type || device.name, device.attributes),
        capabilities: ['open', 'close', 'stop', 'position'],
        attributes: device.attributes
      }
    }
    
    if (nameLower.includes('sensor') || nameLower.includes('传感器')) {
      return {
        type: DeviceType.SENSOR_HUB,
        version: extractVersion(device.type || device.name, device.attributes),
        capabilities: ['read', 'monitor'],
        attributes: device.attributes
      }
    }
  }
  
  // 优先从 type 字段识别
  if (device.type) {
    const typeLower = device.type.toLowerCase()
    
    // 检查是否包含关键词
    if (typeLower.includes('door') || typeLower.includes('lock') || typeLower.includes('门锁')) {
      return {
        type: DeviceType.DOOR_LOCK,
        version: extractVersion(device.type, device.attributes),
        capabilities: ['lock', 'unlock', 'status'],
        attributes: device.attributes
      }
    }
    
    if (typeLower.includes('curtain') || typeLower.includes('窗帘')) {
      return {
        type: DeviceType.CURTAIN,
        version: extractVersion(device.type, device.attributes),
        capabilities: ['open', 'close', 'stop', 'position'],
        attributes: device.attributes
      }
    }
    
    if (typeLower.includes('sensor') || typeLower.includes('传感器')) {
      return {
        type: DeviceType.SENSOR_HUB,
        version: extractVersion(device.type, device.attributes),
        capabilities: ['read', 'monitor'],
        attributes: device.attributes
      }
    }
    
    if (typeLower.includes('switch') || typeLower.includes('开关')) {
      return {
        type: DeviceType.SWITCH,
        version: extractVersion(device.type, device.attributes),
        capabilities: ['on', 'off', 'toggle'],
        attributes: device.attributes
      }
    }
    
    if (typeLower.includes('light') || typeLower.includes('灯')) {
      return {
        type: DeviceType.LIGHT,
        version: extractVersion(device.type, device.attributes),
        capabilities: ['on', 'off', 'brightness', 'color'],
        attributes: device.attributes
      }
    }
  }
  
  // 从 attributes 中识别
  if (device.attributes) {
    const attrs = device.attributes
    
    // 检查是否有门锁相关属性
    if (attrs.device_type === 'door_lock' || attrs.has_lock || attrs.lock_status !== undefined) {
      return {
        type: DeviceType.DOOR_LOCK,
        version: attrs.version || attrs.firmware_version,
        capabilities: ['lock', 'unlock', 'status'],
        attributes: attrs
      }
    }
    
    // 检查是否有窗帘相关属性
    if (attrs.device_type === 'curtain' || attrs.has_motor || attrs.position !== undefined) {
      return {
        type: DeviceType.CURTAIN,
        version: attrs.version || attrs.firmware_version,
        capabilities: ['open', 'close', 'stop', 'position'],
        attributes: attrs
      }
    }
    
    // 检查是否有传感器相关属性
    if (attrs.device_type === 'sensor_hub' || attrs.has_sensors || attrs.temperature !== undefined) {
      return {
        type: DeviceType.SENSOR_HUB,
        version: attrs.version || attrs.firmware_version,
        capabilities: ['read', 'monitor'],
        attributes: attrs
      }
    }
  }
  
  // 从描述中识别
  if (device.description) {
    const descLower = device.description.toLowerCase()
    if (descLower.includes('门锁') || descLower.includes('door lock')) {
      return {
        type: DeviceType.DOOR_LOCK,
        capabilities: ['lock', 'unlock', 'status'],
        attributes: device.attributes
      }
    }
    if (descLower.includes('窗帘') || descLower.includes('curtain')) {
      return {
        type: DeviceType.CURTAIN,
        capabilities: ['open', 'close', 'stop', 'position'],
        attributes: device.attributes
      }
    }
    if (descLower.includes('传感器') || descLower.includes('sensor')) {
      return {
        type: DeviceType.SENSOR_HUB,
        capabilities: ['read', 'monitor'],
        attributes: device.attributes
      }
    }
  }
  
  // 默认返回未知类型
  return {
    type: DeviceType.UNKNOWN,
    attributes: device.attributes
  }
}

/**
 * 从设备信息中提取版本号
 */
function extractVersion(type: string, attributes?: Record<string, any>): string | undefined {
  // 从 type 中提取版本（如 "door_lock_v2" -> "v2"）
  const versionMatch = type.match(/[vV](\d+)/)
  if (versionMatch) {
    return `v${versionMatch[1]}`
  }
  
  // 从 attributes 中获取版本
  if (attributes?.version) {
    return attributes.version
  }
  if (attributes?.firmware_version) {
    return attributes.firmware_version
  }
  
  return undefined
}

/**
 * 获取设备类型的显示名称
 */
export function getDeviceTypeName(type: DeviceType): string {
  const names: Record<DeviceType, string> = {
    [DeviceType.DOOR_LOCK]: '智能门锁',
    [DeviceType.CURTAIN]: '智能窗帘',
    [DeviceType.SENSOR_HUB]: '传感器集成设备',
    [DeviceType.SWITCH]: '智能开关',
    [DeviceType.LIGHT]: '智能灯光',
    [DeviceType.UNKNOWN]: '未知设备'
  }
  return names[type] || '未知设备'
}

/**
 * 获取设备类型的图标
 */
export function getDeviceTypeIcon(type: DeviceType): string {
  const icons: Record<DeviceType, string> = {
    [DeviceType.DOOR_LOCK]: 'Lock',
    [DeviceType.CURTAIN]: 'Menu',
    [DeviceType.SENSOR_HUB]: 'Monitor',
    [DeviceType.SWITCH]: 'Switch',
    [DeviceType.LIGHT]: 'Light',
    [DeviceType.UNKNOWN]: 'QuestionFilled'
  }
  return icons[type] || 'QuestionFilled'
}


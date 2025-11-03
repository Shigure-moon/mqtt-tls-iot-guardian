// Device related types
export interface Device {
  id: string
  name: string
  model: string
  serial_number: string
  description?: string
  status: DeviceStatus
  connection_status: ConnectionStatus
  metadata: Record<string, any>
  last_online_at?: string
  created_at: string
  updated_at: string
  owner_id: string
}

export enum DeviceStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  MAINTENANCE = 'maintenance',
  RETIRED = 'retired'
}

export enum ConnectionStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  UNKNOWN = 'unknown'
}

export interface DeviceCreate {
  name: string
  model: string
  serial_number: string
  description?: string
  metadata?: Record<string, any>
}

export interface DeviceUpdate {
  name?: string
  description?: string
  status?: DeviceStatus
  metadata?: Record<string, any>
}

export interface DeviceMonitoringData {
  device_id: string
  metrics: {
    [key: string]: number | string | boolean
  }
  timestamp: string
}

export interface DeviceAlarm {
  id: string
  device_id: string
  type: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  message: string
  timestamp: string
  resolved: boolean
  resolved_at?: string
  metadata?: Record<string, any>
}

export interface DeviceCommand {
  id: string
  device_id: string
  command: string
  parameters?: Record<string, any>
  status: 'pending' | 'sent' | 'executed' | 'failed'
  result?: Record<string, any>
  created_at: string
  executed_at?: string
}
export interface Device {
  id: string
  device_id: string
  name: string
  type: string
  description?: string
  status: 'active' | 'inactive' | 'disabled' | 'maintenance'
  attributes?: Record<string, any>
  last_online_at?: string
  created_at: string
  updated_at: string
}

export interface DeviceCreate {
  device_id: string
  name: string
  type: string
  description?: string
  attributes?: Record<string, any>
}

export interface DeviceUpdate {
  name?: string
  type?: string
  description?: string
  status?: string
  attributes?: Record<string, any>
}


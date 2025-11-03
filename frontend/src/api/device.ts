import request from '@/utils/request'
import type { Device, DeviceCreate, DeviceUpdate, DeviceCertificate, DeviceLog, DeviceMetrics } from '@/types/device'

// Device Management APIs
export const createDevice = (data: DeviceCreate) => {
  return request({
    url: '/devices',
    method: 'post',
    data
  })
}

export const getDevices = (params?: { skip?: number; limit?: number }) => {
  return request({
    url: '/devices',
    method: 'get',
    params
  })
}

export const getDevice = (id: string) => {
  return request({
    url: `/devices/${id}`,
    method: 'get'
  })
}

export const updateDevice = (id: string, data: DeviceUpdate) => {
  return request({
    url: `/devices/${id}`,
    method: 'put',
    data
  })
}

export const deleteDevice = (id: string) => {
  return request({
    url: `/devices/${id}`,
    method: 'delete'
  })
}

// Device Certificate APIs
export const createDeviceCertificate = (deviceId: string) => {
  return request({
    url: `/devices/${deviceId}/certificates`,
    method: 'post'
  })
}

export const revokeCertificate = (deviceId: string, certId: string, reason: string) => {
  return request({
    url: `/devices/${deviceId}/certificates/${certId}/revoke`,
    method: 'post',
    data: { reason }
  })
}

// Device Log APIs
export const addDeviceLog = (deviceId: string, data: DeviceLog) => {
  return request({
    url: `/devices/${deviceId}/logs`,
    method: 'post',
    data
  })
}

export const getDeviceLogs = (
  deviceId: string,
  params?: {
    start_time?: string
    end_time?: string
    log_type?: string
    limit?: number
  }
) => {
  return request({
    url: `/devices/${deviceId}/logs`,
    method: 'get',
    params
  })
}

// Device Statistics
export const getDeviceStats = (deviceId: string) => {
  return request({
    url: `/devices/${deviceId}/stats`,
    method: 'get'
  })
}
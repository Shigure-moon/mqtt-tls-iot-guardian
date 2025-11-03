import { defineStore } from 'pinia'
import type { Device } from '@/types/device'
import { getDevices } from '@/api/device'

interface DeviceState {
  devices: Device[]
  totalDevices: number
  loading: boolean
  currentDevice: Device | null
}

export const useDeviceStore = defineStore('device', {
  state: (): DeviceState => ({
    devices: [],
    totalDevices: 0,
    loading: false,
    currentDevice: null
  }),

  actions: {
    async fetchDevices(params?: {
      page?: number
      limit?: number
      search?: string
      status?: string
      connection_status?: string
    }) {
      this.loading = true
      try {
        const response = await getDevices(params)
        this.devices = response.items
        this.totalDevices = response.total
      } catch (error) {
        console.error('Failed to fetch devices:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    setCurrentDevice(device: Device | null) {
      this.currentDevice = device
    },

    updateDeviceStatus(deviceId: string, status: Device['status']) {
      const device = this.devices.find(d => d.id === deviceId)
      if (device) {
        device.status = status
      }
    },

    updateDeviceConnectionStatus(deviceId: string, connectionStatus: Device['connection_status']) {
      const device = this.devices.find(d => d.id === deviceId)
      if (device) {
        device.connection_status = connectionStatus
      }
    }
  }
})
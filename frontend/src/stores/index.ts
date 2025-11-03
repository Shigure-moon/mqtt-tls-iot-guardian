import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { RouteRecordRaw } from 'vue-router'
import router from '@/router'
import { getStorageItem, setStorageItem, removeStorageItem } from '@/utils/storage'

// App Store
export const useAppStore = defineStore('app', () => {
  // 状态
  const language = ref(getStorageItem('language') || 'zh-cn')
  const theme = ref(getStorageItem('theme') || '')
  const collapsed = ref(false)

  // 方法
  function setLanguage(newLang: string) {
    language.value = newLang
    setStorageItem('language', newLang)
  }

  function setTheme(newTheme: string) {
    theme.value = newTheme
    setStorageItem('theme', newTheme)
  }

  function toggleCollapse() {
    collapsed.value = !collapsed.value
  }

  return {
    language,
    theme,
    collapsed,
    setLanguage,
    setTheme,
    toggleCollapse
  }
})

// User Store
export const useUserStore = defineStore('user', () => {
  // 状态
  const token = ref<string | null>(getStorageItem('token'))
  const userInfo = ref<any>(null)
  const permissions = ref<string[]>([])
  const roles = ref<string[]>([])

  // 方法
  function setToken(newToken: string | null) {
    token.value = newToken
    if (newToken) {
      setStorageItem('token', newToken)
    } else {
      removeStorageItem('token')
    }
  }

  function setUserInfo(info: any) {
    if (info) {
      userInfo.value = info
      permissions.value = info.permissions || []
      roles.value = info.roles || []
    } else {
      userInfo.value = null
      permissions.value = []
      roles.value = []
    }
  }

  async function logout() {
    setToken(null)
    setUserInfo(null)
    router.push('/login')
  }

  return {
    token,
    userInfo,
    permissions,
    roles,
    setToken,
    setUserInfo,
    logout
  }
})

// 设备管理 Store
export const useDeviceStore = defineStore('device', () => {
  // 状态
  const devices = ref<any[]>([])
  const selectedDevice = ref<any>(null)
  const deviceStatus = ref<Map<string, boolean>>(new Map())

  // 方法
  function setDevices(list: any[]) {
    devices.value = list
  }

  function setSelectedDevice(device: any) {
    selectedDevice.value = device
  }

  function updateDeviceStatus(deviceId: string, status: boolean) {
    deviceStatus.value.set(deviceId, status)
  }

  return {
    devices,
    selectedDevice,
    deviceStatus,
    setDevices,
    setSelectedDevice,
    updateDeviceStatus
  }
})

// 监控管理 Store
export const useMonitoringStore = defineStore('monitoring', () => {
  // 状态
  const metrics = ref<Map<string, any>>(new Map())
  const alerts = ref<any[]>([])
  const alertRules = ref<any[]>([])

  // 方法
  function updateMetrics(deviceId: string, data: any) {
    metrics.value.set(deviceId, data)
  }

  function setAlerts(list: any[]) {
    alerts.value = list
  }

  function setAlertRules(rules: any[]) {
    alertRules.value = rules
  }

  return {
    metrics,
    alerts,
    alertRules,
    updateMetrics,
    setAlerts,
    setAlertRules
  }
})

// 安全管理 Store
export const useSecurityStore = defineStore('security', () => {
  // 状态
  const securityEvents = ref<any[]>([])
  const policies = ref<any[]>([])
  const blacklist = ref<string[]>([])

  // 方法
  function setSecurityEvents(events: any[]) {
    securityEvents.value = events
  }

  function setPolicies(list: any[]) {
    policies.value = list
  }

  function setBlacklist(list: string[]) {
    blacklist.value = list
  }

  return {
    securityEvents,
    policies,
    blacklist,
    setSecurityEvents,
    setPolicies,
    setBlacklist
  }
})
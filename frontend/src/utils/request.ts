import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import router from '@/router'

// 创建axios实例
const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000, // 增加到60秒，避免某些复杂操作（如证书生成、数据库查询等）超时
  headers: {
    'Content-Type': 'application/json',
  },
})

// 请求拦截器
service.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const userStore = useUserStore()
    const token = userStore.token
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    console.error('Request error:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
let isRefreshing = false
let failedQueue: Array<{
  resolve: (value?: any) => void
  reject: (error?: any) => void
}> = []

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token)
    }
  })
  failedQueue = []
}

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const res = response.data
    
    // Blob响应直接返回
    if (response.config.responseType === 'blob' || res instanceof Blob) {
      return res
    }
    
    // 如果后端返回的数据格式是 { code, message, data }
    if (res && typeof res === 'object' && 'code' in res) {
      if (res.code !== 200) {
        ElMessage.error(res.message || '请求失败')
        return Promise.reject(new Error(res.message || '请求失败'))
      }
      // 返回data字段
      return res.data !== undefined ? res.data : res
    }
    
    // 直接返回响应数据（FastAPI直接返回对象的情况）
    return res
  },
  async (error) => {
    // 处理超时错误
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      const config = error.config
      const url = config?.url || '未知请求'
      console.error(`请求超时: ${url}`, error)
      ElMessage.error(`请求超时，请检查网络连接或稍后重试`)
      return Promise.reject(error)
    }
    
    // 404错误是正常的业务逻辑（资源不存在），不需要输出错误日志
    // 特别是OTA状态查询，404表示没有任务，这是正常的
    const isOTAStatusRequest = error.config?.url?.includes('/ota-update/') && error.config?.url?.includes('/status')
    if (error.response?.status === 404 && isOTAStatusRequest) {
      // OTA状态查询的404完全静默处理，不抛出异常
      return Promise.resolve({ status: 404 })
    }
    
    if (error.response?.status !== 404) {
      console.error('Response error:', error)
    }
    
    if (error.response) {
      const { status, data, config } = error.response
      
      switch (status) {
        case 401:
          const userStore = useUserStore()
          
          // 如果是刷新token的请求失败，直接登出
          if (config?.url?.includes('/auth/refresh')) {
            userStore.logout()
            router.push('/login')
            return Promise.reject(error)
          }
          
          // 如果正在刷新，将请求加入队列
          if (isRefreshing) {
            return new Promise((resolve, reject) => {
              failedQueue.push({ resolve, reject })
            }).then(token => {
              if (config.headers) {
                config.headers.Authorization = `Bearer ${token}`
              }
              return service(config)
            }).catch(err => {
              return Promise.reject(err)
            })
          }
          
          // 尝试刷新token
          isRefreshing = true
          
          try {
            const newToken = await userStore.refreshAccessToken()
            processQueue(null, newToken)
            
            // 重试原始请求
            if (config.headers) {
              config.headers.Authorization = `Bearer ${newToken}`
            }
            isRefreshing = false
            return service(config)
          } catch (refreshError) {
            processQueue(refreshError, null)
            isRefreshing = false
            ElMessage.error('登录已过期，请重新登录')
          userStore.logout()
          router.push('/login')
            return Promise.reject(refreshError)
          }
        case 403:
          ElMessage.error('拒绝访问')
          break
        case 404:
          // 404错误不显示提示，因为已经在具体业务逻辑中处理
          break
        case 500:
          ElMessage.error(data?.detail || data?.message || '服务器内部错误')
          break
        default:
          ElMessage.error(data?.detail || data?.message || '请求失败')
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接')
    } else {
      ElMessage.error(error.message || '请求失败')
    }
    
    return Promise.reject(error)
  }
)

export default service


import axios from 'axios'
import type { AxiosRequestConfig } from 'axios'

// 创建axios实例
const service = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API || '/api/v1',
  timeout: 10000
})

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    // 从localStorage获取token
    const token = localStorage.getItem('token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  (response) => {
    const res = response.data
    // 如果是二进制数据直接返回
    if (response.request.responseType === 'blob') {
      return res
    }
    // 根据后端约定，非200状态码表示请求异常
    if (res.code !== 200) {
      // token过期或未登录
      if (res.code === 401) {
        // 清除token并重定向到登录页
        localStorage.removeItem('token')
        window.location.href = '/login'
      }
      return Promise.reject(new Error(res.message || '未知错误'))
    }
    return res.data
  },
  (error) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 封装GET请求
export function get<T>(url: string, params?: any, config?: AxiosRequestConfig) {
  return service.get<T>(url, { params, ...config })
}

// 封装POST请求
export function post<T>(url: string, data?: any, config?: AxiosRequestConfig) {
  return service.post<T>(url, data, config)
}

// 封装PUT请求
export function put<T>(url: string, data?: any, config?: AxiosRequestConfig) {
  return service.put<T>(url, data, config)
}

// 封装DELETE请求
export function del<T>(url: string, config?: AxiosRequestConfig) {
  return service.delete<T>(url, config)
}
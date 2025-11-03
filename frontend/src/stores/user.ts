import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'
import { Storage, STORAGE_KEYS } from '@/utils/storage'
import request from '@/utils/request'
import router from '@/router'

interface UserInfo {
  id: string
  username: string
  email: string
  full_name?: string
  mobile?: string
  is_active: boolean
  is_admin: boolean
  created_at: string
  updated_at: string
}

interface LoginForm {
  username: string
  password: string
}

interface TokenResponse {
  access_token: string
  refresh_token: string
  token_type: string
}

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(Storage.get(STORAGE_KEYS.TOKEN) || '')
  const refreshToken = ref<string>(Storage.get(STORAGE_KEYS.REFRESH_TOKEN) || '')
  const userInfo = ref<UserInfo | null>(Storage.get(STORAGE_KEYS.USER_INFO))

  // 计算属性
  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => userInfo.value?.is_admin || false)

  // 登录
  const login = async (form: LoginForm) => {
    // OAuth2PasswordRequestForm 需要 application/x-www-form-urlencoded 格式
    const params = new URLSearchParams()
    params.append('username', form.username)
    params.append('password', form.password)

    const response = await request.post('/auth/login', params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }) as TokenResponse

    token.value = response.access_token
    refreshToken.value = response.refresh_token
    
    Storage.set(STORAGE_KEYS.TOKEN, response.access_token)
    Storage.set(STORAGE_KEYS.REFRESH_TOKEN, response.refresh_token)

    // 获取用户信息
    await fetchUserInfo()
  }

  // 刷新token
  const refreshAccessToken = async () => {
    try {
      // 后端refresh接口需要使用当前token作为Authorization头
      // 创建一个临时的axios实例，使用refresh_token作为token
      const tempRequest = axios.create({
        baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${refreshToken.value}`,
        },
      })
      
      const response = await tempRequest.post('/auth/refresh')
      // tempRequest返回的是axios response，需要访问data
      const tokenData = response.data as TokenResponse
      
      token.value = tokenData.access_token
      refreshToken.value = tokenData.refresh_token
      Storage.set(STORAGE_KEYS.TOKEN, tokenData.access_token)
      Storage.set(STORAGE_KEYS.REFRESH_TOKEN, tokenData.refresh_token)
      
      return tokenData.access_token
    } catch (error) {
      logout()
      throw error
    }
  }

  // 获取用户信息
  const fetchUserInfo = async () => {
    try {
      const info = await request.get('/users/me') as UserInfo
      userInfo.value = info
      Storage.set(STORAGE_KEYS.USER_INFO, info)
    } catch (error) {
      console.error('Fetch user info error:', error)
    }
  }

  // 登出
  const logout = () => {
    token.value = ''
    refreshToken.value = ''
    userInfo.value = null
    
    Storage.remove(STORAGE_KEYS.TOKEN)
    Storage.remove(STORAGE_KEYS.REFRESH_TOKEN)
    Storage.remove(STORAGE_KEYS.USER_INFO)
    
    router.push('/login')
  }

  return {
    token,
    refreshToken,
    userInfo,
    isLoggedIn,
    isAdmin,
    login,
    refreshAccessToken,
    fetchUserInfo,
    logout,
  }
})


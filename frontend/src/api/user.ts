import request from '@/utils/request'
import type { LoginData, RegisterData, UserInfo, UserCreate, UserUpdate } from '@/types/user'

// Auth APIs
export const login = (data: LoginData) => {
  return request({
    url: '/auth/login',
    method: 'post',
    data: {
      username: data.username,
      password: data.password
    }
  })
}

export const register = (data: RegisterData) => {
  return request({
    url: '/auth/register',
    method: 'post',
    data
  })
}

export const refreshToken = (token: string) => {
  return request({
    url: '/auth/refresh',
    method: 'post',
    data: { refresh_token: token }
  })
}

// User APIs
export const getUserInfo = () => {
  return request({
    url: '/users/me',
    method: 'get'
  })
}

export const updateUserInfo = (data: UserUpdate) => {
  return request({
    url: '/users/me',
    method: 'put',
    data
  })
}

export const createUser = (data: UserCreate) => {
  return request({
    url: '/users',
    method: 'post',
    data
  })
}

export const getUserById = (id: string) => {
  return request({
    url: `/users/${id}`,
    method: 'get'
  })
}

export const updateUser = (id: string, data: UserUpdate) => {
  return request({
    url: `/users/${id}`,
    method: 'put',
    data
  })
}

export const deleteUser = (id: string) => {
  return request({
    url: `/users/${id}`,
    method: 'delete'
  })
}
import { defineStore } from 'pinia'
import type { UserInfo } from '@/types/user'
import { getCurrentUser, login as userLogin } from '@/api/user'

interface UserState {
  userInfo: UserInfo | null
  token: string | null
  permissions: string[]
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    userInfo: null,
    token: localStorage.getItem('token'),
    permissions: []
  }),

  getters: {
    isLoggedIn(): boolean {
      return !!this.token
    },
    hasPermission() {
      return (permission: string) => this.permissions.includes(permission)
    }
  },

  actions: {
    async login(username: string, password: string) {
      const { token, user } = await userLogin({ username, password })
      this.token = token
      this.userInfo = user
      this.permissions = user.permissions
      localStorage.setItem('token', token)
    },

    async fetchUserInfo() {
      if (!this.token) return
      try {
        const user = await getCurrentUser()
        this.userInfo = user
        this.permissions = user.permissions
      } catch (error) {
        this.logout()
        throw error
      }
    },

    logout() {
      this.token = null
      this.userInfo = null
      this.permissions = []
      localStorage.removeItem('token')
    }
  }
})
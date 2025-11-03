// User related types
export interface LoginData {
  username: string
  password: string
}

export interface RegisterData {
  username: string
  email: string
  password: string
  confirm_password: string
  full_name?: string
  mobile?: string
}

export interface UserInfo {
  id: string
  username: string
  email: string
  full_name?: string
  mobile?: string
  is_active: boolean
  is_admin: boolean
  created_at: string
  updated_at: string
  last_login_at?: string
  roles: string[]
  permissions: string[]
}

export interface UserCreate {
  username: string
  email: string
  password: string
  full_name?: string
  mobile?: string
  is_active?: boolean
  is_admin?: boolean
}

export interface UserUpdate {
  email?: string
  password?: string
  full_name?: string
  mobile?: string
  is_active?: boolean
}
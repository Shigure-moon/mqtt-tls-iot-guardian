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
}

export interface LoginForm {
  username: string
  password: string
}

export interface TokenResponse {
  access_token: string
  refresh_token: string
  token_type: string
}


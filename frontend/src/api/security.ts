import { get, post, put, del } from '@/utils/request'

// 安全策略类型定义
export interface SecurityPolicy {
  id: string
  name: string
  description?: string
  rules: SecurityRule[]
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface SecurityRule {
  id: string
  type: string
  action: 'allow' | 'deny'
  priority: number
  conditions: Record<string, any>
  metadata?: Record<string, any>
}

export interface SecurityEvent {
  id: string
  device_id?: string
  user_id?: string
  event_type: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  description: string
  metadata: Record<string, any>
  timestamp: string
}

// 获取安全策略列表
export function getSecurityPolicies(params?: {
  page?: number
  limit?: number
  search?: string
  is_active?: boolean
}) {
  return get<{
    items: SecurityPolicy[]
    total: number
    page: number
    limit: number
  }>('/security/policies', params)
}

// 创建安全策略
export function createSecurityPolicy(data: Omit<SecurityPolicy, 'id' | 'created_at' | 'updated_at'>) {
  return post<SecurityPolicy>('/security/policies', data)
}

// 获取指定安全策略
export function getSecurityPolicy(id: string) {
  return get<SecurityPolicy>(`/security/policies/${id}`)
}

// 更新安全策略
export function updateSecurityPolicy(
  id: string,
  data: Partial<Omit<SecurityPolicy, 'id' | 'created_at' | 'updated_at'>>
) {
  return put<SecurityPolicy>(`/security/policies/${id}`, data)
}

// 删除安全策略
export function deleteSecurityPolicy(id: string) {
  return del(`/security/policies/${id}`)
}

// 获取安全事件列表
export function getSecurityEvents(params?: {
  page?: number
  limit?: number
  device_id?: string
  user_id?: string
  event_type?: string[]
  severity?: string[]
  start_time?: string
  end_time?: string
}) {
  return get<{
    items: SecurityEvent[]
    total: number
    page: number
    limit: number
  }>('/security/events', params)
}

// 获取安全事件统计信息
export function getSecurityStats(params?: {
  start_time?: string
  end_time?: string
  group_by?: string[]
}) {
  return get('/security/stats', params)
}

// 验证安全规则
export function validateSecurityRule(rule: Omit<SecurityRule, 'id'>) {
  return post('/security/rules/validate', rule)
}

// 获取安全审计日志
export function getSecurityAuditLogs(params?: {
  page?: number
  limit?: number
  user_id?: string
  action?: string[]
  resource_type?: string[]
  start_time?: string
  end_time?: string
}) {
  return get('/security/audit-logs', params)
}

// 导出安全审计日志
export function exportSecurityAuditLogs(params?: {
  format?: 'csv' | 'json'
  start_time?: string
  end_time?: string
}) {
  return get('/security/audit-logs/export', {
    ...params,
    responseType: 'blob'
  })
}
import { get, post } from '@/utils/request'

// 监控指标类型定义
export interface MetricData {
  timestamp: string
  value: number
  tags?: Record<string, string>
}

export interface MetricQuery {
  metric: string
  start_time: string
  end_time: string
  interval?: string
  aggregation?: 'avg' | 'sum' | 'min' | 'max' | 'count'
  group_by?: string[]
  filters?: Record<string, string | string[]>
}

export interface AlertRule {
  id: string
  name: string
  description?: string
  metric: string
  condition: {
    operator: '>' | '<' | '>=' | '<=' | '=' | '!='
    threshold: number
  }
  severity: 'low' | 'medium' | 'high' | 'critical'
  duration: string  // 如 "5m", "1h"
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Dashboard {
  id: string
  name: string
  description?: string
  layout: DashboardPanel[]
  created_at: string
  updated_at: string
}

export interface DashboardPanel {
  id: string
  title: string
  type: 'line' | 'bar' | 'gauge' | 'table' | 'stat'
  query: MetricQuery
  options: Record<string, any>
  position: {
    x: number
    y: number
    w: number
    h: number
  }
}

// 获取监控指标数据
export function getMetricData(query: MetricQuery) {
  return post<MetricData[]>('/monitoring/query', query)
}

// 获取可用的监控指标列表
export function getAvailableMetrics() {
  return get<string[]>('/monitoring/metrics')
}

// 获取告警规则列表
export function getAlertRules(params?: {
  page?: number
  limit?: number
  search?: string
  severity?: string[]
  is_active?: boolean
}) {
  return get<{
    items: AlertRule[]
    total: number
    page: number
    limit: number
  }>('/monitoring/alert-rules', params)
}

// 创建告警规则
export function createAlertRule(data: Omit<AlertRule, 'id' | 'created_at' | 'updated_at'>) {
  return post<AlertRule>('/monitoring/alert-rules', data)
}

// 获取指定告警规则
export function getAlertRule(id: string) {
  return get<AlertRule>(`/monitoring/alert-rules/${id}`)
}

// 更新告警规则
export function updateAlertRule(
  id: string,
  data: Partial<Omit<AlertRule, 'id' | 'created_at' | 'updated_at'>>
) {
  return post<AlertRule>(`/monitoring/alert-rules/${id}`, data)
}

// 删除告警规则
export function deleteAlertRule(id: string) {
  return post(`/monitoring/alert-rules/${id}/delete`)
}

// 获取仪表板列表
export function getDashboards(params?: {
  page?: number
  limit?: number
  search?: string
}) {
  return get<{
    items: Dashboard[]
    total: number
    page: number
    limit: number
  }>('/monitoring/dashboards', params)
}

// 创建仪表板
export function createDashboard(data: Omit<Dashboard, 'id' | 'created_at' | 'updated_at'>) {
  return post<Dashboard>('/monitoring/dashboards', data)
}

// 获取指定仪表板
export function getDashboard(id: string) {
  return get<Dashboard>(`/monitoring/dashboards/${id}`)
}

// 更新仪表板
export function updateDashboard(
  id: string,
  data: Partial<Omit<Dashboard, 'id' | 'created_at' | 'updated_at'>>
) {
  return post<Dashboard>(`/monitoring/dashboards/${id}`, data)
}

// 删除仪表板
export function deleteDashboard(id: string) {
  return post(`/monitoring/dashboards/${id}/delete`)
}

// 获取系统健康状态
export function getSystemHealth() {
  return get('/monitoring/health')
}

// 获取系统资源使用情况
export function getSystemResources() {
  return get('/monitoring/resources')
}
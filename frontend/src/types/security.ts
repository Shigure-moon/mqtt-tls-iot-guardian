// 安全相关类型定义

export interface SecurityEvent {
  id: string
  event_type: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  source_ip?: string
  device_id?: string
  description: string
  threat_source?: 'llm_ids_agent' | 'cybersentinal' | 'manual'
  raw_data?: Record<string, any>
  handled: boolean
  handler_id?: string
  handled_at?: string
  created_at: string
}

export interface ThreatResponse {
  success: boolean
  message: string
  event_id?: string
  actions_taken: string[]
}

export interface ThreatResponseRequest {
  source: 'llm_ids_agent' | 'cybersentinal'
  threat_type: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  source_ip?: string
  device_id?: string
  description: string
  raw_data?: Record<string, any>
  threat_score?: number
}

export interface SecurityStats {
  total_events: number
  unhandled_events: number
  severity_distribution: {
    low: number
    medium: number
    high: number
    critical: number
  }
  recent_events: SecurityEvent[]
  recent_24h_events: number
  active_blacklist_count: number
  expiring_blacklist_count: number
  audit_log_types_7d: Record<string, number>
}

export interface BlacklistedIP {
  id: string
  ip_address: string
  reason?: string
  expiry_at?: string
  created_at: string
  updated_at: string
}


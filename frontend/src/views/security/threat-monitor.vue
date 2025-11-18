<template>
  <div class="threat-monitor-page">
    <!-- 统计卡片 -->
    <el-row :gutter="20" style="margin-bottom: 20px">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #f56c6c">
              <el-icon><Warning /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.total_events }}</div>
              <div class="stat-label">总威胁事件</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #e6a23c">
              <el-icon><Clock /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.unhandled_events }}</div>
              <div class="stat-label">待处理事件</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #409eff">
              <el-icon><Timer /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.recent_24h_events }}</div>
              <div class="stat-label">24小时内事件</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #67c23a">
              <el-icon><Lock /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.active_blacklist_count }}</div>
              <div class="stat-label">活跃黑名单</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 威胁分布图表 -->
    <el-row :gutter="20" style="margin-bottom: 20px">
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>威胁严重程度分布</span>
              <el-button text @click="refreshStats">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          <div ref="severityChartRef" style="height: 300px"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>威胁来源分布</span>
              <el-button text @click="refreshStats">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          <div ref="sourceChartRef" style="height: 300px"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 威胁事件列表 -->
    <el-card>
      <template #header>
        <div class="card-header">
          <span>威胁事件列表</span>
          <div class="header-actions">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索事件描述、IP地址..."
              style="width: 250px; margin-right: 10px"
              clearable
              @input="handleSearch"
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-select
              v-model="filterSeverity"
              placeholder="严重程度"
              style="width: 120px; margin-right: 10px"
              clearable
              @change="fetchEvents"
            >
              <el-option label="低" value="low" />
              <el-option label="中" value="medium" />
              <el-option label="高" value="high" />
              <el-option label="严重" value="critical" />
            </el-select>
            <el-select
              v-model="filterSource"
              placeholder="威胁来源"
              style="width: 150px; margin-right: 10px"
              clearable
              @change="fetchEvents"
            >
              <el-option label="LLM-IDS-Agent" value="llm_ids_agent" />
              <el-option label="CyberSentinal" value="cybersentinal" />
              <el-option label="手动" value="manual" />
            </el-select>
            <el-select
              v-model="filterHandled"
              placeholder="处理状态"
              style="width: 120px; margin-right: 10px"
              clearable
              @change="fetchEvents"
            >
              <el-option label="已处理" :value="true" />
              <el-option label="未处理" :value="false" />
            </el-select>
            <el-button @click="fetchEvents" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button type="primary" @click="handleBatchHandle" :disabled="selectedEvents.length === 0">
              <el-icon><Check /></el-icon>
              批量处理
            </el-button>
          </div>
        </div>
      </template>

      <el-table
        v-loading="loading"
        :data="filteredEvents"
        style="width: 100%"
        @selection-change="handleSelectionChange"
        @row-click="handleRowClick"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="created_at" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="severity" label="严重程度" width="120">
          <template #default="{ row }">
            <el-tag :type="getSeverityType(row.severity)" effect="dark">
              {{ getSeverityText(row.severity) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="threat_source" label="威胁来源" width="150">
          <template #default="{ row }">
            <el-tag v-if="row.threat_source" :type="getThreatSourceType(row.threat_source)">
              {{ getSourceText(row.threat_source) }}
            </el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="event_type" label="事件类型" width="150" />
        <el-table-column prop="source_ip" label="源IP" width="140">
          <template #default="{ row }">
            <el-tag v-if="row.source_ip" size="small">{{ row.source_ip }}</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="device_id" label="设备ID" width="150">
          <template #default="{ row }">
            <el-link v-if="row.device_id" type="primary" @click.stop="handleViewDevice(row.device_id)">
              {{ row.device_id }}
            </el-link>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="handled" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.handled ? 'success' : 'warning'">
              {{ row.handled ? '已处理' : '待处理' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click.stop="handleViewDetail(row)">
              详情
            </el-button>
            <el-button
              v-if="!row.handled"
              link
              type="success"
              size="small"
              @click.stop="handleMarkHandled(row)"
            >
              标记已处理
            </el-button>
            <el-button
              v-if="row.source_ip && !row.handled"
              link
              type="danger"
              size="small"
              @click.stop="handleBlockIP(row)"
            >
              封禁IP
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.size"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 20px; justify-content: flex-end"
        @size-change="fetchEvents"
        @current-change="fetchEvents"
      />
    </el-card>

    <!-- 事件详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      :title="`威胁事件详情 - ${currentEvent?.event_type}`"
      width="800px"
    >
      <el-descriptions v-if="currentEvent" :column="2" border>
        <el-descriptions-item label="事件ID">{{ currentEvent.id }}</el-descriptions-item>
        <el-descriptions-item label="事件类型">{{ currentEvent.event_type }}</el-descriptions-item>
        <el-descriptions-item label="严重程度">
          <el-tag :type="getSeverityType(currentEvent.severity)">
            {{ getSeverityText(currentEvent.severity) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="威胁来源">
          <el-tag v-if="currentEvent.threat_source" :type="getThreatSourceType(currentEvent.threat_source)">
            {{ getSourceText(currentEvent.threat_source) }}
          </el-tag>
          <span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="源IP地址">
          {{ currentEvent.source_ip || '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="设备ID">
          <el-link v-if="currentEvent.device_id" type="primary" @click="handleViewDevice(currentEvent.device_id)">
            {{ currentEvent.device_id }}
          </el-link>
          <span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">
          {{ formatTime(currentEvent.created_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">
          {{ currentEvent.description }}
        </el-descriptions-item>
        <el-descriptions-item label="处理状态">
          <el-tag :type="currentEvent.handled ? 'success' : 'warning'">
            {{ currentEvent.handled ? '已处理' : '待处理' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="处理时间">
          {{ currentEvent.handled_at ? formatTime(currentEvent.handled_at) : '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="原始数据" :span="2">
          <el-input
            :model-value="JSON.stringify(currentEvent.raw_data || {}, null, 2)"
            type="textarea"
            :rows="8"
            readonly
            style="font-family: monospace; font-size: 12px"
          />
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
        <el-button
          v-if="currentEvent && !currentEvent.handled"
          type="primary"
          @click="handleMarkHandled(currentEvent)"
        >
          标记已处理
        </el-button>
        <el-button
          v-if="currentEvent && currentEvent.source_ip && !currentEvent.handled"
          type="danger"
          @click="handleBlockIP(currentEvent)"
        >
          封禁IP
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Warning, Clock, Timer, Lock, Refresh, Search, Check } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { useRouter } from 'vue-router'
import request from '@/utils/request'
import type { SecurityEvent, SecurityStats } from '@/types/security'

const router = useRouter()

// 统计数据
const stats = ref<SecurityStats>({
  total_events: 0,
  unhandled_events: 0,
  severity_distribution: {
    low: 0,
    medium: 0,
    high: 0,
    critical: 0,
  },
  recent_events: [],
  recent_24h_events: 0,
  active_blacklist_count: 0,
  expiring_blacklist_count: 0,
  audit_log_types_7d: {},
})

// 事件列表
const loading = ref(false)
const events = ref<SecurityEvent[]>([])
const selectedEvents = ref<SecurityEvent[]>([])
const searchKeyword = ref('')
const filterSeverity = ref<string | null>(null)
const filterSource = ref<string | null>(null)
const filterHandled = ref<boolean | null>(null)

// 分页
const pagination = ref({
  page: 1,
  size: 20,
  total: 0,
})

// 图表引用
const severityChartRef = ref<HTMLDivElement>()
const sourceChartRef = ref<HTMLDivElement>()
let severityChart: echarts.ECharts | null = null
let sourceChart: echarts.ECharts | null = null

// 详情对话框
const detailDialogVisible = ref(false)
const currentEvent = ref<SecurityEvent | null>(null)

// 自动刷新定时器
let refreshTimer: number | null = null

// 获取统计数据
const fetchStats = async () => {
  try {
    const response = await request.get('/security/stats')
    stats.value = response.data || response
    updateCharts()
  } catch (error: any) {
    console.error('获取统计数据失败:', error)
  }
}

// 获取事件列表
const fetchEvents = async () => {
  try {
    loading.value = true
    const params: any = {
      skip: (pagination.value.page - 1) * pagination.value.size,
      limit: pagination.value.size,
    }
    if (filterSeverity.value) {
      params.severity = filterSeverity.value
    }
    if (filterHandled.value !== null) {
      params.handled = filterHandled.value
    }

    const response = await request.get('/security/events', { params })
    const data = response.data || response
    events.value = Array.isArray(data) ? data : (data.items || [])
    pagination.value.total = data.total || events.value.length
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '获取威胁事件失败')
  } finally {
    loading.value = false
  }
}

// 过滤事件
const filteredEvents = computed(() => {
  let result = events.value

  // 搜索关键词过滤
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(
      (event) =>
        event.description.toLowerCase().includes(keyword) ||
        (event.source_ip && event.source_ip.includes(keyword)) ||
        (event.device_id && event.device_id.toLowerCase().includes(keyword))
    )
  }

  // 威胁来源过滤
  if (filterSource.value) {
    result = result.filter((event) => event.threat_source === filterSource.value)
  }

  return result
})

// 更新图表
const updateCharts = () => {
  nextTick(() => {
    // 严重程度分布图表
    if (severityChartRef.value && stats.value) {
      if (!severityChart) {
        severityChart = echarts.init(severityChartRef.value)
      }
      const severityData = [
        { value: stats.value.severity_distribution.low, name: '低' },
        { value: stats.value.severity_distribution.medium, name: '中' },
        { value: stats.value.severity_distribution.high, name: '高' },
        { value: stats.value.severity_distribution.critical, name: '严重' },
      ]
      severityChart.setOption({
        tooltip: {
          trigger: 'item',
          formatter: '{a} <br/>{b}: {c} ({d}%)',
        },
        legend: {
          orient: 'vertical',
          left: 'left',
        },
        series: [
          {
            name: '威胁严重程度',
            type: 'pie',
            radius: ['40%', '70%'],
            avoidLabelOverlap: false,
            itemStyle: {
              borderRadius: 10,
              borderColor: '#fff',
              borderWidth: 2,
            },
            label: {
              show: true,
              formatter: '{b}: {c}',
            },
            emphasis: {
              label: {
                show: true,
                fontSize: 16,
                fontWeight: 'bold',
              },
            },
            data: severityData,
          },
        ],
      })
    }

    // 威胁来源分布图表
    if (sourceChartRef.value && events.value.length > 0) {
      if (!sourceChart) {
        sourceChart = echarts.init(sourceChartRef.value)
      }
      const sourceCount: Record<string, number> = {}
      events.value.forEach((event) => {
        const source = event.threat_source || 'unknown'
        sourceCount[source] = (sourceCount[source] || 0) + 1
      })
      const sourceData = Object.entries(sourceCount).map(([key, value]) => ({
        value,
        name: getSourceText(key as any),
      }))
      sourceChart.setOption({
        tooltip: {
          trigger: 'item',
        },
        legend: {
          orient: 'vertical',
          left: 'left',
        },
        series: [
          {
            name: '威胁来源',
            type: 'pie',
            radius: '50%',
            data: sourceData,
            emphasis: {
              itemStyle: {
                shadowBlur: 10,
                shadowOffsetX: 0,
                shadowColor: 'rgba(0, 0, 0, 0.5)',
              },
            },
          },
        ],
      })
    }
  })
}

// 刷新统计数据
const refreshStats = async () => {
  await Promise.all([fetchStats(), fetchEvents()])
  ElMessage.success('数据已刷新')
}

// 查看详情
const handleViewDetail = (event: SecurityEvent) => {
  currentEvent.value = event
  detailDialogVisible.value = true
}

// 查看设备
const handleViewDevice = (deviceId: string) => {
  router.push(`/devices/${deviceId}`)
}

// 标记已处理
const handleMarkHandled = async (event: SecurityEvent) => {
  try {
    await request.post(`/security/events/${event.id}/handle`)
    ElMessage.success('事件已标记为已处理')
    await fetchEvents()
    await fetchStats()
    if (detailDialogVisible.value) {
      detailDialogVisible.value = false
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '操作失败')
  }
}

// 封禁IP
const handleBlockIP = async (event: SecurityEvent) => {
  if (!event.source_ip) {
    ElMessage.warning('该事件没有源IP地址')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要封禁IP地址 ${event.source_ip} 吗？`,
      '确认封禁',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    await request.post('/security/blacklist', {
      ip_address: event.source_ip,
      reason: `威胁事件: ${event.description}`,
    })

    ElMessage.success(`IP ${event.source_ip} 已添加到黑名单`)
    await fetchStats()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '批量处理失败')
    }
  }
}

// 隔离设备
const handleIsolateDevice = async (event: SecurityEvent) => {
  if (!event.device_id) {
    ElMessage.warning('该事件没有关联的设备ID')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要隔离设备 "${event.device_id}" 吗？隔离后设备将无法连接。`,
      '确认隔离设备',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    await request.post('/security/threats/isolate-device', {
      device_id: event.device_id,
      reason: `手动隔离: ${event.description}`,
      duration_minutes: 60,
    })

    ElMessage.success('设备已隔离')
    await fetchStats()
    await fetchEvents()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '隔离设备失败')
    }
  }
}

// 切换自动刷新
const autoRefresh = ref(false)

const toggleAutoRefresh = () => {
  autoRefresh.value = !autoRefresh.value

  if (autoRefresh.value) {
    refreshTimer = window.setInterval(() => {
      fetchStats()
      fetchEvents()
    }, 30000) // 每30秒刷新一次
    ElMessage.success('已开启自动刷新（30秒间隔）')
  } else {
    if (refreshTimer) {
      clearInterval(refreshTimer)
      refreshTimer = null
    }
    ElMessage.info('已停止自动刷新')
  }
}

// 处理搜索
const handleSearch = () => {
  pagination.value.page = 1
  fetchEvents()
}

// 重置筛选器
const resetFilters = () => {
  searchKeyword.value = ''
  filterSeverity.value = null
  filterSource.value = null
  filterHandled.value = null
  pagination.value.page = 1
  fetchEvents()
}

// 处理选择变化
const handleSelectionChange = (selection: SecurityEvent[]) => {
  selectedEvents.value = selection
}

// 批量处理
const handleBatchHandle = async () => {
  if (selectedEvents.value.length === 0) {
    ElMessage.warning('请选择要处理的事件')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要批量处理 ${selectedEvents.value.length} 个事件吗？`,
      '批量处理',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )

    const promises = selectedEvents.value.map((event) =>
      request.post(`/security/events/${event.id}/handle`)
    )
    await Promise.all(promises)

    ElMessage.success(`已处理 ${selectedEvents.value.length} 个事件`)
    selectedEvents.value = []
    await fetchEvents()
    await fetchStats()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '批量处理失败')
    }
  }
}

// 处理行点击
const handleRowClick = (row: SecurityEvent) => {
  // 可以在这里添加行点击逻辑
}

// 格式化时间
const formatTime = (time: string | undefined) => {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}

// 获取严重程度类型
const getSeverityType = (severity: string) => {
  const map: Record<string, string> = {
    low: 'success',
    medium: 'warning',
    high: 'danger',
    critical: 'danger',
  }
  return map[severity] || 'info'
}

// 获取严重程度文本
const getSeverityText = (severity: string) => {
  const map: Record<string, string> = {
    low: '低',
    medium: '中',
    high: '高',
    critical: '严重',
  }
  return map[severity] || severity
}

// 获取威胁来源类型
const getThreatSourceType = (source: string | undefined) => {
  if (!source) return 'info'
  const map: Record<string, string> = {
    llm_ids_agent: 'primary',
    cybersentinal: 'success',
    manual: 'warning',
  }
  return map[source] || 'info'
}

// 获取威胁来源文本
const getThreatSourceText = (source: string | undefined) => {
  if (!source) return '未知'
  const map: Record<string, string> = {
    llm_ids_agent: 'LLM-IDS-Agent',
    cybersentinal: 'CyberSentinal',
    manual: '手动',
  }
  return map[source] || source
}

// 获取来源文本（用于图表）
const getSourceText = (source: string) => {
  return getThreatSourceText(source)
}

// 获取动作文本
const getActionText = (action: string) => {
  if (action.includes('隔离')) return '设备隔离'
  if (action.includes('吊销')) return '证书吊销'
  if (action.includes('黑名单')) return 'IP黑名单'
  return action
}

// 生命周期
onMounted(async () => {
  await fetchStats()
  await fetchEvents()
  await nextTick()
  updateCharts()

  // 监听窗口大小变化，调整图表
  window.addEventListener('resize', () => {
    severityChart?.resize()
    sourceChart?.resize()
  })
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
  severityChart?.dispose()
  sourceChart?.dispose()
  window.removeEventListener('resize', () => {
    severityChart?.resize()
    sourceChart?.resize()
  })
})
</script>

<style scoped lang="scss">
.threat-monitor-page {
  .stat-card {
    display: flex;
    align-items: center;
    gap: 15px;

    .stat-icon {
      width: 60px;
      height: 60px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      font-size: 24px;
    }

    .stat-content {
      flex: 1;

      .stat-value {
        font-size: 28px;
        font-weight: bold;
        color: #303133;
        margin-bottom: 5px;
      }

      .stat-label {
        font-size: 14px;
        color: #909399;
      }
    }
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: 500;
  }

  .header-actions {
    display: flex;
    gap: 10px;
  }

  .filters {
    background-color: #f5f7fa;
    padding: 15px;
    border-radius: 4px;
  }

  .event-details {
    padding: 10px;
    background-color: #fafafa;

    pre {
      margin: 0;
      font-size: 12px;
      line-height: 1.5;
      color: #606266;
    }
  }
}
</style>

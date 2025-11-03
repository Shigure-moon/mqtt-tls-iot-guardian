<template>
  <div class="device-detail">
    <el-card>
      <template #header>
        <div class="card-header">
          <el-button @click="$router.back()">
            <el-icon><ArrowLeft /></el-icon>
            返回
          </el-button>
          <span>设备详情</span>
        </div>
      </template>

      <el-descriptions v-loading="loading" :column="2" border>
        <el-descriptions-item label="设备ID">{{ deviceInfo?.device_id }}</el-descriptions-item>
        <el-descriptions-item label="设备名称">{{ deviceInfo?.name }}</el-descriptions-item>
        <el-descriptions-item label="设备类型">{{ deviceInfo?.type }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="getStatusType(deviceInfo?.status)">
            {{ getStatusText(deviceInfo?.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ deviceInfo?.description || '-' }}</el-descriptions-item>
        <el-descriptions-item label="最后在线时间">
          {{ formatTime(deviceInfo?.last_online_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">
          {{ formatTime(deviceInfo?.created_at) }}
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>监控数据</span>
          <div class="header-actions">
            <el-select
              v-model="selectedMetric"
              size="small"
              style="width: 200px"
              @change="fetchMetricData"
            >
              <el-option
                v-for="metric in metrics"
                :key="metric.value"
                :label="metric.label"
                :value="metric.value"
              />
            </el-select>
            <el-button-group>
              <el-button
                v-for="period in timePeriods"
                :key="period.value"
                size="small"
                :type="selectedPeriod === period.value ? 'primary' : ''"
                @click="handlePeriodChange(period.value)"
              >
                {{ period.label }}
              </el-button>
            </el-button-group>
          </div>
        </div>
      </template>
      <div id="metric-chart" style="height: 300px"></div>
    </el-card>

    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>告警列表</span>
          <el-button type="primary" link @click="fetchAlerts">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>
      <el-table :data="alerts" style="width: 100%">
        <el-table-column prop="type" label="告警类型" width="150" />
        <el-table-column prop="severity" label="严重程度" width="100">
          <template #default="{ row }">
            <el-tag :type="getSeverityType(row.severity)">
              {{ row.severity }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="message" label="告警消息" />
        <el-table-column prop="timestamp" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.timestamp) }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'resolved' ? 'success' : 'warning'">
              {{ row.status === 'resolved' ? '已解决' : '待处理' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Refresh } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import request from '@/utils/request'

interface Device {
  id: string
  device_id: string
  name: string
  type: string
  status: string
  description?: string
  last_online_at?: string
  created_at?: string
}

interface Alert {
  id: string
  type: string
  severity: string
  message: string
  timestamp: string
  status: string
}

const route = useRoute()

const loading = ref(false)
const deviceInfo = ref<Device | null>(null)

// 监控数据配置
const metrics = [
  { label: '温度', value: 'temperature' },
  { label: '湿度', value: 'humidity' },
  { label: '空气质量', value: 'air_quality' },
  { label: '电池电量', value: 'battery' }
]
const selectedMetric = ref('temperature')

const timePeriods = [
  { label: '1小时', value: '1h' },
  { label: '6小时', value: '6h' },
  { label: '1天', value: '1d' },
  { label: '1周', value: '1w' }
]
const selectedPeriod = ref('1h')

// 告警列表
const alerts = ref<Alert[]>([])

// ECharts实例
let chartInstance: echarts.ECharts | null = null

const getStatusType = (status?: string) => {
  const statusMap: Record<string, string> = {
    active: 'success',
    inactive: 'info',
    disabled: 'danger',
    maintenance: 'warning',
  }
  return statusMap[status || ''] || 'info'
}

const getStatusText = (status?: string) => {
  const statusMap: Record<string, string> = {
    active: '在线',
    inactive: '离线',
    disabled: '已禁用',
    maintenance: '维护中',
  }
  return statusMap[status || ''] || status || '-'
}

const formatTime = (time?: string) => {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

const fetchDeviceDetail = async () => {
  const deviceId = route.params.id as string
  if (!deviceId) return

  loading.value = true
  try {
    const response = await request.get(`/devices/${deviceId}`)
    deviceInfo.value = response as unknown as Device
    // 获取设备信息后，加载监控数据和告警
    await Promise.all([fetchMetricData(), fetchAlerts()])
  } catch (error) {
    ElMessage.error('获取设备详情失败')
  } finally {
    loading.value = false
  }
}

// 获取监控数据
const fetchMetricData = async () => {
  if (!deviceInfo.value) return
  
  try {
    // 计算时间范围
    const now = new Date()
    const end = now.toISOString()
    const start = new Date(now.getTime() - getPeriodMilliseconds(selectedPeriod.value))
      .toISOString()
    
    const response = await request.get('/monitoring/metrics/' + deviceInfo.value.id, {
      params: {
        start_time: start,
        end_time: end,
        metric_type: selectedMetric.value,
        limit: 100
      }
    })
    
    // API返回的metrics是一个数组
    const data = Array.isArray(response) ? response : []
    if (data.length > 0) {
      // 解析JSON格式的metrics字段
      const chartData = data.map((item: any) => {
        const metrics = typeof item.metrics === 'string' ? JSON.parse(item.metrics) : item.metrics
        return {
          timestamp: item.timestamp,
          value: metrics.value
        }
      })
      updateChart(chartData)
    } else {
      updateChart([])
    }
  } catch (error) {
    // 监控数据为空时显示空图表
    console.log('获取监控数据失败或为空:', error)
    initChart()
  }
}

// 获取告警列表
const fetchAlerts = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get('/monitoring/alerts', {
      params: {
        device_id: deviceInfo.value.id,
        limit: 20
      }
    })
    alerts.value = Array.isArray(response) ? response : []
  } catch (error) {
    console.log('获取告警列表失败:', error)
  }
}

// 初始化图表
const initChart = () => {
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
  
  const chartDom = document.getElementById('metric-chart')
  if (!chartDom) return
  
  chartInstance = echarts.init(chartDom)
  chartInstance.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', boundaryGap: false, data: [] },
    yAxis: { type: 'value' },
    series: [{
      type: 'line',
      data: [],
      smooth: true,
      areaStyle: {}
    }]
  })
}

// 更新图表数据
const updateChart = (data: any[]) => {
  if (!chartInstance) {
    // 等待DOM渲染完成
    setTimeout(() => initChart(), 0)
    return
  }
  
  chartInstance.setOption({
    xAxis: {
      data: data.map((d: any) => new Date(d.timestamp).toLocaleTimeString())
    },
    series: [{
      data: data.map((d: any) => d.value)
    }]
  })
}

// 处理时间周期变化
const handlePeriodChange = (period: string) => {
  selectedPeriod.value = period
  fetchMetricData()
}

// 获取时间间隔（毫秒）
const getPeriodMilliseconds = (period: string) => {
  const map: Record<string, number> = {
    '1h': 60 * 60 * 1000,
    '6h': 6 * 60 * 60 * 1000,
    '1d': 24 * 60 * 60 * 1000,
    '1w': 7 * 24 * 60 * 60 * 1000
  }
  return map[period] || map['1h']
}

// 获取严重程度类型
const getSeverityType = (severity?: string) => {
  const types: Record<string, string> = {
    low: 'info',
    medium: 'warning',
    high: 'danger',
    critical: 'danger'
  }
  return types[severity || ''] || 'info'
}

// 自动刷新
let refreshTimer: number
const startAutoRefresh = () => {
  refreshTimer = window.setInterval(() => {
    if (deviceInfo.value) {
      fetchDeviceDetail()
    }
  }, 30000) // 每30秒刷新一次
}

onMounted(() => {
  fetchDeviceDetail()
  startAutoRefresh()
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
  if (chartInstance) {
    chartInstance.dispose()
  }
})
</script>

<style scoped lang="scss">
.device-detail {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
    
    .header-actions {
      display: flex;
      gap: 8px;
    }
  }
}
</style>


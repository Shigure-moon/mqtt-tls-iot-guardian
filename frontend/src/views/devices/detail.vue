&lt;template&gt;
  <div class="device-detail">
    <page-loading :loading="loading" />
    
    <page-header
      :title="device?.name || $t('device.device_detail')"
      :description="device?.description"
      :breadcrumbs="[
        { title: $t('device.devices'), path: '/devices' },
        { title: device?.name || $t('device.device_detail') }
      ]"
    >
      <template #extra>
        <auth-guard permission="device:control">
          <el-button-group>
            <el-button
              type="primary"
              :disabled="!isDeviceOnline"
              @click="handleCommand"
            >
              {{ $t('device.send_command') }}
            </el-button>
            <el-button
              type="warning"
              :disabled="!isDeviceOnline"
              @click="handleRestart"
            >
              {{ $t('device.restart') }}
            </el-button>
          </el-button-group>
        </auth-guard>
      </template>
    </page-header>

    <div class="detail-content" v-if="device">
      <!-- 基本信息卡片 -->
      <el-card class="detail-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('device.basic_info') }}</span>
            <auth-guard permission="device:update">
              <el-button type="primary" link @click="handleEdit">
                {{ $t('common.edit') }}
              </el-button>
            </auth-guard>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item :label="$t('device.device_model')">
            {{ device.model }}
          </el-descriptions-item>
          <el-descriptions-item :label="$t('device.serial_number')">
            {{ device.serial_number }}
          </el-descriptions-item>
          <el-descriptions-item :label="$t('device.status')">
            <el-tag :type="getStatusType(device.status)">
              {{ $t(`device.status_types.${device.status}`) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item :label="$t('device.connection_status')">
            <el-tag :type="getConnectionStatusType(device.connection_status)">
              {{ $t(`device.connection_status_types.${device.connection_status}`) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item :label="$t('device.last_online')">
            {{ formatDateTime(device.last_online_at) }}
          </el-descriptions-item>
          <el-descriptions-item :label="$t('device.created_at')">
            {{ formatDateTime(device.created_at) }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 监控数据卡片 -->
      <el-card class="detail-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('device.monitoring_data') }}</span>
            <div class="header-actions">
              <el-select
                v-model="selectedMetric"
                size="small"
                style="width: 200px"
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
        
        <div class="chart-container">
          <v-chart :option="chartOption" autoresize />
        </div>
      </el-card>

      <!-- 告警列表卡片 -->
      <el-card class="detail-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('device.alarms') }}</span>
            <el-button type="primary" link @click="refreshAlarms">
              {{ $t('common.refresh') }}
            </el-button>
          </div>
        </template>
        
        <el-table :data="alarms" style="width: 100%">
          <el-table-column
            prop="type"
            :label="$t('device.alarm_type')"
            width="150"
          />
          <el-table-column
            prop="severity"
            :label="$t('device.alarm_severity')"
            width="100"
          >
            <template #default="{ row }">
              <el-tag :type="getAlarmSeverityType(row.severity)">
                {{ $t(`device.severity_levels.${row.severity}`) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column
            prop="message"
            :label="$t('device.alarm_message')"
          />
          <el-table-column
            prop="timestamp"
            :label="$t('device.alarm_time')"
            width="180"
          >
            <template #default="{ row }">
              {{ formatDateTime(row.timestamp) }}
            </template>
          </el-table-column>
          <el-table-column
            :label="$t('common.actions')"
            width="100"
            fixed="right"
          >
            <template #default="{ row }">
              <auth-guard permission="device:alarm:resolve">
                <el-button
                  type="primary"
                  link
                  :disabled="row.resolved"
                  @click="handleResolveAlarm(row)"
                >
                  {{ $t('device.resolve_alarm') }}
                </el-button>
              </auth-guard>
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>

    <!-- 发送命令对话框 -->
    <el-dialog
      v-model="commandDialog.visible"
      :title="$t('device.send_command')"
      width="500px"
    >
      <el-form
        ref="commandFormRef"
        :model="commandDialog.form"
        :rules="commandDialog.rules"
        label-width="100px"
      >
        <el-form-item :label="$t('device.command')" prop="command">
          <el-select
            v-model="commandDialog.form.command"
            style="width: 100%"
          >
            <el-option
              v-for="cmd in availableCommands"
              :key="cmd.value"
              :label="cmd.label"
              :value="cmd.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item
          :label="$t('device.parameters')"
          prop="parameters"
        >
          <el-input
            v-model="commandDialog.form.parametersStr"
            type="textarea"
            :rows="5"
            :placeholder="$t('device.parameters_placeholder')"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="commandDialog.visible = false">
          {{ $t('common.cancel') }}
        </el-button>
        <el-button
          type="primary"
          :loading="commandDialog.submitting"
          @click="handleSendCommand"
        >
          {{ $t('common.confirm') }}
        </el-button>
      </template>
    </el-dialog>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import PageHeader from '@/components/PageHeader'
import PageLoading from '@/components/PageLoading'
import AuthGuard from '@/components/AuthGuard'
import { useDeviceStore } from '@/stores/device'
import type { Device, DeviceAlarm } from '@/types/device'
import {
  getDevice,
  sendDeviceCommand,
  getDeviceAlarms,
  resolveDeviceAlarm
} from '@/api/device'
import { getMetricData } from '@/api/monitoring'

// 注册 ECharts 组件
use([
  CanvasRenderer,
  LineChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
])

const route = useRoute()
const deviceStore = useDeviceStore()

// 加载状态
const loading = ref(false)

// 设备信息
const device = ref<Device>()
const isDeviceOnline = computed(() => 
  device.value?.connection_status === 'online'
)

// 监控数据配置
const metrics = [
  { label: 'CPU 使用率', value: 'cpu_usage' },
  { label: '内存使用率', value: 'memory_usage' },
  { label: '网络流量', value: 'network_traffic' },
  { label: '磁盘使用率', value: 'disk_usage' }
]
const selectedMetric = ref('cpu_usage')

const timePeriods = [
  { label: '1小时', value: '1h' },
  { label: '6小时', value: '6h' },
  { label: '1天', value: '1d' },
  { label: '1周', value: '1w' }
]
const selectedPeriod = ref('1h')

// 图表配置
const chartOption = ref({
  tooltip: {
    trigger: 'axis'
  },
  grid: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    containLabel: true
  },
  xAxis: {
    type: 'category',
    boundaryGap: false,
    data: []
  },
  yAxis: {
    type: 'value'
  },
  series: [
    {
      type: 'line',
      data: [],
      smooth: true,
      areaStyle: {}
    }
  ]
})

// 告警列表
const alarms = ref<DeviceAlarm[]>([])

// 可用命令
const availableCommands = [
  { label: '重启设备', value: 'restart' },
  { label: '更新固件', value: 'update_firmware' },
  { label: '同步时间', value: 'sync_time' },
  { label: '清除缓存', value: 'clear_cache' }
]

// 命令对话框
const commandDialog = ref({
  visible: false,
  submitting: false,
  form: {
    command: '',
    parameters: {},
    parametersStr: '{}'
  },
  rules: {
    command: [
      { required: true, message: '请选择命令', trigger: 'change' }
    ]
  }
})
const commandFormRef = ref<FormInstance>()

// 获取设备信息
const fetchDeviceInfo = async () => {
  const id = route.params.id as string
  if (!id) return
  
  loading.value = true
  try {
    const data = await getDevice(id)
    device.value = data
    await fetchAlarms()
    await fetchMetricData()
  } catch (error: any) {
    ElMessage.error(error.message || '获取设备信息失败')
  } finally {
    loading.value = false
  }
}

// 获取告警列表
const fetchAlarms = async () => {
  if (!device.value) return
  
  try {
    const { items } = await getDeviceAlarms(device.value.id, {
      page: 1,
      limit: 10
    })
    alarms.value = items
  } catch (error: any) {
    ElMessage.error(error.message || '获取告警列表失败')
  }
}

// 获取监控数据
const fetchMetricData = async () => {
  if (!device.value) return
  
  try {
    const now = new Date()
    const end = now.toISOString()
    const start = new Date(now.getTime() - getPeriodMilliseconds(selectedPeriod.value))
      .toISOString()
    
    const data = await getMetricData({
      metric: selectedMetric.value,
      start_time: start,
      end_time: end,
      interval: getInterval(selectedPeriod.value)
    })
    
    updateChart(data)
  } catch (error: any) {
    ElMessage.error(error.message || '获取监控数据失败')
  }
}

// 更新图表数据
const updateChart = (data: any[]) => {
  chartOption.value.xAxis.data = data.map(d => 
    new Date(d.timestamp).toLocaleTimeString()
  )
  chartOption.value.series[0].data = data.map(d => d.value)
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

// 获取数据点间隔
const getInterval = (period: string) => {
  const map: Record<string, string> = {
    '1h': '1m',
    '6h': '5m',
    '1d': '15m',
    '1w': '1h'
  }
  return map[period] || '1m'
}

// 处理发送命令
const handleCommand = () => {
  commandDialog.value.visible = true
  commandDialog.value.form = {
    command: '',
    parameters: {},
    parametersStr: '{}'
  }
}

// 发送命令
const handleSendCommand = async () => {
  if (!commandFormRef.value || !device.value) return
  
  await commandFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      commandDialog.value.submitting = true
      
      const params = JSON.parse(commandDialog.value.form.parametersStr)
      await sendDeviceCommand(device.value.id, {
        command: commandDialog.value.form.command,
        parameters: params
      })
      
      ElMessage.success('命令已发送')
      commandDialog.value.visible = false
    } catch (error: any) {
      ElMessage.error(error.message || '发送命令失败')
    } finally {
      commandDialog.value.submitting = false
    }
  })
}

// 处理重启设备
const handleRestart = async () => {
  if (!device.value) return
  
  try {
    await ElMessageBox.confirm(
      '确认重启设备吗？',
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await sendDeviceCommand(device.value.id, {
      command: 'restart'
    })
    
    ElMessage.success('重启命令已发送')
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '发送重启命令失败')
    }
  }
}

// 处理解决告警
const handleResolveAlarm = async (alarm: DeviceAlarm) => {
  if (!device.value) return
  
  try {
    await resolveDeviceAlarm(device.value.id, alarm.id)
    ElMessage.success('告警已解决')
    await fetchAlarms()
  } catch (error: any) {
    ElMessage.error(error.message || '解决告警失败')
  }
}

// 刷新告警列表
const refreshAlarms = () => {
  fetchAlarms()
}

// 辅助函数
const getStatusType = (status: string) => {
  const types: Record<string, string> = {
    active: 'success',
    inactive: 'info',
    maintenance: 'warning',
    retired: 'danger'
  }
  return types[status] || 'info'
}

const getConnectionStatusType = (status: string) => {
  const types: Record<string, string> = {
    online: 'success',
    offline: 'danger',
    unknown: 'info'
  }
  return types[status] || 'info'
}

const getAlarmSeverityType = (severity: string) => {
  const types: Record<string, string> = {
    low: 'info',
    medium: 'warning',
    high: 'danger',
    critical: 'danger'
  }
  return types[severity] || 'info'
}

const formatDateTime = (datetime: string) => {
  if (!datetime) return '-'
  return new Date(datetime).toLocaleString()
}

// 自动刷新
let refreshTimer: number
const startAutoRefresh = () => {
  refreshTimer = window.setInterval(() => {
    if (device.value) {
      fetchDeviceInfo()
    }
  }, 30000) // 每30秒刷新一次
}

// 生命周期钩子
onMounted(() => {
  fetchDeviceInfo()
  startAutoRefresh()
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
})
</script>

<style lang="scss" scoped>
.device-detail {
  .detail-content {
    margin-top: 24px;
  }

  .detail-card {
    margin-bottom: 24px;

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .header-actions {
      display: flex;
      gap: 16px;
    }
  }

  .chart-container {
    height: 400px;
  }

  :deep(.el-descriptions__label) {
    width: 120px;
  }
}
</style>
&lt;template&gt;
  <div class="dashboard">
    <page-header
      :title="$t('common.dashboard')"
      :description="$t('common.dashboard_description')"
    />
    
    <div class="dashboard-content">
      <!-- 统计卡片 -->
      <el-row :gutter="20" class="dashboard-stats">
        <el-col :span="6" v-for="stat in stats" :key="stat.title">
          <el-card class="stat-card" :body-style="{ padding: '20px' }">
            <div class="stat-icon" :style="{ background: stat.color }">
              <el-icon>
                <component :is="stat.icon" />
              </el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-title">{{ stat.title }}</div>
              <div class="stat-value">{{ stat.value }}</div>
              <div class="stat-change" :class="{ up: stat.change > 0, down: stat.change < 0 }">
                {{ stat.change > 0 ? '+' : '' }}{{ stat.change }}%
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 图表区域 -->
      <el-row :gutter="20" class="dashboard-charts">
        <el-col :span="16">
          <el-card class="chart-card">
            <template #header>
              <div class="chart-header">
                <span>{{ $t('monitoring.device_metrics') }}</span>
                <el-select v-model="selectedMetric" size="small">
                  <el-option
                    v-for="metric in metrics"
                    :key="metric.value"
                    :label="metric.label"
                    :value="metric.value"
                  />
                </el-select>
              </div>
            </template>
            <div class="chart-container">
              <v-chart :option="chartOption" autoresize />
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="8">
          <el-card class="chart-card">
            <template #header>
              <div class="chart-header">
                <span>{{ $t('device.status_distribution') }}</span>
              </div>
            </template>
            <div class="chart-container">
              <v-chart :option="pieOption" autoresize />
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 最近活动 -->
      <el-card class="recent-activities">
        <template #header>
          <div class="activities-header">
            <span>{{ $t('common.recent_activities') }}</span>
            <el-button type="primary" link>
              {{ $t('common.view_all') }}
            </el-button>
          </div>
        </template>
        
        <el-timeline>
          <el-timeline-item
            v-for="activity in activities"
            :key="activity.id"
            :timestamp="activity.time"
            :type="activity.type"
          >
            {{ activity.content }}
          </el-timeline-item>
        </el-timeline>
      </el-card>
    </div>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { ref, onMounted } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, PieChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import PageHeader from '@/components/PageHeader'
import { useDeviceStore } from '@/stores/device'
import type { MetricData } from '@/api/monitoring'

// 注册 ECharts 组件
use([
  CanvasRenderer,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
])

const deviceStore = useDeviceStore()

// 统计数据
const stats = ref([
  {
    title: '总设备数',
    value: 0,
    change: 5.2,
    icon: 'Monitor',
    color: '#1890ff'
  },
  {
    title: '在线设备',
    value: 0,
    change: 3.1,
    icon: 'Connection',
    color: '#52c41a'
  },
  {
    title: '告警数量',
    value: 0,
    change: -2.4,
    icon: 'Warning',
    color: '#faad14'
  },
  {
    title: '今日流量',
    value: '1.2TB',
    change: 8.5,
    icon: 'DataLine',
    color: '#722ed1'
  }
])

// 指标选项
const metrics = [
  { label: 'CPU 使用率', value: 'cpu_usage' },
  { label: '内存使用率', value: 'memory_usage' },
  { label: '网络流量', value: 'network_traffic' },
  { label: '磁盘使用率', value: 'disk_usage' }
]
const selectedMetric = ref('cpu_usage')

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
      name: 'CPU Usage',
      type: 'line',
      smooth: true,
      data: []
    }
  ]
})

const pieOption = ref({
  tooltip: {
    trigger: 'item'
  },
  legend: {
    orient: 'vertical',
    left: 'left'
  },
  series: [
    {
      name: '设备状态',
      type: 'pie',
      radius: '50%',
      data: [
        { value: 235, name: '在线' },
        { value: 110, name: '离线' },
        { value: 34, name: '维护中' },
        { value: 15, name: '故障' }
      ],
      emphasis: {
        itemStyle: {
          shadowBlur: 10,
          shadowOffsetX: 0,
          shadowColor: 'rgba(0, 0, 0, 0.5)'
        }
      }
    }
  ]
})

// 最近活动
const activities = ref([
  {
    id: 1,
    content: '设备 DEV-001 触发温度过高告警',
    time: '2025-11-01 10:00:00',
    type: 'warning'
  },
  {
    id: 2,
    content: '新设备 DEV-005 已添加到系统',
    time: '2025-11-01 09:30:00',
    type: 'success'
  },
  {
    id: 3,
    content: '设备 DEV-002 开始例行维护',
    time: '2025-11-01 09:00:00',
    type: 'info'
  }
])

// 初始化数据
onMounted(async () => {
  // 获取设备统计信息
  await deviceStore.fetchDevices()
  stats.value[0].value = deviceStore.totalDevices
  stats.value[1].value = deviceStore.devices.filter(d => d.connection_status === 'online').length

  // TODO: 获取监控数据和图表数据
})
</script>

<style lang="scss" scoped>
.dashboard {
  .dashboard-content {
    margin-top: 24px;
  }

  .dashboard-stats {
    margin-bottom: 24px;

    .stat-card {
      display: flex;
      align-items: center;

      .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-right: 16px;

        :deep(.el-icon) {
          font-size: 24px;
          color: white;
        }
      }

      .stat-info {
        flex: 1;

        .stat-title {
          color: #8c8c8c;
          font-size: 14px;
        }

        .stat-value {
          font-size: 24px;
          font-weight: 600;
          margin: 4px 0;
        }

        .stat-change {
          font-size: 12px;

          &.up {
            color: #52c41a;
          }

          &.down {
            color: #ff4d4f;
          }
        }
      }
    }
  }

  .dashboard-charts {
    margin-bottom: 24px;

    .chart-card {
      .chart-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .chart-container {
        height: 300px;
      }
    }
  }

  .recent-activities {
    .activities-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
  }
}
</style>
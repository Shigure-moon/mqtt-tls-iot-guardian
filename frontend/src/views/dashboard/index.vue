<template>
  <div class="dashboard">
    <el-row :gutter="20" class="stats-row">
      <el-col :xs="24" :sm="12" :md="6" v-for="stat in stats" :key="stat.title">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-info">
              <div class="stat-title">{{ stat.title }}</div>
              <div class="stat-value">{{ stat.value }}</div>
            </div>
            <div class="stat-icon">
              <el-icon :size="48" :color="stat.color">
                <component :is="stat.icon" />
              </el-icon>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px">
      <el-col :xs="24" :sm="24" :md="16">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>设备状态统计</span>
            </div>
          </template>
          <div id="device-chart" style="height: 300px"></div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="24" :md="8">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>最近活动</span>
            </div>
          </template>
          <el-timeline>
            <el-timeline-item
              v-for="(activity, index) in activities"
              :key="index"
              :timestamp="activity.time"
            >
              {{ activity.content }}
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { Monitor, Connection, Warning, Check } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import request from '@/utils/request'

interface Device {
  id: string
  device_id: string
  name: string
  type: string
  description?: string
  status: string
  last_online_at?: string
  attributes?: Record<string, any>
}

const stats = ref([
  { title: '总设备数', value: '0', icon: Monitor, color: '#409eff' },
  { title: '在线设备', value: '0', icon: Connection, color: '#67c23a' },
  { title: '安全事件', value: '0', icon: Warning, color: '#f56c6c' },
  { title: '系统健康度', value: '100%', icon: Check, color: '#67c23a' },
])

const activities = ref<Array<{ time: string; content: string }>>([])

let chartInstance: echarts.ECharts | null = null

const loadStats = async () => {
  try {
    const devices = await request.get('/devices', {
      params: { skip: 0, limit: 1000 }
    }) as Device[]
    
    // 计算统计数据
    const total = devices.length
    const online = devices.filter(d => d.status === 'online').length
    
    // 更新统计数据
    stats.value[0].value = total.toString()
    stats.value[1].value = online.toString()
    
    // 计算系统健康度
    const healthPercent = total > 0 ? Math.round((online / total) * 100) : 100
    stats.value[3].value = `${healthPercent}%`
    
    // 加载安全事件统计
    try {
      const securityStats = await request.get('/security/stats') as any
      stats.value[2].value = securityStats.total_events?.toString() || '0'
    } catch (error) {
      console.error('Failed to load security stats:', error)
    }
    
    // 加载最近活动（审计日志）
    loadRecentActivities()
  } catch (error) {
    console.error('Failed to load stats:', error)
  }
}

const loadRecentActivities = async () => {
  try {
    const logs = await request.get('/security/audit-logs', {
      params: { skip: 0, limit: 10 }
    }) as any[]
    
    activities.value = logs.map(log => ({
      time: new Date(log.created_at).toLocaleString('zh-CN'),
      content: `${log.action}: ${log.target_type} ${log.target_id || ''}`
    }))
  } catch (error) {
    console.error('Failed to load activities:', error)
    activities.value = []
  }
}

const loadChart = async () => {
  try {
    const devices = await request.get('/devices', {
      params: { skip: 0, limit: 1000 }
    }) as Device[]
    
    // 计算设备统计
    const online = devices.filter(d => d.status === 'online').length
    const offline = devices.filter(d => d.status !== 'online').length
    
    // 更新图表
    if (chartInstance) {
      const option = {
        tooltip: {
          trigger: 'axis',
        },
        legend: {
          data: ['在线设备', '离线设备'],
        },
        xAxis: {
          type: 'category',
          data: ['当前'],
        },
        yAxis: {
          type: 'value',
        },
        series: [
          {
            name: '在线设备',
            type: 'bar',
            data: [online],
            itemStyle: { color: '#67c23a' },
          },
          {
            name: '离线设备',
            type: 'bar',
            data: [offline],
            itemStyle: { color: '#909399' },
          },
        ],
      }
      
      chartInstance.setOption(option)
    }
  } catch (error) {
    console.error('Failed to load chart data:', error)
  }
}

onMounted(() => {
  // 加载统计数据
  loadStats()
  
  // 初始化图表
  const chartDom = document.getElementById('device-chart')
  if (chartDom) {
    chartInstance = echarts.init(chartDom)
    loadChart()
  }
})

onUnmounted(() => {
  if (chartInstance) {
    chartInstance.dispose()
  }
})
</script>

<style scoped lang="scss">
.dashboard {
  .stats-row {
    margin-bottom: 20px;
  }

  .stat-card {
    .stat-content {
      display: flex;
      justify-content: space-between;
      align-items: center;

      .stat-info {
        .stat-title {
          font-size: 14px;
          color: #909399;
          margin-bottom: 10px;
        }

        .stat-value {
          font-size: 32px;
          font-weight: bold;
          color: #303133;
        }
      }

      .stat-icon {
        opacity: 0.8;
      }
    }
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
  }
}
</style>


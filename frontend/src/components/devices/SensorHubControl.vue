<template>
  <el-card class="device-control-card">
    <template #header>
      <div class="card-header">
        <span>传感器数据</span>
        <el-button link @click="refreshData" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新数据
        </el-button>
      </div>
    </template>

    <el-row :gutter="20">
      <el-col :span="12" v-if="sensorData.temperature !== undefined">
        <el-card shadow="hover" class="sensor-card">
          <div class="sensor-item">
            <div class="sensor-label">温度</div>
            <div class="sensor-value">{{ sensorData.temperature }}°C</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12" v-if="sensorData.humidity !== undefined">
        <el-card shadow="hover" class="sensor-card">
          <div class="sensor-item">
            <div class="sensor-label">湿度</div>
            <div class="sensor-value">{{ sensorData.humidity }}%</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12" v-if="sensorData.pressure !== undefined">
        <el-card shadow="hover" class="sensor-card">
          <div class="sensor-item">
            <div class="sensor-label">气压</div>
            <div class="sensor-value">{{ sensorData.pressure }} hPa</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12" v-if="sensorData.air_quality !== undefined">
        <el-card shadow="hover" class="sensor-card">
          <div class="sensor-item">
            <div class="sensor-label">空气质量</div>
            <div class="sensor-value">{{ sensorData.air_quality }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-empty v-if="Object.keys(sensorData).length === 0" description="暂无传感器数据" />
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import request from '@/utils/request'

interface Props {
  deviceId: string
}

const props = defineProps<Props>()

const loading = ref(false)
const sensorData = ref<Record<string, any>>({})

const refreshData = async () => {
  if (!props.deviceId) return
  
  loading.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'read_sensors'
    })
    
    if (response.success) {
      ElMessage.success('传感器读取命令已发送')
      // 注意：实际传感器数据需要通过MQTT订阅获取
      // 这里只是发送命令，数据应该从设备的MQTT响应中获取
    }
  } catch (error: any) {
    ElMessage.warning('获取传感器数据失败')
  } finally {
    loading.value = false
  }
}

let refreshTimer: number | null = null

onMounted(() => {
  refreshData()
  refreshTimer = window.setInterval(() => {
    refreshData()
  }, 10000) // 传感器数据每10秒刷新一次
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
})
</script>

<style scoped lang="scss">
.device-control-card {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
  }

  .sensor-card {
    margin-bottom: 20px;
    
    .sensor-item {
      .sensor-label {
        font-size: 14px;
        color: var(--el-text-color-secondary);
        margin-bottom: 10px;
      }
      
      .sensor-value {
        font-size: 24px;
        font-weight: bold;
      }
    }
  }
}
</style>


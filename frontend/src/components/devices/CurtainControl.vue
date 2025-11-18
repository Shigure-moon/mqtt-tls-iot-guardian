<template>
  <el-card class="device-control-card">
    <template #header>
      <div class="card-header">
        <span>窗帘控制</span>
        <el-button link @click="refreshStatus" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新状态
        </el-button>
      </div>
    </template>

    <!-- 位置显示 -->
    <div class="position-section">
      <el-card shadow="hover">
        <div class="position-info">
          <div class="position-label">当前位置</div>
          <div class="position-value">{{ position }}%</div>
          <el-slider
            v-model="position"
            :disabled="loading"
            :step="1"
            :min="0"
            :max="100"
            @change="handlePositionChange"
            show-input
          />
        </div>
      </el-card>
    </div>

    <!-- 控制按钮 -->
    <div class="control-section">
      <el-space direction="vertical" style="width: 100%" size="large">
        <el-button
          type="primary"
          size="large"
          :loading="opening"
          :disabled="position === 100 || loading"
          @click="handleOpen"
          style="width: 100%"
        >
          <el-icon><ArrowUp /></el-icon>
          打开
        </el-button>
        
        <el-button
          type="warning"
          size="large"
          :loading="closing"
          :disabled="position === 0 || loading"
          @click="handleClose"
          style="width: 100%"
        >
          <el-icon><ArrowDown /></el-icon>
          关闭
        </el-button>
        
        <el-button
          type="info"
          size="large"
          :loading="stopping"
          :disabled="loading"
          @click="handleStop"
          style="width: 100%"
        >
          <el-icon><VideoPause /></el-icon>
          停止
        </el-button>
      </el-space>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, ArrowUp, ArrowDown, VideoPause } from '@element-plus/icons-vue'
import request from '@/utils/request'

interface Props {
  deviceId: string
}

const props = defineProps<Props>()

const loading = ref(false)
const opening = ref(false)
const closing = ref(false)
const stopping = ref(false)

const position = ref(0)

const refreshStatus = async () => {
  if (!props.deviceId) return
  
  loading.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'get_status'
    })
    
    if (response.success) {
      ElMessage.success('状态查询命令已发送')
    }
  } catch (error: any) {
    ElMessage.warning('刷新状态失败')
  } finally {
    loading.value = false
  }
}

const handleOpen = async () => {
  opening.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'open'
    })
    if (response.success) {
      ElMessage.success('窗帘正在打开')
    }
  } catch (error: any) {
    ElMessage.error('打开失败')
  } finally {
    opening.value = false
  }
}

const handleClose = async () => {
  closing.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'close'
    })
    if (response.success) {
      ElMessage.success('窗帘正在关闭')
    }
  } catch (error: any) {
    ElMessage.error('关闭失败')
  } finally {
    closing.value = false
  }
}

const handleStop = async () => {
  stopping.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'stop'
    })
    if (response.success) {
      ElMessage.success('窗帘已停止')
    }
  } catch (error: any) {
    ElMessage.error('停止失败')
  } finally {
    stopping.value = false
  }
}

const handlePositionChange = async (value: number) => {
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'set_position',
      payload: { position: value }
    })
    if (response.success) {
      ElMessage.success(`位置已设置为 ${value}%`)
    }
  } catch (error: any) {
    ElMessage.error('设置位置失败')
  }
}

let refreshTimer: number | null = null

onMounted(() => {
  refreshStatus()
  refreshTimer = window.setInterval(() => {
    refreshStatus()
  }, 30000)
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

  .position-section {
    margin-bottom: 20px;
    
    .position-info {
      .position-label {
        font-size: 14px;
        color: var(--el-text-color-secondary);
        margin-bottom: 10px;
      }
      
      .position-value {
        font-size: 24px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 20px;
      }
    }
  }

  .control-section {
    margin: 20px 0;
  }
}
</style>


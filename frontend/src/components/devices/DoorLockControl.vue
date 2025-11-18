<template>
  <el-card class="device-control-card">
    <template #header>
      <div class="card-header">
        <span>门锁控制</span>
        <el-button link @click="refreshStatus" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新状态
        </el-button>
      </div>
    </template>

    <!-- 状态显示 -->
    <div class="status-section">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card shadow="hover" class="status-card">
            <div class="status-item">
              <div class="status-label">锁状态</div>
              <div class="status-value">
                <el-tag :type="lockStatus === 'locked' ? 'success' : 'warning'" size="large">
                  {{ lockStatus === 'locked' ? '已锁定' : '已解锁' }}
                </el-tag>
              </div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card shadow="hover" class="status-card">
            <div class="status-item">
              <div class="status-label">电池电量</div>
              <div class="status-value">
                <el-progress
                  :percentage="batteryLevel"
                  :color="getBatteryColor(batteryLevel)"
                  :stroke-width="20"
                  :format="(percentage) => `${percentage}%`"
                />
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 控制按钮 -->
    <div class="control-section">
      <el-space direction="vertical" style="width: 100%" size="large">
        <el-button
          type="success"
          size="large"
          :loading="locking"
          :disabled="lockStatus === 'locked' || loading"
          @click="handleLock"
          style="width: 100%"
        >
          <el-icon><Lock /></el-icon>
          锁定
        </el-button>
        
        <el-button
          type="warning"
          size="large"
          :loading="unlocking"
          :disabled="lockStatus === 'unlocked' || loading"
          @click="handleUnlock"
          style="width: 100%"
        >
          <el-icon><Unlock /></el-icon>
          解锁
        </el-button>
      </el-space>
    </div>

    <!-- 操作历史 -->
    <el-divider />
    <div class="history-section">
      <div class="section-title">最近操作</div>
      <el-timeline>
        <el-timeline-item
          v-for="(record, index) in operationHistory"
          :key="index"
          :timestamp="formatTime(record.timestamp)"
          :type="record.type === 'lock' ? 'success' : 'warning'"
        >
          {{ record.action }}
        </el-timeline-item>
        <el-timeline-item v-if="operationHistory.length === 0">
          <el-empty description="暂无操作记录" :image-size="80" />
        </el-timeline-item>
      </el-timeline>
    </div>

    <!-- 高级设置 -->
    <el-divider />
    <el-collapse>
      <el-collapse-item title="高级设置" name="advanced">
        <el-form :model="settings" label-width="120px">
          <el-form-item label="自动锁定">
            <el-switch v-model="settings.autoLock" @change="handleSettingChange" />
            <div class="form-tip">设备在指定时间后自动锁定</div>
          </el-form-item>
          <el-form-item label="自动锁定时间（秒）" v-if="settings.autoLock">
            <el-input-number
              v-model="settings.autoLockDelay"
              :min="10"
              :max="3600"
              :step="10"
              @change="handleSettingChange"
            />
          </el-form-item>
          <el-form-item label="低电量提醒">
            <el-switch v-model="settings.lowBatteryAlert" @change="handleSettingChange" />
            <div class="form-tip">电池电量低于20%时发送提醒</div>
          </el-form-item>
        </el-form>
      </el-collapse-item>
    </el-collapse>
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Lock, Unlock, Refresh } from '@element-plus/icons-vue'
import request from '@/utils/request'

interface Props {
  deviceId: string
  deviceType?: string
}

const props = defineProps<Props>()

const loading = ref(false)
const locking = ref(false)
const unlocking = ref(false)

const lockStatus = ref<'locked' | 'unlocked' | 'unknown'>('unknown')
const batteryLevel = ref(100)

const settings = ref({
  autoLock: false,
  autoLockDelay: 30,
  lowBatteryAlert: true
})

interface OperationRecord {
  action: string
  type: 'lock' | 'unlock'
  timestamp: string
  success: boolean
}

const operationHistory = ref<OperationRecord[]>([])

// 获取电池颜色
const getBatteryColor = (level: number) => {
  if (level > 50) return '#67c23a'
  if (level > 20) return '#e6a23c'
  return '#f56c6c'
}

// 格式化时间
const formatTime = (time: string) => {
  return new Date(time).toLocaleString('zh-CN')
}

// 刷新状态
const refreshStatus = async () => {
  if (!props.deviceId) return
  
  loading.value = true
  try {
    // 通过MQTT获取设备状态
    // 注意：这里需要设备的device_id（字符串），而不是UUID
    // 如果传入的是UUID，需要先获取设备的device_id
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'get_status'
    })
    
    // 注意：设备状态需要通过MQTT订阅获取，这里只是发送命令
    // 实际状态应该从设备的MQTT响应中获取
    ElMessage.success('状态查询命令已发送')
  } catch (error: any) {
    console.error('刷新状态失败:', error)
    ElMessage.warning('刷新状态失败，请检查设备连接')
  } finally {
    loading.value = false
  }
}

// 锁定
const handleLock = async () => {
  if (!props.deviceId) return
  
  locking.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'lock'
    })
    
    if (response.success) {
      lockStatus.value = 'locked'
      operationHistory.value.unshift({
        action: '锁定成功',
        type: 'lock',
        timestamp: new Date().toISOString(),
        success: true
      })
      ElMessage.success('门锁已锁定')
    }
  } catch (error: any) {
    ElMessage.error('锁定失败: ' + (error.response?.data?.detail || error.message))
    operationHistory.value.unshift({
      action: '锁定失败',
      type: 'lock',
      timestamp: new Date().toISOString(),
      success: false
    })
  } finally {
    locking.value = false
  }
}

// 解锁
const handleUnlock = async () => {
  if (!props.deviceId) return
  
  unlocking.value = true
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'unlock'
    })
    
    if (response.success) {
      lockStatus.value = 'unlocked'
      operationHistory.value.unshift({
        action: '解锁成功',
        type: 'unlock',
        timestamp: new Date().toISOString(),
        success: true
      })
      ElMessage.success('门锁已解锁')
    }
  } catch (error: any) {
    ElMessage.error('解锁失败: ' + (error.response?.data?.detail || error.message))
    operationHistory.value.unshift({
      action: '解锁失败',
      type: 'unlock',
      timestamp: new Date().toISOString(),
      success: false
    })
  } finally {
    unlocking.value = false
  }
}

// 设置变更
const handleSettingChange = async () => {
  if (!props.deviceId) return
  
  try {
    const response = await request.post(`/devices/${props.deviceId}/command`, {
      command: 'update_settings',
      payload: settings.value
    })
    
    if (response.success) {
      ElMessage.success('设置已保存')
    }
  } catch (error: any) {
    ElMessage.error('保存设置失败')
  }
}

// 自动刷新定时器
let refreshTimer: number | null = null

onMounted(() => {
  refreshStatus()
  // 每30秒自动刷新一次状态
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

  .status-section {
    margin-bottom: 20px;
    
    .status-card {
      .status-item {
        .status-label {
          font-size: 14px;
          color: var(--el-text-color-secondary);
          margin-bottom: 10px;
        }
        
        .status-value {
          font-size: 18px;
          font-weight: bold;
        }
      }
    }
  }

  .control-section {
    margin: 20px 0;
  }

  .history-section {
    .section-title {
      font-size: 16px;
      font-weight: bold;
      margin-bottom: 15px;
    }
  }

  .form-tip {
    font-size: 12px;
    color: var(--el-text-color-secondary);
    margin-top: 4px;
  }
}
</style>


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
        <span>设备统计</span>
      </template>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="总消息数">0</el-descriptions-item>
        <el-descriptions-item label="在线时长">0小时</el-descriptions-item>
        <el-descriptions-item label="错误次数">0</el-descriptions-item>
        <el-descriptions-item label="最后活动时间">-</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
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

const route = useRoute()

const loading = ref(false)
const deviceInfo = ref<Device | null>(null)

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
    const response = await request.get<Device>(`/devices/${deviceId}`)
    deviceInfo.value = response
  } catch (error) {
    ElMessage.error('获取设备详情失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchDeviceDetail()
})
</script>

<style scoped lang="scss">
.device-detail {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
  }
}
</style>


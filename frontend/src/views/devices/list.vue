<template>
  <div class="devices-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>设备列表</span>
          <div class="header-actions">
            <el-button @click="handleRefresh" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新状态
            </el-button>
          <el-button type="primary" @click="handleAdd">
            <el-icon><Plus /></el-icon>
            添加设备
          </el-button>
          </div>
        </div>
      </template>

      <el-table
        v-loading="loading"
        :data="deviceList"
        style="width: 100%"
      >
        <el-table-column prop="device_id" label="设备ID" width="180" />
        <el-table-column prop="name" label="设备名称" />
        <el-table-column prop="type" label="设备类型" width="120" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag 
              :color="getStatusColor(row.status)" 
              effect="dark"
              :style="{ borderColor: getStatusColor(row.status) }"
            >
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="last_online_at" label="最后在线时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.last_online_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleView(row)">
              查看
            </el-button>
            <el-button link type="primary" @click="handleEdit(row)">
              编辑
            </el-button>
            <el-button link type="danger" @click="handleDelete(row)">
              删除
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
        @size-change="fetchDevices"
        @current-change="fetchDevices"
      />
    </el-card>

    <!-- 添加设备对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="添加设备并生成烧录代码"
      width="700px"
      @close="resetForm"
    >
      <el-form
        ref="deviceFormRef"
        :model="deviceForm"
        :rules="deviceFormRules"
        label-width="100px"
      >
        <el-form-item label="设备ID" prop="device_id">
          <el-input
            v-model="deviceForm.device_id"
            placeholder="请输入设备ID（唯一标识符）"
          />
          <div class="form-tip">
            设备唯一标识符，例如：esp8266-001
          </div>
        </el-form-item>

        <el-form-item label="设备名称" prop="name">
          <el-input
            v-model="deviceForm.name"
            placeholder="请输入设备名称"
          />
        </el-form-item>

        <el-form-item label="设备类型" prop="type">
          <el-select
            v-model="deviceForm.type"
            placeholder="请选择设备类型"
            style="width: 100%"
          >
            <el-option label="ESP8266" value="ESP8266" />
            <el-option label="ESP32" value="ESP32" />
            <el-option label="树莓派" value="RaspberryPi" />
            <el-option label="其他" value="Other" />
          </el-select>
        </el-form-item>

        <el-form-item label="设备描述" prop="description">
          <el-input
            v-model="deviceForm.description"
            type="textarea"
            :rows="3"
            placeholder="请输入设备描述"
          />
        </el-form-item>

        <el-divider>WiFi配置</el-divider>

        <el-form-item label="WiFi SSID" prop="wifi_ssid">
          <el-input
            v-model="deviceForm.wifi_ssid"
            placeholder="请输入WiFi网络名称"
          />
        </el-form-item>

        <el-form-item label="WiFi密码" prop="wifi_password">
          <el-input
            v-model="deviceForm.wifi_password"
            type="password"
            placeholder="请输入WiFi密码"
            show-password
          />
        </el-form-item>

        <el-form-item label="MQTT服务器" prop="mqtt_server">
          <el-input
            v-model="deviceForm.mqtt_server"
            placeholder="请输入MQTT服务器地址"
          />
          <div class="form-tip">
            填写服务器IP地址（如192.168.1.8），设备需能访问该地址
          </div>
        </el-form-item>

        <el-divider>证书配置</el-divider>

        <el-form-item>
          <el-checkbox v-model="deviceForm.generate_cert">
            自动生成TLS证书
          </el-checkbox>
        </el-form-item>

        <el-form-item v-if="deviceForm.generate_cert" label="证书有效期" prop="validity_days">
          <el-input-number
            v-model="deviceForm.validity_days"
            :min="30"
            :max="3650"
            :precision="0"
            style="width: 100%"
          />
          <div class="form-tip">
            证书有效期（天），建议365天
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="submitForm">
          {{ submitLoading ? '处理中...' : '添加并生成代码' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 烧录代码生成成功对话框 -->
    <el-dialog
      v-model="codeDialogVisible"
      title="设备添加成功"
      width="800px"
    >
      <div style="margin-bottom: 20px;">
        <el-alert
          type="success"
          title="设备已成功添加并生成了烧录代码"
          :closable="false"
        />
      </div>

      <el-card>
        <template #header>
          <span>下一步操作</span>
        </template>
        <ol style="line-height: 2;">
          <li>下载生成的Arduino代码文件</li>
          <li>在Arduino IDE中打开下载的文件</li>
          <li>选择ESP8266开发板（工具 → 开发板 → ESP8266）</li>
          <li>将设备连接到电脑</li>
          <li>选择串口（工具 → 端口）</li>
          <li>点击"上传"按钮烧录代码</li>
        </ol>
      </el-card>

      <template #footer>
        <el-button @click="codeDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="downloadCode">
          <el-icon><Download /></el-icon>
          下载烧录代码
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Download, Refresh } from '@element-plus/icons-vue'
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

const router = useRouter()

const loading = ref(false)
const deviceList = ref<Device[]>([])

const pagination = ref({
  page: 1,
  size: 20,
  total: 0,
})

// 对话框相关
const dialogVisible = ref(false)
const submitLoading = ref(false)
const deviceFormRef = ref<FormInstance>()
const codeDialogVisible = ref(false)
const generatedDeviceId = ref('')

const deviceForm = ref({
  device_id: '',
  name: '',
  type: '',
  description: '',
  wifi_ssid: '',
  wifi_password: '',
  mqtt_server: '192.168.1.8',
  generate_cert: true,
  validity_days: 365,
})

const deviceFormRules: FormRules = {
  device_id: [
    { required: true, message: '请输入设备ID', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_-]+$/, message: '设备ID只能包含字母、数字、下划线和连字符', trigger: 'blur' },
  ],
  name: [
    { required: true, message: '请输入设备名称', trigger: 'blur' },
  ],
  type: [
    { required: true, message: '请选择设备类型', trigger: 'change' },
  ],
  wifi_ssid: [
    { required: true, message: '请输入WiFi SSID', trigger: 'blur' },
  ],
  wifi_password: [
    { required: true, message: '请输入WiFi密码', trigger: 'blur' },
  ],
  mqtt_server: [
    { required: true, message: '请输入MQTT服务器地址', trigger: 'blur' },
  ],
  validity_days: [
    { required: true, message: '请输入证书有效期', trigger: 'blur' },
  ],
}

const getStatusColor = (status: string) => {
  const colorMap: Record<string, string> = {
    online: '#409eff',      // 蓝色
    offline: '#909399',     // 灰色
    active: '#409eff',      // 蓝色
    inactive: '#909399',    // 灰色
    disabled: '#f56c6c',    // 红色
    maintenance: '#e6a23c',  // 橙色
  }
  return colorMap[status] || '#909399'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    online: '在线',
    offline: '离线',
    active: '在线',
    inactive: '离线',
    disabled: '已禁用',
    maintenance: '维护中',
  }
  return statusMap[status] || status
}

const formatTime = (time?: string) => {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

const fetchDevices = async (showMessage = false) => {
  loading.value = true
  try {
    const response = await request.get('/devices', {
      params: {
        skip: (pagination.value.page - 1) * pagination.value.size,
        limit: pagination.value.size,
      },
    }) as Device[]
    deviceList.value = Array.isArray(response) ? response : []
    pagination.value.total = deviceList.value.length
    if (showMessage) {
      ElMessage.success('设备状态已刷新')
    }
  } catch (error) {
    ElMessage.error('获取设备列表失败')
  } finally {
    loading.value = false
  }
}

const handleRefresh = () => {
  fetchDevices(true)
}

const handleAdd = () => {
  dialogVisible.value = true
}

const handleView = (device: Device) => {
  router.push(`/devices/${device.id}`)
}

const handleEdit = (device: Device) => {
  // 编辑功能暂时不实现
  ElMessage.info('编辑功能开发中')
}

const handleDelete = async (device: Device) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除设备 "${device.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    
    await request.delete(`/devices/${device.id}`)
    ElMessage.success('删除成功')
    fetchDevices()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const resetForm = () => {
  deviceFormRef.value?.resetFields()
  deviceForm.value = {
    device_id: '',
    name: '',
    type: '',
    description: '',
    wifi_ssid: '',
    wifi_password: '',
    mqtt_server: '192.168.1.8',
    generate_cert: true,
    validity_days: 365,
  }
}

const submitForm = async () => {
  if (!deviceFormRef.value) return
  
  try {
    await deviceFormRef.value.validate()
    submitLoading.value = true
    
    // 1. 创建设备
    const deviceResponse = await request.post('/devices', {
      device_id: deviceForm.value.device_id,
      name: deviceForm.value.name,
      type: deviceForm.value.type,
      description: deviceForm.value.description || undefined,
    }) as Device
    
    generatedDeviceId.value = deviceForm.value.device_id
    
    // 2. 如果选择了生成证书，则生成证书
    let caCert = ''
    if (deviceForm.value.generate_cert) {
      try {
        const certResponse = await request.post(`/certificates/client/generate/${deviceResponse.device_id}`, {
          common_name: deviceResponse.name,
          validity_days: deviceForm.value.validity_days,
        })
        caCert = certResponse.ca_cert
      } catch (error) {
        console.error('Certificate generation failed:', error)
        ElMessage.warning('证书生成失败，但设备已创建成功')
      }
    }
    
    // 3. 生成烧录代码（代码会保存在后端）
    await request.post(`/devices/${deviceResponse.device_id}/firmware/generate`, {
      wifi_ssid: deviceForm.value.wifi_ssid,
      wifi_password: deviceForm.value.wifi_password,
      mqtt_server: deviceForm.value.mqtt_server,
      ca_cert: caCert || undefined,
    })
    
    dialogVisible.value = false
    codeDialogVisible.value = true
    ElMessage.success('设备添加成功')
    fetchDevices()
  } catch (error) {
    console.error('Submit error:', error)
  } finally {
    submitLoading.value = false
  }
}

const downloadCode = async () => {
  try {
    const response = await request.get(`/devices/${generatedDeviceId.value}/firmware/download`, {
      responseType: 'blob',
    })
    
    // 创建下载链接
    const blob = new Blob([response as any], { type: 'application/octet-stream' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${generatedDeviceId.value}.ino`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('代码下载成功')
    codeDialogVisible.value = false
  } catch (error) {
    ElMessage.error('下载失败')
  }
}

onMounted(() => {
  fetchDevices()
})
</script>

<style scoped lang="scss">
.devices-page {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
  }

  .header-actions {
    display: flex;
    gap: 10px;
    align-items: center;
  }

  .form-tip {
    font-size: 12px;
    color: var(--el-text-color-secondary);
    margin-top: 4px;
  }

  ol {
    padding-left: 20px;
  }

  ol li {
    margin: 8px 0;
  }

  :deep(.el-tag) {
    border-color: transparent !important;
  }
}
</style>

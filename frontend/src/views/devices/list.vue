&lt;template&gt;
  <div class="device-list">
    <page-header
      :title="$t('device.devices')"
      :description="$t('device.devices_description')"
    />
    
    <div class="device-content">
      <!-- 搜索和操作栏 -->
      <div class="action-bar">
        <div class="search-box">
          <el-input
            v-model="searchQuery"
            :placeholder="$t('common.search')"
            prefix-icon="Search"
            clearable
            @input="handleSearch"
          >
            <template #append>
              <el-button @click="showAdvancedSearch = true">
                {{ $t('common.advanced_search') }}
              </el-button>
            </template>
          </el-input>
        </div>
        
        <div class="action-buttons">
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>
            {{ $t('device.add_device') }}
          </el-button>
          <el-button @click="handleRefresh">
            <el-icon><Refresh /></el-icon>
            {{ $t('common.refresh') }}
          </el-button>
        </div>
      </div>

      <!-- 设备表格 -->
      <el-table
        v-loading="loading"
        :data="devices"
        border
        style="width: 100%"
      >
        <el-table-column type="selection" width="55" />
        
        <el-table-column
          prop="name"
          :label="$t('device.device_name')"
          min-width="150"
        >
          <template #default="{ row }">
            <router-link
              :to="{ name: 'DeviceDetail', params: { id: row.id }}"
              class="device-name-link"
            >
              {{ row.name }}
            </router-link>
          </template>
        </el-table-column>
        
        <el-table-column
          prop="model"
          :label="$t('device.device_model')"
          min-width="120"
        />
        
        <el-table-column
          prop="serial_number"
          :label="$t('device.serial_number')"
          min-width="150"
        />
        
        <el-table-column
          prop="status"
          :label="$t('device.status')"
          width="100"
        >
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ $t(`device.status_types.${row.status}`) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column
          prop="connection_status"
          :label="$t('device.connection_status')"
          width="120"
        >
          <template #default="{ row }">
            <el-tag :type="getConnectionStatusType(row.connection_status)">
              {{ $t(`device.connection_status_types.${row.connection_status}`) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column
          prop="last_online_at"
          :label="$t('device.last_online')"
          width="180"
        >
          <template #default="{ row }">
            {{ formatDateTime(row.last_online_at) }}
          </template>
        </el-table-column>
        
        <el-table-column
          :label="$t('common.actions')"
          width="200"
          fixed="right"
        >
          <template #default="{ row }">
            <el-button
              type="primary"
              link
              @click="handleEdit(row)"
            >
              {{ $t('common.edit') }}
            </el-button>
            <el-button
              type="primary"
              link
              @click="handleMonitor(row)"
            >
              {{ $t('device.monitor') }}
            </el-button>
            <el-button
              type="danger"
              link
              @click="handleDelete(row)"
            >
              {{ $t('common.delete') }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </div>

    <!-- 创建/编辑设备对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? $t('device.edit_device') : $t('device.add_device')"
      width="600px"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item :label="$t('device.device_name')" prop="name">
          <el-input v-model="formData.name" />
        </el-form-item>
        
        <el-form-item :label="$t('device.device_model')" prop="model">
          <el-input v-model="formData.model" />
        </el-form-item>
        
        <el-form-item :label="$t('device.serial_number')" prop="serial_number">
          <el-input v-model="formData.serial_number" />
        </el-form-item>
        
        <el-form-item :label="$t('device.description')" prop="description">
          <el-input
            v-model="formData.description"
            type="textarea"
            :rows="3"
          />
        </el-form-item>
        
        <el-form-item :label="$t('device.metadata')" prop="metadata">
          <el-input
            v-model="metadataStr"
            type="textarea"
            :rows="5"
            :placeholder="$t('device.metadata_placeholder')"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">
          {{ $t('common.cancel') }}
        </el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ $t('common.confirm') }}
        </el-button>
      </template>
    </el-dialog>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'
import PageHeader from '@/components/PageHeader'
import { useDeviceStore } from '@/stores/device'
import type { Device, DeviceCreate } from '@/types/device'
import { createDevice, updateDevice, deleteDevice } from '@/api/device'

const deviceStore = useDeviceStore()

// 表格数据和加载状态
const loading = ref(false)
const devices = computed(() => deviceStore.devices)
const total = computed(() => deviceStore.totalDevices)

// 分页
const currentPage = ref(1)
const pageSize = ref(10)

// 搜索
const searchQuery = ref('')
const showAdvancedSearch = ref(false)

// 表单对话框
const dialogVisible = ref(false)
const isEdit = ref(false)
const submitting = ref(false)
const formRef = ref<FormInstance>()

const formData = ref<DeviceCreate>({
  name: '',
  model: '',
  serial_number: '',
  description: '',
  metadata: {}
})

// 表单验证规则
const rules = {
  name: [
    { required: true, message: '请输入设备名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  model: [
    { required: true, message: '请输入设备型号', trigger: 'blur' }
  ],
  serial_number: [
    { required: true, message: '请输入序列号', trigger: 'blur' }
  ]
}

// metadata JSON 字符串
const metadataStr = computed({
  get: () => JSON.stringify(formData.value.metadata || {}, null, 2),
  set: (val) => {
    try {
      formData.value.metadata = JSON.parse(val)
    } catch (e) {
      // 解析失败时不更新值
    }
  }
})

// 获取设备列表
const fetchDevices = async () => {
  loading.value = true
  try {
    await deviceStore.fetchDevices({
      page: currentPage.value,
      limit: pageSize.value,
      search: searchQuery.value
    })
  } finally {
    loading.value = false
  }
}

// 状态标签类型
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

// 格式化日期时间
const formatDateTime = (datetime: string) => {
  if (!datetime) return '-'
  return new Date(datetime).toLocaleString()
}

// 处理创建设备
const handleCreate = () => {
  isEdit.value = false
  formData.value = {
    name: '',
    model: '',
    serial_number: '',
    description: '',
    metadata: {}
  }
  dialogVisible.value = true
}

// 处理编辑设备
const handleEdit = (row: Device) => {
  isEdit.value = true
  formData.value = {
    name: row.name,
    model: row.model,
    serial_number: row.serial_number,
    description: row.description || '',
    metadata: row.metadata || {}
  }
  dialogVisible.value = true
}

// 处理删除设备
const handleDelete = async (row: Device) => {
  try {
    await ElMessageBox.confirm(
      '确认删除该设备吗？此操作不可恢复。',
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteDevice(row.id)
    ElMessage.success('删除成功')
    await fetchDevices()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 处理监控
const handleMonitor = (row: Device) => {
  // TODO: 跳转到设备监控页面
}

// 处理表单提交
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      submitting.value = true
      if (isEdit.value) {
        // TODO: 处理编辑逻辑
      } else {
        await createDevice(formData.value)
        ElMessage.success('创建成功')
      }
      
      dialogVisible.value = false
      await fetchDevices()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      submitting.value = false
    }
  })
}

// 处理搜索
const handleSearch = () => {
  currentPage.value = 1
  fetchDevices()
}

// 处理刷新
const handleRefresh = () => {
  fetchDevices()
}

// 处理分页
const handleSizeChange = (val: number) => {
  pageSize.value = val
  fetchDevices()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  fetchDevices()
}

// 初始化
onMounted(() => {
  fetchDevices()
})
</script>

<style lang="scss" scoped>
.device-list {
  .device-content {
    margin-top: 24px;
  }

  .action-bar {
    display: flex;
    justify-content: space-between;
    margin-bottom: 16px;

    .search-box {
      width: 400px;
    }
  }

  .device-name-link {
    color: #1890ff;
    text-decoration: none;
    
    &:hover {
      text-decoration: underline;
    }
  }

  .pagination {
    margin-top: 16px;
    display: flex;
    justify-content: flex-end;
  }
}
</style>
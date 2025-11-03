&lt;template&gt;
  <div class="monitoring-dashboard">
    <page-header
      :title="currentDashboard?.name || $t('monitoring.dashboards')"
      :description="currentDashboard?.description"
    >
      <template #extra>
        <el-space>
          <el-select
            v-model="currentDashboardId"
            style="width: 200px"
            :placeholder="$t('monitoring.select_dashboard')"
          >
            <el-option
              v-for="dash in dashboards"
              :key="dash.id"
              :label="dash.name"
              :value="dash.id"
            />
          </el-select>
          
          <auth-guard permission="monitoring:dashboard:manage">
            <el-button type="primary" @click="handleCreateDashboard">
              {{ $t('monitoring.create_dashboard') }}
            </el-button>
          </auth-guard>
          
          <el-button-group v-if="currentDashboard">
            <auth-guard permission="monitoring:dashboard:edit">
              <el-button @click="handleEditDashboard">
                {{ $t('common.edit') }}
              </el-button>
            </auth-guard>
            <el-button @click="handleRefresh">
              {{ $t('common.refresh') }}
            </el-button>
          </el-button-group>
        </el-space>
      </template>
    </page-header>

    <div class="dashboard-content">
      <page-loading :loading="loading" />
      
      <template v-if="currentDashboard">
        <!-- 使用Grid Layout实现可拖拽的仪表板布局 -->
        <grid-layout
          v-model:layout="layout"
          :col-num="12"
          :row-height="30"
          :is-draggable="isEditing"
          :is-resizable="isEditing"
          :margin="[10, 10]"
          :use-css-transforms="true"
        >
          <grid-item
            v-for="panel in currentDashboard.layout"
            :key="panel.id"
            :x="panel.position.x"
            :y="panel.position.y"
            :w="panel.position.w"
            :h="panel.position.h"
            :i="panel.id"
            :draggable="isEditing"
            :resizable="isEditing"
          >
            <el-card class="panel-card" :body-style="{ height: '100%' }">
              <template #header>
                <div class="panel-header">
                  <span>{{ panel.title }}</span>
                  <el-space v-if="isEditing">
                    <el-button
                      type="primary"
                      link
                      @click="handleEditPanel(panel)"
                    >
                      {{ $t('common.edit') }}
                    </el-button>
                    <el-button
                      type="danger"
                      link
                      @click="handleDeletePanel(panel)"
                    >
                      {{ $t('common.delete') }}
                    </el-button>
                  </el-space>
                </div>
              </template>
              
              <div class="panel-content">
                <component
                  :is="getPanelComponent(panel.type)"
                  :panel="panel"
                  :data="panelData[panel.id]"
                />
              </div>
            </el-card>
          </grid-item>
        </grid-layout>

        <!-- 编辑模式下的添加面板按钮 -->
        <div v-if="isEditing" class="add-panel">
          <el-button type="dashed" @click="handleAddPanel">
            <el-icon><Plus /></el-icon>
            {{ $t('monitoring.add_panel') }}
          </el-button>
        </div>
      </template>

      <!-- 空状态 -->
      <el-empty
        v-else
        :description="$t('monitoring.no_dashboard_selected')"
      >
        <template #extra>
          <auth-guard permission="monitoring:dashboard:manage">
            <el-button type="primary" @click="handleCreateDashboard">
              {{ $t('monitoring.create_first_dashboard') }}
            </el-button>
          </auth-guard>
        </template>
      </el-empty>
    </div>

    <!-- 仪表板编辑对话框 -->
    <el-dialog
      v-model="dashboardDialog.visible"
      :title="dashboardDialog.isEdit ? $t('monitoring.edit_dashboard') : $t('monitoring.create_dashboard')"
      width="500px"
    >
      <el-form
        ref="dashboardFormRef"
        :model="dashboardDialog.form"
        :rules="dashboardDialog.rules"
        label-width="100px"
      >
        <el-form-item :label="$t('common.name')" prop="name">
          <el-input v-model="dashboardDialog.form.name" />
        </el-form-item>
        
        <el-form-item :label="$t('common.description')" prop="description">
          <el-input
            v-model="dashboardDialog.form.description"
            type="textarea"
            :rows="3"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dashboardDialog.visible = false">
          {{ $t('common.cancel') }}
        </el-button>
        <el-button
          type="primary"
          :loading="dashboardDialog.submitting"
          @click="handleDashboardSubmit"
        >
          {{ $t('common.confirm') }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 面板编辑对话框 -->
    <el-dialog
      v-model="panelDialog.visible"
      :title="panelDialog.isEdit ? $t('monitoring.edit_panel') : $t('monitoring.add_panel')"
      width="800px"
    >
      <el-form
        ref="panelFormRef"
        :model="panelDialog.form"
        :rules="panelDialog.rules"
        label-width="100px"
      >
        <el-form-item :label="$t('common.title')" prop="title">
          <el-input v-model="panelDialog.form.title" />
        </el-form-item>
        
        <el-form-item :label="$t('monitoring.panel_type')" prop="type">
          <el-select v-model="panelDialog.form.type" style="width: 100%">
            <el-option
              v-for="type in panelTypes"
              :key="type.value"
              :label="type.label"
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item :label="$t('monitoring.metric')" prop="query.metric">
          <el-select
            v-model="panelDialog.form.query.metric"
            style="width: 100%"
          >
            <el-option
              v-for="metric in availableMetrics"
              :key="metric.value"
              :label="metric.label"
              :value="metric.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item :label="$t('monitoring.aggregation')" prop="query.aggregation">
          <el-select
            v-model="panelDialog.form.query.aggregation"
            style="width: 100%"
          >
            <el-option
              v-for="agg in aggregations"
              :key="agg.value"
              :label="agg.label"
              :value="agg.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item
          :label="$t('monitoring.interval')"
          prop="query.interval"
        >
          <el-input-number
            v-model="panelDialog.form.query.interval"
            :min="1"
            :max="60"
          />
          <el-select
            v-model="panelDialog.form.query.intervalUnit"
            style="width: 100px; margin-left: 10px"
          >
            <el-option
              v-for="unit in intervalUnits"
              :key="unit.value"
              :label="unit.label"
              :value="unit.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item :label="$t('monitoring.options')" prop="options">
          <el-input
            v-model="panelDialog.form.optionsStr"
            type="textarea"
            :rows="5"
            :placeholder="$t('monitoring.options_placeholder')"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="panelDialog.visible = false">
          {{ $t('common.cancel') }}
        </el-button>
        <el-button
          type="primary"
          :loading="panelDialog.submitting"
          @click="handlePanelSubmit"
        >
          {{ $t('common.confirm') }}
        </el-button>
      </template>
    </el-dialog>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'
import { GridLayout, GridItem } from 'vue-grid-layout'
import PageHeader from '@/components/PageHeader'
import PageLoading from '@/components/PageLoading'
import AuthGuard from '@/components/AuthGuard'
import LineChartPanel from './panels/LineChartPanel.vue'
import BarChartPanel from './panels/BarChartPanel.vue'
import GaugePanel from './panels/GaugePanel.vue'
import StatPanel from './panels/StatPanel.vue'
import TablePanel from './panels/TablePanel.vue'
import type { Dashboard, DashboardPanel } from '@/types/monitoring'
import {
  getDashboards,
  getDashboard,
  createDashboard,
  updateDashboard,
  deleteDashboard
} from '@/api/monitoring'
import { getMetricData } from '@/api/monitoring'

// 状态
const loading = ref(false)
const isEditing = ref(false)
const dashboards = ref<Dashboard[]>([])
const currentDashboardId = ref<string>('')
const currentDashboard = ref<Dashboard>()
const panelData = ref<Record<string, any>>({})
const layout = ref([])

// 面板类型配置
const panelTypes = [
  { label: '折线图', value: 'line' },
  { label: '柱状图', value: 'bar' },
  { label: '仪表盘', value: 'gauge' },
  { label: '数值', value: 'stat' },
  { label: '表格', value: 'table' }
]

const aggregations = [
  { label: '平均值', value: 'avg' },
  { label: '最大值', value: 'max' },
  { label: '最小值', value: 'min' },
  { label: '总和', value: 'sum' },
  { label: '计数', value: 'count' }
]

const intervalUnits = [
  { label: '秒', value: 's' },
  { label: '分钟', value: 'm' },
  { label: '小时', value: 'h' }
]

// 可用指标
const availableMetrics = [
  { label: 'CPU使用率', value: 'cpu_usage' },
  { label: '内存使用率', value: 'memory_usage' },
  { label: '磁盘使用率', value: 'disk_usage' },
  { label: '网络流入', value: 'network_in' },
  { label: '网络流出', value: 'network_out' }
]

// 仪表板对话框
const dashboardDialog = ref({
  visible: false,
  isEdit: false,
  submitting: false,
  form: {
    name: '',
    description: ''
  },
  rules: {
    name: [
      { required: true, message: '请输入名称', trigger: 'blur' },
      { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
    ]
  }
})
const dashboardFormRef = ref<FormInstance>()

// 面板对话框
const panelDialog = ref({
  visible: false,
  isEdit: false,
  submitting: false,
  currentPanelId: '',
  form: {
    title: '',
    type: 'line',
    query: {
      metric: '',
      aggregation: 'avg',
      interval: 1,
      intervalUnit: 'm'
    },
    options: {},
    optionsStr: '{}'
  },
  rules: {
    title: [
      { required: true, message: '请输入标题', trigger: 'blur' }
    ],
    type: [
      { required: true, message: '请选择类型', trigger: 'change' }
    ],
    'query.metric': [
      { required: true, message: '请选择指标', trigger: 'change' }
    ]
  }
})
const panelFormRef = ref<FormInstance>()

// 获取面板组件
const getPanelComponent = (type: string) => {
  const components = {
    line: LineChartPanel,
    bar: BarChartPanel,
    gauge: GaugePanel,
    stat: StatPanel,
    table: TablePanel
  }
  return components[type] || LineChartPanel
}

// 加载仪表板列表
const loadDashboards = async () => {
  try {
    const { items } = await getDashboards()
    dashboards.value = items
  } catch (error: any) {
    ElMessage.error(error.message || '加载仪表板列表失败')
  }
}

// 加载当前仪表板
const loadCurrentDashboard = async () => {
  if (!currentDashboardId.value) {
    currentDashboard.value = undefined
    return
  }
  
  loading.value = true
  try {
    const data = await getDashboard(currentDashboardId.value)
    currentDashboard.value = data
    await refreshPanelsData()
  } catch (error: any) {
    ElMessage.error(error.message || '加载仪表板失败')
  } finally {
    loading.value = false
  }
}

// 刷新面板数据
const refreshPanelsData = async () => {
  if (!currentDashboard.value) return
  
  const now = new Date()
  const promises = currentDashboard.value.layout.map(async (panel) => {
    try {
      const data = await getMetricData({
        ...panel.query,
        end_time: now.toISOString(),
        start_time: new Date(
          now.getTime() - 3600000 // 默认查询最近1小时的数据
        ).toISOString()
      })
      panelData.value[panel.id] = data
    } catch (error) {
      console.error(`Failed to fetch data for panel ${panel.id}:`, error)
    }
  })
  
  await Promise.all(promises)
}

// 处理创建仪表板
const handleCreateDashboard = () => {
  dashboardDialog.value.isEdit = false
  dashboardDialog.value.form = {
    name: '',
    description: ''
  }
  dashboardDialog.value.visible = true
}

// 处理编辑仪表板
const handleEditDashboard = () => {
  if (!currentDashboard.value) return
  
  dashboardDialog.value.isEdit = true
  dashboardDialog.value.form = {
    name: currentDashboard.value.name,
    description: currentDashboard.value.description || ''
  }
  dashboardDialog.value.visible = true
}

// 处理仪表板表单提交
const handleDashboardSubmit = async () => {
  if (!dashboardFormRef.value) return
  
  await dashboardFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      dashboardDialog.value.submitting = true
      
      if (dashboardDialog.value.isEdit && currentDashboard.value) {
        await updateDashboard(currentDashboard.value.id, dashboardDialog.value.form)
        ElMessage.success('更新成功')
      } else {
        const { id } = await createDashboard({
          ...dashboardDialog.value.form,
          layout: []
        })
        currentDashboardId.value = id
        ElMessage.success('创建成功')
      }
      
      dashboardDialog.value.visible = false
      await loadDashboards()
      await loadCurrentDashboard()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      dashboardDialog.value.submitting = false
    }
  })
}

// 处理添加面板
const handleAddPanel = () => {
  panelDialog.value.isEdit = false
  panelDialog.value.form = {
    title: '',
    type: 'line',
    query: {
      metric: '',
      aggregation: 'avg',
      interval: 1,
      intervalUnit: 'm'
    },
    options: {},
    optionsStr: '{}'
  }
  panelDialog.value.visible = true
}

// 处理编辑面板
const handleEditPanel = (panel: DashboardPanel) => {
  panelDialog.value.isEdit = true
  panelDialog.value.currentPanelId = panel.id
  panelDialog.value.form = {
    title: panel.title,
    type: panel.type,
    query: { ...panel.query },
    options: { ...panel.options },
    optionsStr: JSON.stringify(panel.options, null, 2)
  }
  panelDialog.value.visible = true
}

// 处理删除面板
const handleDeletePanel = async (panel: DashboardPanel) => {
  if (!currentDashboard.value) return
  
  try {
    await ElMessageBox.confirm(
      '确认删除该面板吗？此操作不可恢复。',
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const newLayout = currentDashboard.value.layout.filter(p => p.id !== panel.id)
    await updateDashboard(currentDashboard.value.id, {
      layout: newLayout
    })
    
    ElMessage.success('删除成功')
    await loadCurrentDashboard()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 处理面板表单提交
const handlePanelSubmit = async () => {
  if (!panelFormRef.value || !currentDashboard.value) return
  
  await panelFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      panelDialog.value.submitting = true
      
      let options = {}
      try {
        options = JSON.parse(panelDialog.value.form.optionsStr)
      } catch (e) {
        ElMessage.warning('面板选项格式不正确，将使用默认选项')
      }
      
      const newPanel = {
        id: panelDialog.value.isEdit
          ? panelDialog.value.currentPanelId
          : `panel-${Date.now()}`,
        title: panelDialog.value.form.title,
        type: panelDialog.value.form.type,
        query: {
          ...panelDialog.value.form.query,
          interval: `${panelDialog.value.form.query.interval}${panelDialog.value.form.query.intervalUnit}`
        },
        options,
        position: {
          x: 0,
          y: 0,
          w: 6,
          h: 8
        }
      }
      
      let newLayout
      if (panelDialog.value.isEdit) {
        newLayout = currentDashboard.value.layout.map(p =>
          p.id === newPanel.id ? newPanel : p
        )
      } else {
        newLayout = [...currentDashboard.value.layout, newPanel]
      }
      
      await updateDashboard(currentDashboard.value.id, { layout: newLayout })
      
      ElMessage.success(panelDialog.value.isEdit ? '更新成功' : '添加成功')
      panelDialog.value.visible = false
      await loadCurrentDashboard()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      panelDialog.value.submitting = false
    }
  })
}

// 处理刷新
const handleRefresh = () => {
  refreshPanelsData()
}

// 监听仪表板切换
watch(currentDashboardId, () => {
  loadCurrentDashboard()
})

// 自动刷新
let refreshTimer: number
const startAutoRefresh = () => {
  refreshTimer = window.setInterval(() => {
    if (currentDashboard.value) {
      refreshPanelsData()
    }
  }, 60000) // 每分钟刷新一次
}

// 生命周期钩子
onMounted(async () => {
  await loadDashboards()
  if (dashboards.value.length > 0) {
    currentDashboardId.value = dashboards.value[0].id
  }
  startAutoRefresh()
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
})
</script>

<style lang="scss" scoped>
.monitoring-dashboard {
  .dashboard-content {
    margin-top: 24px;
    padding: 24px;
    min-height: calc(100vh - 200px);
    background: #f0f2f5;
  }

  :deep(.panel-card) {
    height: 100%;
    
    .el-card__header {
      padding: 12px 16px;
      border-bottom: 1px solid #f0f0f0;
    }
    
    .el-card__body {
      padding: 12px;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .panel-content {
      height: calc(100% - 24px);
    }
  }

  .add-panel {
    margin-top: 24px;
    text-align: center;
    
    .el-button {
      width: 200px;
      height: 100px;
      border: 1px dashed #d9d9d9;
      
      &:hover {
        border-color: #1890ff;
        color: #1890ff;
      }
    }
  }
}
</style>
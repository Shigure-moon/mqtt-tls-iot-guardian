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
        <div class="card-header">
          <span>监控数据</span>
          <div class="header-actions">
            <el-select
              v-model="selectedMetric"
              size="small"
              style="width: 200px"
              @change="fetchMetricData"
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
      <div id="metric-chart" style="height: 300px"></div>
    </el-card>

    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>证书管理</span>
          <div class="header-actions">
            <el-button type="primary" @click="handleGenerateCert">
              <el-icon><Plus /></el-icon>
              生成证书
            </el-button>
            <el-button link @click="fetchCertificates">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>
      <el-alert
        type="info"
        :closable="false"
        style="margin-bottom: 15px"
      >
        <template #title>
          <span>证书管理说明</span>
        </template>
        <div style="font-size: 12px; line-height: 1.6;">
          <p><strong>证书的作用：</strong></p>
          <ul style="margin: 8px 0; padding-left: 20px;">
            <li><strong>服务器证书</strong>：用于HTTPS OTA固件下载和MQTT TLS连接的服务器端认证（必需）</li>
            <li><strong>CA证书</strong>：已内置在固件中，用于验证服务器证书的真实性（必需）</li>
            <li><strong>客户端证书</strong>：用于MQTT双向认证（可选，当前使用用户名密码认证）</li>
          </ul>
          <p style="margin-top: 8px;"><strong>简化流程：</strong>如果使用用户名密码认证MQTT，客户端证书是可选的。但服务器证书和CA证书是必需的，用于HTTPS OTA安全下载。</p>
        </div>
      </el-alert>
      <el-table v-loading="certLoading" :data="certificates" style="width: 100%">
        <el-table-column prop="serial_number" label="序列号" width="200" />
        <el-table-column prop="certificate_type" label="证书类型" width="120">
          <template #default="{ row }">
            <el-tag :type="row.certificate_type === 'client' ? 'primary' : 'success'">
              {{ row.certificate_type === 'client' ? '客户端' : '服务器' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="issued_at" label="颁发时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.issued_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="expires_at" label="过期时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.expires_at) }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getCertStatusType(row)">
              {{ getCertStatusText(row) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleViewCert(row)">
              查看
            </el-button>
            <el-button link type="primary" @click="handleDownloadCert(row)">
              下载
            </el-button>
            <el-button 
              v-if="!row.revoked_at" 
              link 
              type="success" 
              @click="handleRenewCert(row)"
            >
              续约
            </el-button>
            <el-button 
              v-if="!row.revoked_at" 
              link 
              type="danger" 
              @click="handleRevokeCert(row)"
            >
              吊销
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div v-if="certificates.length === 0" style="text-align: center; padding: 40px; color: #909399">
        暂无证书，点击"生成证书"创建新证书
      </div>
    </el-card>

    <!-- 加密烧录管理 -->
    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>加密烧录</span>
          <div class="header-actions">
            <el-button type="primary" @click="handleBuildFirmware">
              <el-icon><Plus /></el-icon>
              申请烧录文件
            </el-button>
            <el-button link @click="checkFirmwareStatus">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>
      
      <el-alert
        v-if="!isAdmin"
        type="info"
        :closable="false"
        style="margin-bottom: 20px"
      >
        <template #title>
          <span>普通用户权限说明</span>
        </template>
        <div>
          <p>• 您可以申请加密烧录文件，但无法查看密钥信息</p>
          <p>• 密钥信息仅管理员可见，确保系统安全</p>
          <p>• 如需密钥，请联系管理员</p>
        </div>
      </el-alert>
      
      <el-descriptions :column="2" border v-if="firmwareBuildInfo">
        <el-descriptions-item label="构建状态">
          <el-tag :type="firmwareBuildInfo.status === 'completed' ? 'success' : firmwareBuildInfo.status === 'failed' ? 'danger' : 'warning'">
            {{ getBuildStatusText(firmwareBuildInfo.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="加密方式">
          <el-tag type="info">XOR掩码 + HTTPS OTA</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="固件大小" v-if="firmwareBuildInfo.firmware_size">
          {{ firmwareBuildInfo.firmware_size }}
        </el-descriptions-item>
        <el-descriptions-item label="构建时间" v-if="firmwareBuildInfo.created_at">
          {{ formatTime(firmwareBuildInfo.created_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="错误信息" :span="2" v-if="firmwareBuildInfo.error_message">
          <el-text type="danger">{{ firmwareBuildInfo.error_message }}</el-text>
        </el-descriptions-item>
        <el-descriptions-item label="OTA配置" :span="2" v-if="firmwareBuildInfo.ota_config">
          <el-card style="margin-top: 10px">
            <pre style="margin: 0; font-family: monospace; font-size: 12px; white-space: pre-wrap; word-wrap: break-word;">{{ JSON.stringify(firmwareBuildInfo.ota_config, null, 2) }}</pre>
            <el-button 
              type="primary" 
              size="small" 
              style="margin-top: 10px"
              @click="copyOTAConfig"
            >
              复制OTA配置
            </el-button>
          </el-card>
        </el-descriptions-item>
      </el-descriptions>
      
      <div v-else style="text-align: center; padding: 40px; color: #909399">
        <p>暂无加密烧录文件</p>
        <p style="font-size: 12px; margin-top: 10px">点击"申请烧录文件"按钮生成加密固件</p>
      </div>
      
      <div style="margin-top: 20px" v-if="firmwareBuildInfo && firmwareBuildInfo.status === 'completed'">
        <el-button type="success" @click="handleDownloadFirmware">
          <el-icon><Download /></el-icon>
          下载加密固件
        </el-button>
        <el-button type="primary" @click="handleOTAUpdate" :loading="otaUpdateLoading">
          <el-icon><Upload /></el-icon>
          推送OTA更新
        </el-button>
      </div>
      
      <!-- OTA更新状态 -->
      <el-card style="margin-top: 20px" v-if="otaUpdateStatus">
        <template #header>
          <div class="card-header">
            <span>OTA更新状态</span>
            <el-button type="primary" link @click="checkOTAStatus">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="状态">
            <el-tag :type="getOTAStatusType(otaUpdateStatus.status)">
              {{ getOTAStatusText(otaUpdateStatus.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="进度">
            {{ otaUpdateStatus.progress }}
          </el-descriptions-item>
          <el-descriptions-item label="开始时间" v-if="otaUpdateStatus.started_at">
            {{ formatTime(otaUpdateStatus.started_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="完成时间" v-if="otaUpdateStatus.completed_at">
            {{ formatTime(otaUpdateStatus.completed_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="错误信息" :span="2" v-if="otaUpdateStatus.error_message">
            <el-text type="danger">{{ otaUpdateStatus.error_message }}</el-text>
          </el-descriptions-item>
        </el-descriptions>
      </el-card>
      
      <!-- 管理员可见：密钥管理 -->
      <el-divider v-if="isAdmin">密钥管理（仅管理员）</el-divider>
      <div v-if="isAdmin" style="margin-top: 20px">
        <el-button type="warning" @click="handleViewKey">
          查看加密密钥
        </el-button>
        <el-button type="danger" @click="handleRegenerateKey">
          重新生成密钥
        </el-button>
        <el-alert
          v-if="encryptionKey"
          type="warning"
          :closable="false"
          style="margin-top: 15px"
        >
          <template #title>
            <span>XOR密钥（请妥善保管）</span>
          </template>
          <div>
            <p style="font-family: monospace; word-break: break-all;">{{ encryptionKey }}</p>
            <el-button size="small" type="primary" @click="copyKey" style="margin-top: 10px">
              复制密钥
            </el-button>
          </div>
        </el-alert>
      </div>
    </el-card>

    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>告警列表</span>
          <el-button type="primary" link @click="fetchAlerts">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>
      <el-table :data="alerts" style="width: 100%">
        <el-table-column prop="type" label="告警类型" width="150" />
        <el-table-column prop="severity" label="严重程度" width="100">
          <template #default="{ row }">
            <el-tag :type="getSeverityType(row.severity)">
              {{ row.severity }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="message" label="告警消息" />
        <el-table-column prop="timestamp" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.timestamp) }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'resolved' ? 'success' : 'warning'">
              {{ row.status === 'resolved' ? '已解决' : '待处理' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 生成证书对话框 -->
    <el-dialog
      v-model="certDialogVisible"
      title="生成设备证书"
      width="600px"
      @close="resetCertForm"
    >
      <el-form
        ref="certFormRef"
        :model="certForm"
        :rules="certFormRules"
        label-width="120px"
      >
        <el-form-item prop="certificate_type">
          <template #label>
            <span>证书类型</span>
          </template>
          <el-radio-group v-model="certForm.certificate_type">
            <el-radio value="client">客户端证书</el-radio>
            <!-- 服务器证书只能由超级管理员在安全管理页面生成 -->
          </el-radio-group>
        </el-form-item>
        <el-form-item prop="common_name">
          <template #label>
            <span>通用名称</span>
          </template>
          <el-input
            v-model="certForm.common_name"
            placeholder="请输入证书通用名称（CN）"
          />
          <div class="form-tip">
            通常为设备名称或设备ID
          </div>
        </el-form-item>
        <el-form-item prop="validity_days">
          <template #label>
            <span>有效期（天）</span>
          </template>
          <el-input-number
            v-model="certForm.validity_days"
            :min="30"
            :max="3650"
            :precision="0"
            style="width: 100%"
          />
          <div class="form-tip">
            证书有效期，建议365天
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="certDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="certSubmitLoading" @click="submitCertForm">
          生成证书
        </el-button>
      </template>
    </el-dialog>

    <!-- 查看证书对话框 -->
    <el-dialog
      v-model="certViewDialogVisible"
      title="证书详情"
      width="800px"
    >
      <el-descriptions :column="1" border>
        <el-descriptions-item label="序列号">
          {{ currentCert?.serial_number }}
        </el-descriptions-item>
        <el-descriptions-item label="证书类型">
          <el-tag :type="currentCert?.certificate_type === 'client' ? 'primary' : 'success'">
            {{ currentCert?.certificate_type === 'client' ? '客户端证书' : '服务器证书' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="颁发时间">
          {{ formatTime(currentCert?.issued_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="过期时间">
          {{ formatTime(currentCert?.expires_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="getCertStatusType(currentCert)">
            {{ getCertStatusText(currentCert) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item v-if="currentCert?.revoked_at" label="吊销时间">
          {{ formatTime(currentCert.revoked_at) }}
        </el-descriptions-item>
        <el-descriptions-item v-if="currentCert?.revoke_reason" label="吊销原因">
          {{ currentCert.revoke_reason }}
        </el-descriptions-item>
        <el-descriptions-item label="证书内容" :span="2">
          <el-input
            :model-value="currentCert?.certificate || ''"
            type="textarea"
            :rows="10"
            readonly
            style="font-family: monospace; font-size: 12px;"
          />
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="certViewDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="handleDownloadCert(currentCert)">
          下载证书
        </el-button>
      </template>
    </el-dialog>

    <!-- 续约证书对话框 -->
    <el-dialog
      v-model="renewDialogVisible"
      title="续约证书"
      width="500px"
      @close="resetRenewForm"
    >
      <el-form
        ref="renewFormRef"
        :model="renewForm"
        :rules="renewFormRules"
        label-width="120px"
      >
        <el-form-item>
          <template #label>
            <span>证书序列号</span>
          </template>
          <el-input :model-value="currentCert?.serial_number || ''" disabled />
        </el-form-item>
        <el-form-item>
          <template #label>
            <span>当前过期时间</span>
          </template>
          <el-input :model-value="currentCert ? formatTime(currentCert.expires_at) : ''" disabled />
        </el-form-item>
        <el-form-item prop="validity_days">
          <template #label>
            <span>新有效期（天）</span>
          </template>
          <el-input-number
            v-model="renewForm.validity_days"
            :min="1"
            :max="3650"
            :precision="0"
            style="width: 100%"
          />
          <div class="form-tip">
            新证书的有效期，建议365天
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="renewDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="renewLoading" @click="confirmRenew">
          确认续约
        </el-button>
      </template>
    </el-dialog>

    <!-- 吊销证书对话框 -->
    <el-dialog
      v-model="revokeDialogVisible"
      title="吊销证书"
      width="500px"
    >
      <el-form
        ref="revokeFormRef"
        :model="revokeForm"
        :rules="revokeFormRules"
        label-width="100px"
      >
        <el-form-item>
          <template #label>
            <span>证书序列号</span>
          </template>
          <el-input :model-value="currentCert?.serial_number || ''" disabled />
        </el-form-item>
        <el-form-item prop="reason">
          <template #label>
            <span>吊销原因</span>
          </template>
          <el-input
            v-model="revokeForm.reason"
            type="textarea"
            :rows="3"
            placeholder="请输入吊销原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="revokeDialogVisible = false">取消</el-button>
        <el-button type="danger" :loading="revokeLoading" @click="confirmRevoke">
          确认吊销
        </el-button>
      </template>
    </el-dialog>

    <!-- 构建固件对话框 -->
    <el-dialog
      v-model="buildDialogVisible"
      title="申请加密烧录文件"
      width="600px"
      @close="buildFormRef?.resetFields()"
    >
      <el-form
        ref="buildFormRef"
        :model="buildForm"
        :rules="buildFormRules"
        label-width="120px"
      >
        <el-form-item prop="wifi_ssid">
          <template #label>
            <span>WiFi SSID</span>
          </template>
          <el-input
            v-model="buildForm.wifi_ssid"
            placeholder="请输入WiFi网络名称"
          />
        </el-form-item>
        <el-form-item prop="wifi_password">
          <template #label>
            <span>WiFi密码</span>
          </template>
          <el-input
            v-model="buildForm.wifi_password"
            type="password"
            placeholder="请输入WiFi密码"
            show-password
          />
        </el-form-item>
        <el-form-item>
          <template #label>
            <span>模板选择</span>
          </template>
          <el-select
            v-model="buildForm.template_id"
            placeholder="选择固件模板（可选，默认使用系统模板）"
            style="width: 100%"
            :loading="templatesLoading"
            clearable
            filterable
          >
            <el-option
              v-for="template in templates"
              :key="template.id"
              :label="`${template.name} (${template.version})`"
              :value="template.id"
            >
              <div>
                <div style="font-weight: bold">{{ template.name }}</div>
                <div style="font-size: 12px; color: #909399">
                  版本: {{ template.version }}
                  <span v-if="template.description"> | {{ template.description }}</span>
                </div>
              </div>
            </el-option>
          </el-select>
          <div class="form-tip">
            选择管理员创建的固件模板，不同版本可能包含不同的功能和优化
          </div>
        </el-form-item>
        <el-form-item>
          <template #label>
            <span>使用加密</span>
          </template>
          <el-switch v-model="buildForm.use_encryption" />
          <div class="form-tip">
            启用XOR掩码加密，保护固件内容
          </div>
        </el-form-item>
        <el-alert
          v-if="!isAdmin"
          type="info"
          :closable="false"
          style="margin-top: 15px"
        >
          <template #title>
            <span>权限提示</span>
          </template>
          <div>
            <p>普通用户只能申请烧录文件，无法查看密钥信息</p>
            <p>密钥信息仅管理员可见，请联系管理员获取</p>
          </div>
        </el-alert>
      </el-form>
      <template #footer>
        <el-button @click="buildDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="firmwareBuildLoading" @click="submitBuildForm">
          提交申请
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { ArrowLeft, Refresh, Plus, Download, Setting, Upload } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import * as echarts from 'echarts'
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

interface Alert {
  id: string
  type: string
  severity: string
  message: string
  timestamp: string
  status: string
}

interface DeviceCertificate {
  id: string
  device_id: string
  certificate_type: string
  serial_number: string
  certificate: string
  issued_at: string
  expires_at: string
  revoked_at?: string
  revoke_reason?: string
  created_at: string
}

const route = useRoute()
const userStore = useUserStore()

const loading = ref(false)
const deviceInfo = ref<Device | null>(null)

// 管理员权限
const isAdmin = computed(() => userStore.isAdmin)

// 证书管理相关
const certLoading = ref(false)
const certificates = ref<DeviceCertificate[]>([])
const certDialogVisible = ref(false)
const certViewDialogVisible = ref(false)
const certSubmitLoading = ref(false)
const currentCert = ref<DeviceCertificate | null>(null)
const certFormRef = ref<FormInstance>()
const certForm = ref({
  certificate_type: 'client',
  common_name: '',
  validity_days: 365,
})
const certFormRules: FormRules = {
  common_name: [
    { required: false, message: '请输入证书通用名称', trigger: 'blur' },
  ],
  validity_days: [
    { required: true, message: '请输入有效期', trigger: 'blur' },
  ],
}

// 吊销证书相关
const revokeDialogVisible = ref(false)
const revokeLoading = ref(false)
const revokeFormRef = ref<FormInstance>()
const revokeForm = ref({
  reason: '',
})
const revokeFormRules: FormRules = {
  reason: [
    { required: true, message: '请输入吊销原因', trigger: 'blur' },
  ],
}

// 续约证书相关
const renewDialogVisible = ref(false)
const renewLoading = ref(false)
const renewFormRef = ref<FormInstance>()
const renewForm = ref({
  validity_days: 365,
})
const renewFormRules: FormRules = {
  validity_days: [
    { required: true, message: '请输入有效期', trigger: 'blur' },
    { type: 'number', min: 1, max: 3650, message: '有效期必须在1-3650天之间', trigger: 'blur' },
  ],
}

// 监控数据配置
const metrics = [
  { label: '温度', value: 'temperature' },
  { label: '湿度', value: 'humidity' },
  { label: '空气质量', value: 'air_quality' },
  { label: '电池电量', value: 'battery' }
]
const selectedMetric = ref('temperature')

const timePeriods = [
  { label: '1小时', value: '1h' },
  { label: '6小时', value: '6h' },
  { label: '1天', value: '1d' },
  { label: '1周', value: '1w' }
]
const selectedPeriod = ref('1h')

// 告警列表
const alerts = ref<Alert[]>([])

// 加密烧录相关
const firmwareBuildInfo = ref<any>(null)
const firmwareBuildLoading = ref(false)
const buildDialogVisible = ref(false)
const buildFormRef = ref<FormInstance>()
const buildForm = ref({
  wifi_ssid: '',
  wifi_password: '',
  use_encryption: true,
  template_id: ''
})
const buildFormRules: FormRules = {
  wifi_ssid: [{ required: true, message: '请输入WiFi SSID', trigger: 'blur' }],
  wifi_password: [{ required: true, message: '请输入WiFi密码', trigger: 'blur' }]
}

// 模板列表
const templates = ref<Array<{id: string, name: string, version: string, description?: string}>>([])
const templatesLoading = ref(false)

// 密钥管理（仅管理员）
const encryptionKey = ref<string | null>(null)
const hasEncryptionKey = ref(false)

// OTA更新
const otaUpdateLoading = ref(false)
const otaUpdateStatus = ref<any>(null)

// ECharts实例
let chartInstance: echarts.ECharts | null = null

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
    const response = await request.get(`/devices/${deviceId}`)
    deviceInfo.value = response as unknown as Device
    // 获取设备信息后，加载监控数据、告警和证书
    await Promise.all([fetchMetricData(), fetchAlerts(), fetchCertificates()])
  } catch (error) {
    ElMessage.error('获取设备详情失败')
  } finally {
    loading.value = false
  }
}

// 获取监控数据
const fetchMetricData = async () => {
  if (!deviceInfo.value) return
  
  try {
    // 计算时间范围
    const now = new Date()
    const end = now.toISOString()
    const start = new Date(now.getTime() - getPeriodMilliseconds(selectedPeriod.value))
      .toISOString()
    
    const response = await request.get('/monitoring/metrics/' + deviceInfo.value.id, {
      params: {
        start_time: start,
        end_time: end,
        metric_type: selectedMetric.value,
        limit: 100
      }
    })
    
    // API返回的metrics是一个数组
    const data = Array.isArray(response) ? response : []
    if (data.length > 0) {
      // 解析JSON格式的metrics字段
      const chartData = data.map((item: any) => {
        const metrics = typeof item.metrics === 'string' ? JSON.parse(item.metrics) : item.metrics
        return {
          timestamp: item.timestamp,
          value: metrics.value
        }
      })
      updateChart(chartData)
    } else {
      updateChart([])
    }
  } catch (error) {
    // 监控数据为空时显示空图表
    console.log('获取监控数据失败或为空:', error)
    initChart()
  }
}

// 获取告警列表
const fetchAlerts = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get('/monitoring/alerts', {
      params: {
        device_id: deviceInfo.value.id,
        limit: 20
      }
    })
    alerts.value = Array.isArray(response) ? response : []
  } catch (error) {
    console.log('获取告警列表失败:', error)
  }
}

// 初始化图表
const initChart = () => {
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
  
  const chartDom = document.getElementById('metric-chart')
  if (!chartDom) return
  
  chartInstance = echarts.init(chartDom)
  chartInstance.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', boundaryGap: false, data: [] },
    yAxis: { type: 'value' },
    series: [{
      type: 'line',
      data: [],
      smooth: true,
      areaStyle: {}
    }]
  })
}

// 更新图表数据
const updateChart = (data: any[]) => {
  if (!chartInstance) {
    // 等待DOM渲染完成
    setTimeout(() => initChart(), 0)
    return
  }
  
  chartInstance.setOption({
    xAxis: {
      data: data.map((d: any) => new Date(d.timestamp).toLocaleTimeString())
    },
    series: [{
      data: data.map((d: any) => d.value)
    }]
  })
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

// 获取严重程度类型
const getSeverityType = (severity?: string) => {
  const types: Record<string, string> = {
    low: 'info',
    medium: 'warning',
    high: 'danger',
    critical: 'danger'
  }
  return types[severity || ''] || 'info'
}

// 证书管理相关函数
const fetchCertificates = async () => {
  if (!deviceInfo.value) return
  
  certLoading.value = true
  try {
    const response = await request.get(`/devices/${deviceInfo.value.id}/certificates`)
    certificates.value = Array.isArray(response) ? response : []
  } catch (error) {
    console.error('获取证书列表失败:', error)
    certificates.value = []
  } finally {
    certLoading.value = false
  }
}

const getCertStatusType = (cert?: DeviceCertificate | null) => {
  if (!cert) return 'info'
  if (cert.revoked_at) return 'danger'
  const now = new Date()
  const expiresAt = new Date(cert.expires_at)
  if (expiresAt < now) return 'warning'
  // 30天内过期
  const daysUntilExpiry = (expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
  if (daysUntilExpiry <= 30) return 'warning'
  return 'success'
}

const getCertStatusText = (cert?: DeviceCertificate | null) => {
  if (!cert) return '-'
  if (cert.revoked_at) return '已吊销'
  const now = new Date()
  const expiresAt = new Date(cert.expires_at)
  if (expiresAt < now) return '已过期'
  const daysUntilExpiry = Math.floor((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  if (daysUntilExpiry <= 30) return `即将过期（${daysUntilExpiry}天）`
  return '有效'
}

const handleGenerateCert = () => {
  if (!deviceInfo.value) return
  certForm.value.common_name = deviceInfo.value.name || deviceInfo.value.device_id
  certDialogVisible.value = true
}

const resetCertForm = () => {
  certFormRef.value?.resetFields()
  certForm.value = {
    certificate_type: 'client',
    common_name: deviceInfo.value?.name || deviceInfo.value?.device_id || '',
    validity_days: 365,
  }
}

const submitCertForm = async () => {
  if (!certFormRef.value || !deviceInfo.value) return
  
  try {
    await certFormRef.value.validate()
    certSubmitLoading.value = true
    
    // 确保 common_name 有值
    const commonName = certForm.value.common_name || deviceInfo.value.name || deviceInfo.value.device_id
    
    const response = await request.post(`/certificates/client/generate/${deviceInfo.value.device_id}`, {
      common_name: commonName,
      validity_days: certForm.value.validity_days,
    })
    
    ElMessage.success('证书生成成功')
    certDialogVisible.value = false
    await fetchCertificates()
  } catch (error: any) {
    const errorMsg = error.response?.data?.detail || error.message || '生成证书失败'
    ElMessage.error(errorMsg)
    console.error('Certificate generation error:', error)
  } finally {
    certSubmitLoading.value = false
  }
}

const handleViewCert = async (cert: DeviceCertificate) => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get(`/devices/${deviceInfo.value.id}/certificates/${cert.id}`)
    currentCert.value = response as DeviceCertificate
    certViewDialogVisible.value = true
  } catch (error) {
    ElMessage.error('获取证书详情失败')
  }
}

const handleDownloadCert = async (cert: DeviceCertificate | null | undefined) => {
  if (!cert) return
  
  try {
    // 创建证书文件内容
    const certContent = cert.certificate
    const blob = new Blob([certContent], { type: 'text/plain' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `certificate-${cert.serial_number}.pem`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('证书下载成功')
  } catch (error) {
    ElMessage.error('下载证书失败')
  }
}

const handleRenewCert = (cert: DeviceCertificate) => {
  currentCert.value = cert
  renewForm.value.validity_days = 365
  renewDialogVisible.value = true
}

const resetRenewForm = () => {
  renewForm.value.validity_days = 365
  renewFormRef.value?.resetFields()
}

const confirmRenew = async () => {
  if (!renewFormRef.value || !currentCert.value || !deviceInfo.value) return
  
  try {
    await renewFormRef.value.validate()
    renewLoading.value = true
    
    await request.post(
      `/devices/${deviceInfo.value.id}/certificates/${currentCert.value.id}/renew?validity_days=${renewForm.value.validity_days}`
    )
    
    ElMessage.success('证书已成功续约')
    renewDialogVisible.value = false
    await fetchCertificates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '续约证书失败')
  } finally {
    renewLoading.value = false
  }
}

const handleRevokeCert = (cert: DeviceCertificate) => {
  currentCert.value = cert
  revokeForm.value.reason = ''
  revokeDialogVisible.value = true
}

const confirmRevoke = async () => {
  if (!revokeFormRef.value || !currentCert.value || !deviceInfo.value) return
  
  try {
    await revokeFormRef.value.validate()
    revokeLoading.value = true
    
    await request.post(`/devices/${deviceInfo.value.id}/certificates/${currentCert.value.id}/revoke?reason=${encodeURIComponent(revokeForm.value.reason)}`)
    
    ElMessage.success('证书已成功吊销')
    revokeDialogVisible.value = false
    await fetchCertificates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '吊销证书失败')
  } finally {
    revokeLoading.value = false
  }
}

// 自动刷新
let refreshTimer: number
const startAutoRefresh = () => {
  refreshTimer = window.setInterval(() => {
    if (deviceInfo.value) {
      fetchDeviceDetail()
    }
  }, 30000) // 每30秒刷新一次
}

// 加密烧录相关函数
const handleBuildFirmware = async () => {
  if (!deviceInfo.value) return
  buildForm.value.wifi_ssid = ''
  buildForm.value.wifi_password = ''
  buildForm.value.use_encryption = true
  buildForm.value.template_id = ''
  
  // 加载模板列表
  await fetchTemplates()
  
  buildDialogVisible.value = true
}

// 获取模板列表
const fetchTemplates = async () => {
  if (!deviceInfo.value) return
  
  try {
    templatesLoading.value = true
    const response = await request.get(`/templates/public/device-types/${deviceInfo.value.type}/list`)
    templates.value = response || []
  } catch (error: any) {
    console.error('获取模板列表失败:', error)
    // 如果获取失败，不影响使用，只是没有模板选择
    templates.value = []
  } finally {
    templatesLoading.value = false
  }
}

const checkFirmwareStatus = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get(`/firmware/status/${deviceInfo.value.device_id}`)
    
    // 更新固件构建信息，保留之前的WiFi配置
    firmwareBuildInfo.value = {
      ...firmwareBuildInfo.value,
      status: response.status,
      firmware_size: response.firmware_size,
      created_at: response.created_at,
      error_message: response.status === 'failed' ? response.message : undefined
    }
    
    // 如果状态为已完成，显示成功消息并获取OTA配置
    if (response.status === 'completed') {
      ElMessage.success('固件构建已完成')
      await fetchOTAConfig()
      // 检查OTA更新状态（只有在有固件时才检查）
      await checkOTAStatus()
    } else if (response.status === 'pending') {
      ElMessage.info('固件代码已生成，加密固件构建中...')
    } else if (response.status === 'not_found') {
      firmwareBuildInfo.value = null
    }
  } catch (error: any) {
    // 如果返回404，说明没有固件文件
    if (error.response?.status === 404) {
      firmwareBuildInfo.value = null
    } else {
      const errorMsg = error.response?.data?.detail || error.message || '获取固件状态失败'
      ElMessage.error(errorMsg)
      console.error('Check firmware status error:', error)
    }
  }
}

const fetchOTAConfig = async () => {
  if (!deviceInfo.value || !firmwareBuildInfo.value) return
  
  try {
    // 获取后端服务器地址
    // 优先使用环境变量，如果没有则从当前请求的baseURL推断
    let serverHost = 'localhost'
    let serverPort = 8000
    let useHttps = false
    
    const apiBaseURL = import.meta.env.VITE_API_BASE_URL
    if (apiBaseURL) {
      try {
        const apiURL = new URL(apiBaseURL)
        serverHost = apiURL.hostname
        serverPort = apiURL.port ? parseInt(apiURL.port) : (apiURL.protocol === 'https:' ? 443 : 80)
        useHttps = apiURL.protocol === 'https:'
      } catch {
        // 如果解析失败，使用默认值
      }
    } else {
      // 如果没有配置，使用默认的后端地址
      serverHost = 'localhost'
      serverPort = 8000
      useHttps = false
    }
    
    // 获取WiFi信息（从构建信息或表单中）
    const wifiSsid = firmwareBuildInfo.value.wifi_ssid || buildForm.value.wifi_ssid || ''
    const wifiPassword = firmwareBuildInfo.value.wifi_password || buildForm.value.wifi_password || ''
    
    const response = await request.get(`/firmware/ota-config/${deviceInfo.value.device_id}`, {
      params: {
        ssid: wifiSsid,
        password: wifiPassword,
        server_host: serverHost,
        server_port: serverPort,
        use_https: useHttps,
        use_xor_mask: firmwareBuildInfo.value.use_encryption !== false
      }
    })
    
    // 保存OTA配置到构建信息中
    firmwareBuildInfo.value = {
      ...firmwareBuildInfo.value,
      ota_config: response
    }
  } catch (error: any) {
    console.error('Fetch OTA config error:', error)
    // OTA配置获取失败不影响主流程，只是不显示配置
  }
}

const submitBuildForm = async () => {
  if (!buildFormRef.value || !deviceInfo.value) return
  
  try {
    await buildFormRef.value.validate()
    firmwareBuildLoading.value = true
    
    const response = await request.post(`/firmware/build/${deviceInfo.value.device_id}`, {
      wifi_ssid: buildForm.value.wifi_ssid,
      wifi_password: buildForm.value.wifi_password,
      use_encryption: buildForm.value.use_encryption,
      template_id: buildForm.value.template_id || undefined
    })
    
    ElMessage.success('固件构建请求已提交')
    buildDialogVisible.value = false
    
    // 保存构建信息，包括WiFi配置
    firmwareBuildInfo.value = {
      ...response,
      wifi_ssid: buildForm.value.wifi_ssid,
      wifi_password: buildForm.value.wifi_password,
      use_encryption: buildForm.value.use_encryption
    }
    
    // 等待一下让构建完成，然后检查状态
    await new Promise(resolve => setTimeout(resolve, 2000))
    await checkFirmwareStatus()
    
    // 如果构建完成，获取OTA配置
    if (firmwareBuildInfo.value.status === 'completed') {
      await fetchOTAConfig()
    }
  } catch (error: any) {
    const errorMsg = error.response?.data?.detail || error.message || '构建固件失败'
    ElMessage.error(errorMsg)
    console.error('Firmware build error:', error)
  } finally {
    firmwareBuildLoading.value = false
  }
}

const handleDownloadFirmware = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get(`/firmware/download/${deviceInfo.value.device_id}`, {
      responseType: 'blob'
    })
    
    // 创建下载链接
    const url = window.URL.createObjectURL(new Blob([response]))
    const link = document.createElement('a')
    link.href = url
    link.download = `${deviceInfo.value.device_id}_encrypted.bin`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('加密固件下载成功')
  } catch (error: any) {
    ElMessage.error('下载加密固件失败')
  }
}

const copyOTAConfig = () => {
  if (!firmwareBuildInfo.value?.ota_config) return
  navigator.clipboard.writeText(JSON.stringify(firmwareBuildInfo.value.ota_config, null, 2))
  ElMessage.success('OTA配置已复制到剪贴板')
}

const handleOTAUpdate = async () => {
  if (!deviceInfo.value) return
  
  try {
    await ElMessageBox.confirm(
      '确认推送OTA更新到设备？设备将自动下载并安装最新固件。',
      '确认OTA更新',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    otaUpdateLoading.value = true
    
    // 如果firmwareBuildInfo有build_id，使用它；否则使用默认URL
    const requestData: any = {}
    if (firmwareBuildInfo.value?.build_id) {
      requestData.firmware_build_id = firmwareBuildInfo.value.build_id
    } else {
      requestData.firmware_url = `/api/v1/firmware/download/${deviceInfo.value.device_id}`
    }
    
    const response = await request.post(`/firmware/ota-update/${deviceInfo.value.device_id}`, requestData)
    
    ElMessage.success('OTA更新指令已推送到设备')
    
    // 获取更新状态
    await checkOTAStatus()
    
    // 如果状态正在更新，定期刷新
    if (response.status && ['sent', 'downloading', 'installing'].includes(response.status)) {
      // 每5秒刷新一次状态
      const statusInterval = setInterval(async () => {
        await checkOTAStatus()
        if (otaUpdateStatus.value && ['completed', 'failed', 'cancelled'].includes(otaUpdateStatus.value.status)) {
          clearInterval(statusInterval)
        }
      }, 5000)
      
      // 30秒后停止自动刷新
      setTimeout(() => clearInterval(statusInterval), 30000)
    }
  } catch (error: any) {
    if (error === 'cancel') return
    const errorMsg = error.response?.data?.detail || error.message || '推送OTA更新失败'
    ElMessage.error(errorMsg)
    console.error('OTA update error:', error)
  } finally {
    otaUpdateLoading.value = false
  }
}

const checkOTAStatus = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get(`/firmware/ota-update/${deviceInfo.value.device_id}/status`)
    
    // 如果返回的是404标记对象，说明没有任务
    if (response && typeof response === 'object' && response.status === 404) {
      otaUpdateStatus.value = null
      return
    }
    
    otaUpdateStatus.value = response
  } catch (error: any) {
    // 404表示没有OTA任务，这是正常的，不需要显示错误
    if (error.response?.status === 404) {
      otaUpdateStatus.value = null
    } else {
      // 其他错误（如500）才记录，但不阻止页面加载
      console.error('Get OTA status error:', error)
      otaUpdateStatus.value = null
    }
  }
}

const getOTAStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    sent: '已推送',
    downloading: '下载中',
    installing: '安装中',
    completed: '已完成',
    failed: '失败',
    cancelled: '已取消'
  }
  return statusMap[status] || status
}

const getOTAStatusType = (status: string) => {
  const typeMap: Record<string, string> = {
    pending: 'info',
    sent: 'warning',
    downloading: 'warning',
    installing: 'warning',
    completed: 'success',
    failed: 'danger',
    cancelled: 'info'
  }
  return typeMap[status] || 'info'
}

const handleViewKey = async () => {
  if (!deviceInfo.value) return
  
  try {
    const response = await request.get(`/firmware/xor-key/${deviceInfo.value.device_id}`)
    encryptionKey.value = response.key_hex
    hasEncryptionKey.value = true
  } catch (error: any) {
    if (error.response?.status === 404) {
      ElMessage.warning('该设备尚未生成加密密钥')
      hasEncryptionKey.value = false
    } else {
      ElMessage.error('获取加密密钥失败')
    }
  }
}

const handleRegenerateKey = async () => {
  if (!deviceInfo.value) return
  
  try {
    await ElMessageBox.confirm(
      '重新生成密钥将导致旧的加密固件无法使用，是否继续？',
      '确认重新生成密钥',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const response = await request.post(`/firmware/generate-key/${deviceInfo.value.device_id}?force=true`)
    encryptionKey.value = response.key_hex
    hasEncryptionKey.value = true
    ElMessage.success('密钥已重新生成')
  } catch (error: any) {
    if (error === 'cancel') return
    ElMessage.error('重新生成密钥失败')
  }
}

const copyKey = () => {
  if (!encryptionKey.value) return
  
  navigator.clipboard.writeText(encryptionKey.value)
  ElMessage.success('密钥已复制到剪贴板')
}

const getBuildStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    building: '构建中',
    completed: '已完成',
    failed: '失败',
    not_found: '未找到'
  }
  return statusMap[status] || status
}

onMounted(() => {
  fetchDeviceDetail().then(() => {
    // 获取设备详情后，检查固件状态
    checkFirmwareStatus().then(() => {
      // 只有在有固件构建完成时才检查OTA状态
      if (firmwareBuildInfo.value?.status === 'completed') {
        checkOTAStatus()
      }
    })
  })
  startAutoRefresh()
  // 如果是管理员，检查是否有加密密钥
  if (isAdmin.value) {
    handleViewKey().catch(() => {})
  }
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
  if (chartInstance) {
    chartInstance.dispose()
  }
})
</script>

<style scoped lang="scss">
.device-detail {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
    
    .header-actions {
      display: flex;
      gap: 8px;
      align-items: center;
    }
  }

  .form-tip {
    font-size: 12px;
    color: var(--el-text-color-secondary);
    margin-top: 4px;
  }
}
</style>


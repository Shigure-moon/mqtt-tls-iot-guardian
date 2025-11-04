<template>
  <div class="security-page">
    <el-tabs v-model="activeTab" type="card">
      <!-- 服务器证书管理 -->
      <el-tab-pane label="服务器证书管理" name="server-certs">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>服务器证书管理</span>
              <div class="header-actions">
                <el-button @click="fetchServerCert">
                  <el-icon><Refresh /></el-icon>
                  刷新
                </el-button>
                <el-button type="primary" @click="handleGenerateServerCert">
                  <el-icon><Plus /></el-icon>
                  生成服务器证书
                </el-button>
              </div>
            </div>
          </template>

          <el-alert
            type="info"
            :closable="false"
            style="margin-bottom: 20px"
          >
            <template #default>
              <div>
                <p>服务器证书用于MQTT Broker的TLS加密通信。</p>
                <p>只有超级管理员可以管理服务器证书。</p>
              </div>
            </template>
          </el-alert>

          <div v-loading="serverCertLoading">
            <el-descriptions :column="2" border v-if="serverCertInfo">
              <el-descriptions-item label="证书状态">
                <el-tag type="success">已生成</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="通用名称">
                {{ serverCertInfo.common_name || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="序列号">
                {{ serverCertInfo.serial_number || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="有效期">
                <span v-if="serverCertInfo.issued_at && serverCertInfo.expires_at">
                  {{ formatTime(serverCertInfo.issued_at) }} 至 {{ formatTime(serverCertInfo.expires_at) }}
                </span>
                <span v-else>-</span>
              </el-descriptions-item>
              <el-descriptions-item label="证书内容" :span="2">
                <el-input
                  :model-value="serverCertInfo.certificate || ''"
                  type="textarea"
                  :rows="10"
                  readonly
                  style="font-family: monospace; font-size: 12px;"
                />
                <el-button
                  type="text"
                  size="small"
                  @click="copyToClipboard(serverCertInfo.certificate)"
                  style="margin-top: 5px;"
                >
                  <el-icon><DocumentCopy /></el-icon>
                  复制证书
                </el-button>
              </el-descriptions-item>
              <el-descriptions-item label="私钥" :span="2">
                <el-input
                  :model-value="serverCertInfo.private_key || ''"
                  type="textarea"
                  :rows="10"
                  readonly
                  style="font-family: monospace; font-size: 12px;"
                />
                <el-button
                  type="text"
                  size="small"
                  @click="copyToClipboard(serverCertInfo.private_key)"
                  style="margin-top: 5px;"
                >
                  <el-icon><DocumentCopy /></el-icon>
                  复制私钥
                </el-button>
              </el-descriptions-item>
            </el-descriptions>
            <el-empty v-else description="尚未生成服务器证书" />
          </div>
        </el-card>
      </el-tab-pane>

      <!-- 模板管理 -->
      <el-tab-pane label="模板管理" name="templates">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>模板管理</span>
              <div class="header-actions">
                <el-button type="primary" @click="handleCreateTemplate">
                  <el-icon><Plus /></el-icon>
                  创建模板
                </el-button>
                <el-button type="primary" @click="handleUploadTemplate">
                  <el-icon><Upload /></el-icon>
                  上传模板
                </el-button>
              </div>
            </div>
          </template>

          <el-table :data="templates" v-loading="templateLoading" style="width: 100%">
            <el-table-column prop="name" label="模板名称" width="200" />
            <el-table-column prop="device_type" label="设备类型" width="150" />
            <el-table-column prop="description" label="描述" />
            <el-table-column label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.is_active ? 'success' : 'info'">
                  {{ row.is_active ? '启用' : '禁用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="created_at" label="创建时间" width="180">
              <template #default="{ row }">
                {{ formatTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="handleViewTemplate(row)">查看</el-button>
                <el-button link type="primary" @click="handleEditTemplate(row)">编辑</el-button>
                <el-button link type="danger" @click="handleDeleteTemplate(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- 数据库管理 -->
      <el-tab-pane label="数据库管理" name="database">
        <!-- 数据库概览 -->
        <el-card style="margin-bottom: 20px">
          <template #header>
            <div class="card-header">
              <span>数据库概览</span>
              <el-button @click="refreshDatabaseOverview">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>

          <el-row :gutter="20">
            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>
                  <span>连接池状态</span>
                </template>
                <div style="margin-bottom: 10px">
                  <el-progress
                    :percentage="databaseOverview.connection_pool.usage_percent"
                    :color="getPoolUsageColor(databaseOverview.connection_pool.usage_percent)"
                  />
                </div>
                <el-descriptions :column="1" size="small" border>
                  <el-descriptions-item label="当前连接">
                    {{ databaseOverview.connection_pool.current }} / {{ databaseOverview.connection_pool.max }}
                  </el-descriptions-item>
                  <el-descriptions-item label="活跃连接">
                    {{ databaseOverview.connection_pool.active }}
                  </el-descriptions-item>
                  <el-descriptions-item label="空闲连接">
                    {{ databaseOverview.connection_pool.idle }}
                  </el-descriptions-item>
                  <el-descriptions-item label="使用率">
                    {{ databaseOverview.connection_pool.usage_percent }}%
                  </el-descriptions-item>
                </el-descriptions>
              </el-card>
            </el-col>

            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>
                  <span>数据库统计</span>
                </template>
                <el-descriptions :column="1" size="small" border>
                  <el-descriptions-item label="数据库大小">
                    {{ databaseOverview.database_stats.size }}
                  </el-descriptions-item>
                  <el-descriptions-item label="表数量">
                    {{ databaseOverview.database_stats.table_count }}
                  </el-descriptions-item>
                  <el-descriptions-item label="索引数量">
                    {{ databaseOverview.database_stats.index_count }}
                  </el-descriptions-item>
                  <el-descriptions-item label="总记录数">
                    {{ formatNumber(databaseOverview.database_stats.total_rows) }}
                  </el-descriptions-item>
                  <el-descriptions-item label="最后更新">
                    {{ formatTime(databaseOverview.database_stats.last_update) }}
                  </el-descriptions-item>
                </el-descriptions>
              </el-card>
            </el-col>

            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>
                  <span>性能指标</span>
                </template>
                <el-descriptions :column="1" size="small" border>
                  <el-descriptions-item label="平均查询时间">
                    {{ databaseOverview.performance.avg_query_time }}ms
                  </el-descriptions-item>
                  <el-descriptions-item label="慢查询">
                    <el-tag :type="databaseOverview.performance.slow_queries > 0 ? 'warning' : 'success'">
                      {{ databaseOverview.performance.slow_queries }}
                    </el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item label="缓存命中率">
                    {{ (databaseOverview.performance.cache_hit_rate * 100).toFixed(1) }}%
                  </el-descriptions-item>
                  <el-descriptions-item label="锁等待">
                    <el-tag :type="databaseOverview.performance.lock_waits > 0 ? 'danger' : 'success'">
                      {{ databaseOverview.performance.lock_waits }}
                    </el-tag>
                  </el-descriptions-item>
                </el-descriptions>
              </el-card>
            </el-col>
          </el-row>
        </el-card>

        <!-- 表管理 -->
        <el-card style="margin-bottom: 20px">
          <template #header>
            <div class="card-header">
              <span>表管理</span>
              <div class="header-actions">
                <el-input
                  v-model="tableSearch"
                  placeholder="搜索表名"
                  style="width: 200px; margin-right: 10px"
                  clearable
                />
                <el-button @click="refreshTableList">
                  <el-icon><Refresh /></el-icon>
                  刷新
                </el-button>
              </div>
            </div>
          </template>

          <el-table
            :data="filteredTables"
            v-loading="tableLoading"
            style="width: 100%"
            @row-click="handleViewTable"
          >
            <el-table-column prop="name" label="表名" width="200" />
            <el-table-column prop="size" label="大小" width="150" />
            <el-table-column prop="row_count" label="记录数" width="150">
              <template #default="{ row }">
                {{ formatNumber(row.row_count) }}
              </template>
            </el-table-column>
            <el-table-column prop="index_count" label="索引数" width="100" />
            <el-table-column prop="last_update" label="最后更新" width="180">
              <template #default="{ row }">
                {{ formatTime(row.last_update) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click.stop="handleViewTable(row)">查看</el-button>
                <el-button link type="primary" @click.stop="handleOptimizeTable(row)">优化</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <!-- SQL查询执行器 -->
        <el-card style="margin-bottom: 20px">
          <template #header>
            <div class="card-header">
              <span>SQL查询执行器</span>
              <div class="header-actions">
                <el-button @click="clearQuery">清空</el-button>
                <el-button type="primary" :loading="queryLoading" @click="executeQuery">
                  执行查询
                </el-button>
              </div>
            </div>
          </template>

          <el-alert
            type="warning"
            :closable="false"
            style="margin-bottom: 15px"
          >
            <template #default>
              <div>
                <p>⚠️ 仅支持SELECT查询（只读操作）</p>
                <p>结果集限制：最多1000行，执行超时：30秒</p>
              </div>
            </template>
          </el-alert>

          <el-input
            v-model="sqlQuery"
            type="textarea"
            :rows="8"
            placeholder="输入SQL查询语句（仅支持SELECT）"
            style="margin-bottom: 15px; font-family: monospace; font-size: 14px;"
          />

          <el-table
            v-if="queryResult"
            :data="queryResult.rows"
            style="width: 100%"
            max-height="400"
            border
          >
            <el-table-column
              v-for="col in queryResult.columns"
              :key="col"
              :prop="col"
              :label="col"
              min-width="120"
            />
          </el-table>
          <div v-if="queryResult" style="margin-top: 10px; color: #909399; font-size: 12px">
            查询完成，共 {{ queryResult.rows.length }} 行，执行时间 {{ queryResult.execution_time }}ms
          </div>
        </el-card>

        <!-- 备份管理 -->
        <el-card style="margin-bottom: 20px">
          <template #header>
            <div class="card-header">
              <span>备份管理</span>
              <el-button type="primary" @click="handleCreateBackup">
                <el-icon><Plus /></el-icon>
                创建备份
              </el-button>
            </div>
          </template>

          <el-table :data="backups" v-loading="backupLoading" style="width: 100%">
            <el-table-column prop="name" label="备份名称" width="200" />
            <el-table-column prop="size" label="大小" width="150" />
            <el-table-column prop="created_at" label="创建时间" width="180">
              <template #default="{ row }">
                {{ formatTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.status === 'completed' ? 'success' : 'warning'">
                  {{ row.status === 'completed' ? '已完成' : '进行中' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="250" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="handleDownloadBackup(row)">下载</el-button>
                <el-button link type="primary" @click="handleRestoreBackup(row)">恢复</el-button>
                <el-button link type="danger" @click="handleDeleteBackup(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <!-- 维护操作 -->
        <el-card>
          <template #header>
            <div class="card-header">
              <span>维护操作</span>
            </div>
          </template>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-card shadow="hover">
                <template #header>
                  <span>数据库优化</span>
                </template>
                <el-space direction="vertical" style="width: 100%">
                  <el-button type="primary" @click="handleVacuum" :loading="maintenanceLoading.vacuum">
                    VACUUM
                  </el-button>
                  <el-button type="primary" @click="handleAnalyze" :loading="maintenanceLoading.analyze">
                    ANALYZE
                  </el-button>
                  <el-button type="primary" @click="handleReindex" :loading="maintenanceLoading.reindex">
                    REINDEX
                  </el-button>
                  <el-button type="primary" @click="handleUpdateStats" :loading="maintenanceLoading.updateStats">
                    更新统计信息
                  </el-button>
                </el-space>
              </el-card>
            </el-col>

            <el-col :span="12">
              <el-card shadow="hover">
                <template #header>
                  <span>数据清理</span>
                </template>
                <el-space direction="vertical" style="width: 100%">
                  <el-button type="warning" @click="handleCleanExpiredData" :loading="maintenanceLoading.cleanExpired">
                    清理过期数据
                  </el-button>
                  <el-button type="warning" @click="handleCleanLogs" :loading="maintenanceLoading.cleanLogs">
                    清理日志表
                  </el-button>
                  <el-button type="warning" @click="handleCleanTempData" :loading="maintenanceLoading.cleanTemp">
                    清理临时数据
                  </el-button>
                </el-space>
              </el-card>
            </el-col>
          </el-row>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 生成服务器证书对话框 -->
    <el-dialog
      v-model="serverCertDialogVisible"
      title="生成服务器证书"
      width="600px"
      @close="resetServerCertForm"
    >
      <el-form
        ref="serverCertFormRef"
        :model="serverCertForm"
        :rules="serverCertFormRules"
        label-width="120px"
      >
        <el-form-item label="通用名称" prop="common_name">
          <el-input
            v-model="serverCertForm.common_name"
            placeholder="如：mosquitto-broker"
          />
        </el-form-item>
        <el-form-item label="有效期（天）" prop="validity_days">
          <el-input-number
            v-model="serverCertForm.validity_days"
            :min="30"
            :max="3650"
            :precision="0"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="备用名称（可选）">
          <el-input
            v-model="serverCertForm.alt_names_input"
            type="textarea"
            :rows="3"
            placeholder="输入IP地址或域名，多个用逗号或换行分隔&#10;例如：10.42.0.1, 192.168.1.8, localhost"
          />
          <div style="margin-top: 5px; color: #909399; font-size: 12px;">
            用于添加服务器证书的Subject Alternative Name（SAN），支持IP地址和域名
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="serverCertDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="serverCertSubmitLoading" @click="submitServerCertForm">
          生成
        </el-button>
      </template>
    </el-dialog>

    <!-- 模板创建/编辑对话框 -->
    <el-dialog
      v-model="templateDialogVisible"
      :title="templateDialogTitle"
      width="800px"
      @close="resetTemplateForm"
    >
      <el-form
        ref="templateFormRef"
        :model="templateForm"
        :rules="templateFormRules"
        label-width="120px"
      >
        <el-form-item label="模板名称" prop="name">
          <el-input v-model="templateForm.name" placeholder="如：ESP8266-ILI9341" />
        </el-form-item>
        <el-form-item label="设备类型" prop="device_type">
          <el-input v-model="templateForm.device_type" placeholder="如：ESP8266" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="templateForm.description"
            type="textarea"
            :rows="2"
            placeholder="模板描述"
          />
        </el-form-item>
        <el-form-item label="模板代码" prop="template_code">
          <el-input
            v-model="templateForm.template_code"
            type="textarea"
            :rows="15"
            placeholder="Arduino代码模板，支持占位符：{device_id}, {device_name}, {wifi_ssid}, {wifi_password}, {mqtt_server}, {mqtt_username}, {mqtt_password}, {ca_cert}"
            style="font-family: monospace; font-size: 12px;"
          />
        </el-form-item>
        <el-form-item label="启用状态">
          <el-switch v-model="templateForm.is_active" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="templateDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="templateSubmitLoading" @click="submitTemplateForm">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 模板查看对话框 -->
    <el-dialog
      v-model="templateViewDialogVisible"
      title="模板详情"
      width="900px"
    >
      <el-descriptions :column="1" border>
        <el-descriptions-item label="模板名称">
          {{ currentTemplate?.name }}
        </el-descriptions-item>
        <el-descriptions-item label="设备类型">
          {{ currentTemplate?.device_type }}
        </el-descriptions-item>
        <el-descriptions-item label="描述">
          {{ currentTemplate?.description || '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="currentTemplate?.is_active ? 'success' : 'info'">
            {{ currentTemplate?.is_active ? '启用' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">
          {{ formatTime(currentTemplate?.created_at) }}
        </el-descriptions-item>
        <el-descriptions-item label="更新时间">
          {{ formatTime(currentTemplate?.updated_at) }}
        </el-descriptions-item>
      </el-descriptions>
      <el-divider />
      <div>
        <strong>模板代码：</strong>
        <el-input
          :model-value="currentTemplate?.template_code || ''"
          type="textarea"
          :rows="20"
          readonly
          style="font-family: monospace; font-size: 12px; margin-top: 10px;"
        />
      </div>
      <template #footer>
        <el-button @click="templateViewDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 模板上传对话框 -->
    <el-dialog
      v-model="templateUploadDialogVisible"
      title="上传模板文件"
      width="600px"
      @close="resetTemplateUploadForm"
    >
      <el-form
        ref="templateUploadFormRef"
        :model="templateUploadForm"
        :rules="templateUploadFormRules"
        label-width="120px"
      >
        <el-form-item label="模板名称" prop="name">
          <el-input v-model="templateUploadForm.name" placeholder="如：ESP8266-ILI9341" />
        </el-form-item>
        <el-form-item label="设备类型" prop="device_type">
          <el-input v-model="templateUploadForm.device_type" placeholder="如：ESP8266" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="templateUploadForm.description"
            type="textarea"
            :rows="2"
            placeholder="模板描述"
          />
        </el-form-item>
        <el-form-item label="模板文件" prop="file">
          <el-upload
            ref="templateUploadRef"
            :auto-upload="false"
            :limit="1"
            :on-change="handleTemplateFileChange"
            accept=".ino,.cpp,.txt"
          >
            <el-button type="primary">选择文件</el-button>
            <template #tip>
              <div class="el-upload__tip">
                支持 .ino, .cpp, .txt 格式文件
              </div>
            </template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="templateUploadDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="templateUploadLoading" @click="submitTemplateUpload">
          上传
        </el-button>
      </template>
    </el-dialog>

    <!-- 表详情对话框 -->
    <el-dialog
      v-model="tableDetailDialogVisible"
      :title="`表详情 - ${currentTable?.name}`"
      width="900px"
    >
      <el-tabs v-if="currentTable">
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="表名">{{ currentTable.name }}</el-descriptions-item>
            <el-descriptions-item label="大小">{{ currentTable.size }}</el-descriptions-item>
            <el-descriptions-item label="记录数">{{ formatNumber(currentTable.row_count) }}</el-descriptions-item>
            <el-descriptions-item label="索引数">{{ currentTable.index_count }}</el-descriptions-item>
            <el-descriptions-item label="最后更新" :span="2">
              {{ formatTime(currentTable.last_update) }}
            </el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <el-tab-pane label="表结构" name="structure">
          <el-table :data="tableColumns" border style="width: 100%">
            <el-table-column prop="name" label="列名" width="150" />
            <el-table-column prop="type" label="类型" width="150" />
            <el-table-column prop="nullable" label="可空" width="100">
              <template #default="{ row }">
                <el-tag :type="row.nullable ? 'info' : 'success'">
                  {{ row.nullable ? '是' : '否' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="default" label="默认值" />
            <el-table-column prop="primary_key" label="主键" width="100">
              <template #default="{ row }">
                <el-tag v-if="row.primary_key" type="warning">是</el-tag>
                <span v-else>-</span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="索引信息" name="indexes">
          <el-table :data="tableIndexes" border style="width: 100%">
            <el-table-column prop="name" label="索引名" width="200" />
            <el-table-column prop="columns" label="列" />
            <el-table-column prop="unique" label="唯一" width="100">
              <template #default="{ row }">
                <el-tag :type="row.unique ? 'warning' : 'info'">
                  {{ row.unique ? '是' : '否' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Upload, Refresh, DocumentCopy } from '@element-plus/icons-vue'
import request from '@/utils/request'

interface ServerCertInfo {
  id: string
  certificate: string
  private_key: string
  common_name: string
  serial_number: string
  issued_at?: string
  expires_at?: string
  is_active: boolean
  created_at?: string
  updated_at?: string
}

interface DeviceTemplate {
  id: string
  name: string
  device_type: string
  description?: string
  template_code: string
  is_active: boolean
  created_at: string
  updated_at: string
  created_by?: string
}

const activeTab = ref('server-certs')

// 服务器证书相关
const serverCertInfo = ref<ServerCertInfo | null>(null)
const serverCertLoading = ref(false)
const serverCertDialogVisible = ref(false)
const serverCertSubmitLoading = ref(false)
const serverCertFormRef = ref<FormInstance>()
const serverCertForm = ref({
  common_name: 'mosquitto-broker',
  validity_days: 365,
  alt_names: [] as string[],
  alt_names_input: '' as string,
})
const serverCertFormRules: FormRules = {
  common_name: [{ required: true, message: '请输入通用名称', trigger: 'blur' }],
  validity_days: [{ required: true, message: '请输入有效期', trigger: 'blur' }],
}

// 模板管理相关
const templateLoading = ref(false)
const templates = ref<DeviceTemplate[]>([])
const templateDialogVisible = ref(false)
const templateDialogTitle = ref('创建模板')
const templateSubmitLoading = ref(false)
const templateFormRef = ref<FormInstance>()
const templateForm = ref({
  name: '',
  device_type: '',
  description: '',
  template_code: '',
  is_active: true,
})
const templateFormRules: FormRules = {
  name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
  device_type: [{ required: true, message: '请输入设备类型', trigger: 'blur' }],
  template_code: [{ required: true, message: '请输入模板代码', trigger: 'blur' }],
}

const templateViewDialogVisible = ref(false)
const currentTemplate = ref<DeviceTemplate | null>(null)

const templateUploadDialogVisible = ref(false)
const templateUploadLoading = ref(false)
const templateUploadFormRef = ref<FormInstance>()
const templateUploadRef = ref()
const templateUploadForm = ref({
  name: '',
  device_type: '',
  description: '',
  file: null as File | null,
})
const templateUploadFormRules: FormRules = {
  name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
  device_type: [{ required: true, message: '请输入设备类型', trigger: 'blur' }],
}

// 服务器证书相关函数
const fetchServerCert = async () => {
  try {
    serverCertLoading.value = true
    // 从API获取服务器证书信息
    const response = await request.get('/certificates/server')
    serverCertInfo.value = {
      id: response.id,
      certificate: response.certificate,
      private_key: response.private_key,
      common_name: response.common_name,
      serial_number: response.serial_number,
      issued_at: response.issued_at,
      expires_at: response.expires_at,
      is_active: response.is_active,
      created_at: response.created_at,
      updated_at: response.updated_at,
    }
  } catch (error: any) {
    // 如果获取失败（404），说明尚未生成证书，这是正常情况
    if (error.response?.status === 404) {
      serverCertInfo.value = null
      // 404是正常的，不需要输出错误日志
    } else {
      // 其他错误才输出日志
      console.error('获取服务器证书失败:', error)
      ElMessage.error(error.response?.data?.detail || '获取服务器证书失败')
      serverCertInfo.value = null
    }
  } finally {
    serverCertLoading.value = false
  }
}

const handleGenerateServerCert = () => {
  serverCertForm.value = {
    common_name: 'mosquitto-broker',
    validity_days: 365,
    alt_names: [],
    alt_names_input: '',
  }
  serverCertDialogVisible.value = true
}

const resetServerCertForm = () => {
  serverCertFormRef.value?.resetFields()
}

const submitServerCertForm = async () => {
  if (!serverCertFormRef.value) return
  
  try {
    await serverCertFormRef.value.validate()
    serverCertSubmitLoading.value = true
    
    // 解析alt_names（支持逗号、换行、空格分隔）
    const altNames: string[] = []
    if (serverCertForm.value.alt_names_input) {
      const input = serverCertForm.value.alt_names_input
      const lines = input.split(/[,\n]/)
      for (const line of lines) {
        const trimmed = line.trim()
        if (trimmed) {
          altNames.push(trimmed)
        }
      }
    }
    
    const response = await request.post('/certificates/server/generate', {
      common_name: serverCertForm.value.common_name,
      validity_days: serverCertForm.value.validity_days,
      alt_names: altNames.length > 0 ? altNames : undefined,
    })
    
    ElMessage.success('服务器证书生成成功并已保存')
    serverCertDialogVisible.value = false
    
    // 刷新证书信息（从数据库重新获取）
    await fetchServerCert()
  } catch (error: any) {
    const errorMsg = error.response?.data?.detail || error.message || '生成服务器证书失败'
    ElMessage.error(errorMsg)
    // 如果是CA证书不存在，提示用户先生成CA证书
    if (errorMsg.includes('CA证书不存在')) {
      ElMessage.warning('请先点击"生成CA证书"按钮生成CA证书')
    }
  } finally {
    serverCertSubmitLoading.value = false
  }
}

// 复制到剪贴板
const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success('已复制到剪贴板')
  } catch (error) {
    // 如果clipboard API不可用，使用传统方法
    const textArea = document.createElement('textarea')
    textArea.value = text
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand('copy')
      ElMessage.success('已复制到剪贴板')
    } catch (err) {
      ElMessage.error('复制失败，请手动复制')
    }
    document.body.removeChild(textArea)
  }
}

// 模板管理相关函数
const fetchTemplates = async () => {
  try {
    templateLoading.value = true
    const response = await request.get('/templates')
    templates.value = response
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '获取模板列表失败')
  } finally {
    templateLoading.value = false
  }
}

const handleCreateTemplate = () => {
  templateDialogTitle.value = '创建模板'
  templateForm.value = {
    name: '',
    device_type: '',
    description: '',
    template_code: '',
    is_active: true,
  }
  templateDialogVisible.value = true
}

const handleEditTemplate = (template: DeviceTemplate) => {
  templateDialogTitle.value = '编辑模板'
  templateForm.value = {
    name: template.name,
    device_type: template.device_type,
    description: template.description || '',
    template_code: template.template_code,
    is_active: template.is_active,
  }
  currentTemplate.value = template
  templateDialogVisible.value = true
}

const handleViewTemplate = (template: DeviceTemplate) => {
  currentTemplate.value = template
  templateViewDialogVisible.value = true
}

const handleDeleteTemplate = async (template: DeviceTemplate) => {
  try {
    await ElMessageBox.confirm('确定要删除该模板吗？', '确认删除', {
      type: 'warning',
    })
    
    await request.delete(`/templates/${template.id}`)
    ElMessage.success('模板已删除')
    await fetchTemplates()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '删除模板失败')
    }
  }
}

const submitTemplateForm = async () => {
  if (!templateFormRef.value) return
  
  try {
    await templateFormRef.value.validate()
    templateSubmitLoading.value = true
    
    if (currentTemplate.value) {
      await request.put(`/templates/${currentTemplate.value.id}`, templateForm.value)
      ElMessage.success('模板已更新')
    } else {
      await request.post('/templates', templateForm.value)
      ElMessage.success('模板已创建')
    }
    
    templateDialogVisible.value = false
    await fetchTemplates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '操作失败')
  } finally {
    templateSubmitLoading.value = false
  }
}

const resetTemplateForm = () => {
  templateFormRef.value?.resetFields()
  currentTemplate.value = null
}

const handleUploadTemplate = () => {
  templateUploadForm.value = {
    name: '',
    device_type: '',
    description: '',
    file: null,
  }
  templateUploadDialogVisible.value = true
}

const handleTemplateFileChange = (file: any) => {
  templateUploadForm.value.file = file.raw
}

const submitTemplateUpload = async () => {
  if (!templateUploadFormRef.value || !templateUploadForm.value.file) return
  
  try {
    await templateUploadFormRef.value.validate()
    templateUploadLoading.value = true
    
    const formData = new FormData()
    formData.append('file', templateUploadForm.value.file)
    formData.append('name', templateUploadForm.value.name)
    formData.append('device_type', templateUploadForm.value.device_type)
    if (templateUploadForm.value.description) {
      formData.append('description', templateUploadForm.value.description)
    }
    
    await request.post('/templates/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    
    ElMessage.success('模板已上传')
    templateUploadDialogVisible.value = false
    await fetchTemplates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '上传模板失败')
  } finally {
    templateUploadLoading.value = false
  }
}

const resetTemplateUploadForm = () => {
  templateUploadFormRef.value?.resetFields()
  templateUploadRef.value?.clearFiles()
  templateUploadForm.value.file = null
}

// 数据库管理相关接口定义
interface DatabaseOverview {
  connection_pool: {
    current: number
    max: number
    active: number
    idle: number
    usage_percent: number
  }
  database_stats: {
    size: string
    table_count: number
    index_count: number
    total_rows: number
    last_update: string
  }
  performance: {
    avg_query_time: number
    slow_queries: number
    cache_hit_rate: number
    lock_waits: number
  }
}

interface DatabaseTable {
  name: string
  size: string
  row_count: number
  index_count: number
  last_update: string
}

interface QueryResult {
  columns: string[]
  rows: any[]
  execution_time: number
}

interface Backup {
  id: string
  name: string
  size: string
  created_at: string
  status: 'completed' | 'running'
}

// 数据库管理相关状态
const databaseOverview = ref<DatabaseOverview>({
  connection_pool: {
    current: 8,
    max: 20,
    active: 6,
    idle: 2,
    usage_percent: 40,
  },
  database_stats: {
    size: '1.2 GB',
    table_count: 15,
    index_count: 45,
    total_rows: 1000000,
    last_update: new Date().toISOString(),
  },
  performance: {
    avg_query_time: 5,
    slow_queries: 0,
    cache_hit_rate: 0.95,
    lock_waits: 0,
  },
})

const tableLoading = ref(false)
const tableSearch = ref('')
const tables = ref<DatabaseTable[]>([
  { name: 'devices', size: '500 MB', row_count: 10000, index_count: 3, last_update: new Date().toISOString() },
  { name: 'device_certificates', size: '200 MB', row_count: 5000, index_count: 2, last_update: new Date().toISOString() },
  { name: 'users', size: '50 MB', row_count: 100, index_count: 2, last_update: new Date().toISOString() },
  { name: 'device_logs', size: '300 MB', row_count: 500000, index_count: 4, last_update: new Date().toISOString() },
  { name: 'security_events', size: '150 MB', row_count: 200000, index_count: 3, last_update: new Date().toISOString() },
])

const filteredTables = computed(() => {
  if (!tableSearch.value) return tables.value
  return tables.value.filter(table => 
    table.name.toLowerCase().includes(tableSearch.value.toLowerCase())
  )
})

const queryLoading = ref(false)
const sqlQuery = ref('SELECT * FROM devices LIMIT 10')
const queryResult = ref<QueryResult | null>(null)

const backupLoading = ref(false)
const backups = ref<Backup[]>([
  { id: '1', name: 'backup_20240101', size: '1.2 GB', created_at: new Date(Date.now() - 86400000).toISOString(), status: 'completed' },
  { id: '2', name: 'backup_20240102', size: '1.3 GB', created_at: new Date().toISOString(), status: 'completed' },
])

const maintenanceLoading = ref({
  vacuum: false,
  analyze: false,
  reindex: false,
  updateStats: false,
  cleanExpired: false,
  cleanLogs: false,
  cleanTemp: false,
})

// 数据库管理相关函数
const refreshDatabaseOverview = () => {
  // 模拟数据刷新
  databaseOverview.value.connection_pool.current = Math.floor(Math.random() * 15) + 5
  databaseOverview.value.connection_pool.active = databaseOverview.value.connection_pool.current - 2
  databaseOverview.value.connection_pool.idle = databaseOverview.value.connection_pool.current - databaseOverview.value.connection_pool.active
  databaseOverview.value.connection_pool.usage_percent = Math.round(
    (databaseOverview.value.connection_pool.current / databaseOverview.value.connection_pool.max) * 100
  )
  databaseOverview.value.performance.avg_query_time = Math.floor(Math.random() * 10) + 1
  databaseOverview.value.performance.slow_queries = Math.floor(Math.random() * 5)
  ElMessage.success('数据库概览已刷新')
}

const getPoolUsageColor = (percentage: number) => {
  if (percentage < 50) return '#67c23a'
  if (percentage < 80) return '#e6a23c'
  return '#f56c6c'
}

const refreshTableList = () => {
  tableLoading.value = true
  setTimeout(() => {
    tableLoading.value = false
    ElMessage.success('表列表已刷新')
  }, 500)
}

const tableDetailDialogVisible = ref(false)
const currentTable = ref<DatabaseTable | null>(null)
const tableColumns = ref([
  { name: 'id', type: 'uuid', nullable: false, default: null, primary_key: true },
  { name: 'device_id', type: 'varchar(255)', nullable: false, default: null, primary_key: false },
  { name: 'name', type: 'varchar(255)', nullable: true, default: null, primary_key: false },
  { name: 'type', type: 'varchar(50)', nullable: false, default: 'ESP8266', primary_key: false },
  { name: 'status', type: 'varchar(20)', nullable: false, default: 'offline', primary_key: false },
  { name: 'created_at', type: 'timestamp', nullable: false, default: 'CURRENT_TIMESTAMP', primary_key: false },
  { name: 'updated_at', type: 'timestamp', nullable: true, default: null, primary_key: false },
])

const tableIndexes = ref([
  { name: 'ix_devices_device_id', columns: 'device_id', unique: true },
  { name: 'ix_devices_status', columns: 'status', unique: false },
  { name: 'ix_devices_created_at', columns: 'created_at', unique: false },
])

const handleViewTable = (row: DatabaseTable) => {
  currentTable.value = row
  // 模拟加载表结构数据（实际应该从API获取）
  tableDetailDialogVisible.value = true
}

const handleOptimizeTable = async (row: DatabaseTable) => {
  try {
    await ElMessageBox.confirm(
      `确定要优化表 "${row.name}" 吗？此操作可能需要一些时间。`,
      '优化表',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    ElMessage.success(`表 "${row.name}" 优化完成`)
  } catch {
    // 用户取消
  }
}

const executeQuery = () => {
  if (!sqlQuery.value.trim()) {
    ElMessage.warning('请输入SQL查询语句')
    return
  }

  // 检查是否为SELECT查询
  const trimmedQuery = sqlQuery.value.trim().toUpperCase()
  if (!trimmedQuery.startsWith('SELECT')) {
    ElMessage.error('仅支持SELECT查询（只读操作）')
    return
  }

  queryLoading.value = true
  
  // 模拟查询执行
  setTimeout(() => {
    // 模拟查询结果
    queryResult.value = {
      columns: ['id', 'device_id', 'name', 'type', 'status'],
      rows: [
        { id: '1', device_id: 'esp8266-001', name: '温度传感器01', type: 'ESP8266', status: 'online' },
        { id: '2', device_id: 'esp8266-002', name: '温度传感器02', type: 'ESP8266', status: 'offline' },
        { id: '3', device_id: 'esp32-001', name: '湿度传感器01', type: 'ESP32', status: 'online' },
      ],
      execution_time: Math.floor(Math.random() * 50) + 10,
    }
    queryLoading.value = false
    ElMessage.success('查询执行完成')
  }, 1000)
}

const clearQuery = () => {
  sqlQuery.value = ''
  queryResult.value = null
}

const handleCreateBackup = async () => {
  try {
    const { value } = await ElMessageBox.prompt('请输入备份名称', '创建备份', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputPattern: /^[a-zA-Z0-9_-]+$/,
      inputErrorMessage: '备份名称只能包含字母、数字、下划线和连字符',
    })

    if (!value) {
      return
    }

    backupLoading.value = true
    // 模拟备份创建
    setTimeout(() => {
      const backupName = value || `backup_${new Date().toISOString().split('T')[0].replace(/-/g, '')}`
      backups.value.unshift({
        id: Date.now().toString(),
        name: backupName,
        size: '1.2 GB',
        created_at: new Date().toISOString(),
        status: 'completed',
      })
      backupLoading.value = false
      ElMessage.success('备份创建成功')
    }, 2000)
  } catch {
    // 用户取消
  }
}

const handleDownloadBackup = (row: Backup) => {
  ElMessage.info(`下载备份: ${row.name}（功能待实现）`)
}

const handleRestoreBackup = async (row: Backup) => {
  try {
    await ElMessageBox.confirm(
      `确定要恢复备份 "${row.name}" 吗？此操作将覆盖当前数据库，请谨慎操作！`,
      '恢复备份',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    ElMessage.warning('恢复备份功能待实现，需要二次确认')
  } catch {
    // 用户取消
  }
}

const handleDeleteBackup = async (row: Backup) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除备份 "${row.name}" 吗？`,
      '删除备份',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    const index = backups.value.findIndex(b => b.id === row.id)
    if (index > -1) {
      backups.value.splice(index, 1)
      ElMessage.success('备份已删除')
    }
  } catch {
    // 用户取消
  }
}

const handleVacuum = async () => {
  try {
    await ElMessageBox.confirm('确定要执行VACUUM操作吗？', 'VACUUM', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.vacuum = true
    setTimeout(() => {
      maintenanceLoading.value.vacuum = false
      ElMessage.success('VACUUM操作完成')
    }, 2000)
  } catch {
    // 用户取消
  }
}

const handleAnalyze = async () => {
  try {
    await ElMessageBox.confirm('确定要执行ANALYZE操作吗？', 'ANALYZE', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.analyze = true
    setTimeout(() => {
      maintenanceLoading.value.analyze = false
      ElMessage.success('ANALYZE操作完成')
    }, 1500)
  } catch {
    // 用户取消
  }
}

const handleReindex = async () => {
  try {
    await ElMessageBox.confirm('确定要执行REINDEX操作吗？', 'REINDEX', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.reindex = true
    setTimeout(() => {
      maintenanceLoading.value.reindex = false
      ElMessage.success('REINDEX操作完成')
    }, 3000)
  } catch {
    // 用户取消
  }
}

const handleUpdateStats = async () => {
  try {
    await ElMessageBox.confirm('确定要更新统计信息吗？', '更新统计信息', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.updateStats = true
    setTimeout(() => {
      maintenanceLoading.value.updateStats = false
      ElMessage.success('统计信息更新完成')
    }, 1000)
  } catch {
    // 用户取消
  }
}

const handleCleanExpiredData = async () => {
  try {
    await ElMessageBox.confirm('确定要清理过期数据吗？', '清理过期数据', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.cleanExpired = true
    setTimeout(() => {
      maintenanceLoading.value.cleanExpired = false
      ElMessage.success('过期数据清理完成')
    }, 2000)
  } catch {
    // 用户取消
  }
}

const handleCleanLogs = async () => {
  try {
    await ElMessageBox.confirm('确定要清理日志表吗？', '清理日志表', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.cleanLogs = true
    setTimeout(() => {
      maintenanceLoading.value.cleanLogs = false
      ElMessage.success('日志表清理完成')
    }, 2000)
  } catch {
    // 用户取消
  }
}

const handleCleanTempData = async () => {
  try {
    await ElMessageBox.confirm('确定要清理临时数据吗？', '清理临时数据', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    maintenanceLoading.value.cleanTemp = true
    setTimeout(() => {
      maintenanceLoading.value.cleanTemp = false
      ElMessage.success('临时数据清理完成')
    }, 1500)
  } catch {
    // 用户取消
  }
}

const formatNumber = (num: number) => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(2) + 'M'
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(2) + 'K'
  }
  return num.toString()
}

const formatTime = (time: string | undefined) => {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchServerCert()
  fetchTemplates()
  // 初始化数据库概览数据
  refreshDatabaseOverview()
})
</script>

<style scoped>
.security-page {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
}
</style>

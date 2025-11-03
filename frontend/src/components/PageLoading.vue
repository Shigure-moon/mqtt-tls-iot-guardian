&lt;template&gt;
  <div v-if="loading" class="page-loading">
    <el-card class="loading-card" :body-style="{ padding: '24px' }">
      <div class="loading-content">
        <el-icon class="loading-icon"><Loading /></el-icon>
        <div class="loading-text">{{ text }}</div>
      </div>
    </el-card>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { Loading } from '@element-plus/icons-vue'

defineProps({
  loading: {
    type: Boolean,
    default: false
  },
  text: {
    type: String,
    default: '加载中...'
  }
})
</script>

<style lang="scss" scoped>
.page-loading {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.9);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;

  .loading-card {
    min-width: 200px;
    border-radius: 4px;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  }

  .loading-content {
    text-align: center;

    .loading-icon {
      font-size: 24px;
      color: #1890ff;
      animation: rotate 1s linear infinite;
    }

    .loading-text {
      margin-top: 12px;
      color: #666;
      font-size: 14px;
    }
  }
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
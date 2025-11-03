&lt;template&gt;
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <img src="@/assets/logo.svg" alt="Logo" class="logo" />
        <h1>{{ $t('common.welcome') }}</h1>
      </div>
      
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        class="login-form"
        @keyup.enter="handleSubmit"
      >
        <el-form-item prop="username">
          <el-input
            v-model="formData.username"
            :placeholder="$t('auth.username')"
            prefix-icon="User"
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="formData.password"
            type="password"
            :placeholder="$t('auth.password')"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item class="login-options">
          <el-checkbox v-model="rememberMe">
            {{ $t('auth.remember_me') }}
          </el-checkbox>
          <el-link type="primary" :underline="false">
            {{ $t('auth.forgot_password') }}
          </el-link>
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            class="login-button"
            :loading="loading"
            @click="handleSubmit"
          >
            {{ $t('auth.login') }}
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
&lt;/template&gt;

<script lang="ts" setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import type { FormInstance } from 'element-plus'
import type { LoginData } from '@/types/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const formRef = ref<FormInstance>()
const loading = ref(false)
const rememberMe = ref(false)

const formData = ref<LoginData>({
  username: '',
  password: ''
})

// 表单验证规则
const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符', trigger: 'blur' }
  ]
}

// 处理登录提交
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      loading.value = true
      await userStore.login(formData.value.username, formData.value.password)
      
      // 如果有重定向地址，跳转到重定向地址
      const redirect = route.query.redirect as string
      router.replace(redirect || '/')
      
      ElMessage.success('登录成功')
    } catch (error: any) {
      ElMessage.error(error.message || '登录失败')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style lang="scss" scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #1890ff 0%, #001529 100%);
  
  .login-box {
    width: 400px;
    padding: 40px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
    
    .login-header {
      text-align: center;
      margin-bottom: 40px;
      
      .logo {
        width: 80px;
        margin-bottom: 16px;
      }
      
      h1 {
        font-size: 24px;
        color: #1890ff;
        margin: 0;
      }
    }
    
    .login-form {
      .login-options {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .login-button {
        width: 100%;
      }
    }
  }
}
</style>
import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: {
      requiresAuth: false,
      title: '登录',
    },
  },
  {
    path: '/',
    component: () => import('@/layout/index.vue'),
    redirect: '/dashboard',
    meta: {
      requiresAuth: true,
    },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: {
          title: '仪表盘',
          icon: 'DataAnalysis',
        },
      },
      {
        path: 'devices',
        name: 'Devices',
        component: () => import('@/views/devices/list.vue'),
        meta: {
          title: '设备管理',
          icon: 'Monitor',
        },
      },
      {
        path: 'devices/:id',
        name: 'DeviceDetail',
        component: () => import('@/views/devices/detail.vue'),
        meta: {
          title: '设备详情',
          hidden: true,
        },
      },
      {
        path: 'monitoring',
        name: 'Monitoring',
        component: () => import('@/views/monitoring/dashboards.vue'),
        meta: {
          title: '监控告警',
          icon: 'Bell',
        },
      },
      {
        path: 'security',
        name: 'Security',
        component: () => import('@/views/security/index.vue'),
        meta: {
          title: '安全管理',
          icon: 'Lock',
          requiresAdmin: true,  // 需要超级管理员权限
        },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()
  
  // 检查是否需要认证
  if (to.meta.requiresAuth && !userStore.isLoggedIn) {
    next('/login')
    return
  }
  
  // 检查是否需要管理员权限
  if (to.meta.requiresAdmin && !userStore.userInfo?.is_admin) {
    ElMessage.warning('权限不足：需要超级管理员权限')
    next('/dashboard')
    return
  }
  
  // 如果已登录，访问登录页则跳转到首页
  if (to.path === '/login' && userStore.isLoggedIn) {
    next('/')
    return
  }
  
  // 设置页面标题
  if (to.meta.title) {
    document.title = `${to.meta.title} - IoT安全管理系统`
  }
  
  next()
})

export default router


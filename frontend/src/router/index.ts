import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

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


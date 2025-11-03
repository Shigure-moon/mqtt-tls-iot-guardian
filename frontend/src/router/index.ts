import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'
import NProgress from 'nprogress'
import 'nprogress/nprogress.css'

// 基础路由
export const baseRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: {
      title: '登录',
      isPublic: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    meta: {
      title: '404',
      isPublic: true
    }
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHistory(import.meta.env.VITE_APP_BASE_PATH),
  routes: baseRoutes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// 白名单
const WHITE_LIST = ['/login']

// 路由守卫
router.beforeEach(async (to, from, next) => {
  NProgress.start()
  
  // 设置页面标题
  const title = to.meta.title
    ? `${to.meta.title} - ${import.meta.env.VITE_APP_TITLE}`
    : import.meta.env.VITE_APP_TITLE
  document.title = title

  const userStore = useUserStore()
  const token = userStore.token

  // 白名单直接通过
  if (WHITE_LIST.includes(to.path)) {
    next()
    return
  }

  // 检查是否登录
  if (!token) {
    next({
      path: '/login',
      query: {
        redirect: to.fullPath
      }
    })
    return
  }

  // 检查用户信息
  if (!userStore.userInfo) {
    try {
      await userStore.getUserInfo()
      next({ ...to, replace: true })
    } catch (error) {
      userStore.logout()
      next({
        path: '/login',
        query: {
          redirect: to.fullPath
        }
      })
    }
    return
  }

  next()
})

router.afterEach(() => {
  NProgress.done()
})

export default router
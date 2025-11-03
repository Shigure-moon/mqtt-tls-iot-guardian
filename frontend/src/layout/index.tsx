import { defineComponent, ref } from 'vue'
import { RouterView, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'

export default defineComponent({
  name: 'AppLayout',
  setup() {
    const router = useRouter()
    const userStore = useUserStore()
    const collapsed = ref(false)

    // 获取用户可访问的路由
    const getAccessibleRoutes = () => {
      return router.options.routes.filter(route => {
        if (route.meta?.roles) {
          return route.meta.roles.some(role => userStore.userInfo?.roles.includes(role))
        }
        return true
      })
    }

    // 生成菜单
    const generateMenus = () => {
      return getAccessibleRoutes().filter(route => route.path !== '/login')
    }

    // 切换菜单折叠状态
    const toggleCollapsed = () => {
      collapsed.value = !collapsed.value
    }

    // 退出登录
    const handleLogout = async () => {
      userStore.logout()
      router.push('/login')
    }

    return () => (
      <div class="app-layout">
        <aside class={['sidebar', { collapsed: collapsed.value }]}>
          <div class="logo">
            <img src="@/assets/logo.svg" alt="Logo" />
            {!collapsed.value && <span>LST DEMO</span>}
          </div>
          <div class="menu">
            {generateMenus().map(route => (
              <div class="menu-item" key={route.path}>
                <router-link to={route.path}>
                  <i class={`icon ${route.meta?.icon}`} />
                  {!collapsed.value && <span>{route.meta?.title}</span>}
                </router-link>
              </div>
            ))}
          </div>
        </aside>
        
        <div class="main-content">
          <header class="header">
            <div class="header-left">
              <button class="collapse-btn" onClick={toggleCollapsed}>
                <i class={`icon ${collapsed.value ? 'menu-unfold' : 'menu-fold'}`} />
              </button>
            </div>
            <div class="header-right">
              <div class="user-info">
                <span class="username">{userStore.userInfo?.username}</span>
                <button class="logout-btn" onClick={handleLogout}>
                  退出登录
                </button>
              </div>
            </div>
          </header>
          
          <main class="content">
            <RouterView />
          </main>
        </div>
      </div>
    )
  }
})
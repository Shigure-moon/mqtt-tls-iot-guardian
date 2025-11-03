import { defineComponent, type PropType } from 'vue'
import { useUserStore } from '@/stores/user'

export default defineComponent({
  name: 'AuthGuard',
  props: {
    permission: {
      type: String,
      required: false
    },
    role: {
      type: String,
      required: false
    },
    any: {
      type: Array as PropType<string[]>,
      required: false
    },
    all: {
      type: Array as PropType<string[]>,
      required: false
    }
  },
  setup(props, { slots }) {
    const userStore = useUserStore()

    const hasAccess = () => {
      // 如果没有指定任何权限要求，则允许访问
      if (!props.permission && !props.role && !props.any && !props.all) {
        return true
      }

      // 检查单个权限
      if (props.permission && !userStore.hasPermission(props.permission)) {
        return false
      }

      // 检查角色
      if (props.role && !userStore.userInfo?.roles.includes(props.role)) {
        return false
      }

      // 检查任意一个权限
      if (props.any && !props.any.some(p => userStore.hasPermission(p))) {
        return false
      }

      // 检查所有权限
      if (props.all && !props.all.every(p => userStore.hasPermission(p))) {
        return false
      }

      return true
    }

    return () => hasAccess() ? slots.default?.() : null
  }
})
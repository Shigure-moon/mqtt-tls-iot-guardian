import { createI18n } from 'vue-i18n'
import { useAppStore } from '@/stores/app'

// 导入语言包
const modules = import.meta.glob('./lang/*.json', { eager: true })
const pagesModules = import.meta.glob('./pages/**/*.json', { eager: true })

const messages: any = {}

// 处理核心语言包
for (const path in modules) {
  const key = path.match(/\.\/lang\/(.+)\.json/)![1]
  messages[key] = modules[path].default
}

// 处理页面语言包
for (const path in pagesModules) {
  const keys = path.match(/\.\/pages\/(.+)\/(.+)\.json/)!
  const namespace = keys[1]
  const lang = keys[2]
  
  if (!messages[lang]) {
    messages[lang] = {}
  }
  
  messages[lang][namespace] = pagesModules[path].default
}

// 创建i18n实例
const i18n = createI18n({
  legacy: false,
  locale: useAppStore().language || 'zh-cn',
  fallbackLocale: 'zh-cn',
  messages,
})

export default i18n

// 导出t函数方便直接使用
export const t = i18n.global.t
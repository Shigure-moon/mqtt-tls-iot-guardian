/**
 * 本地存储工具类
 */

// 获取存储项
export function getStorageItem(key: string): any {
  try {
    const item = localStorage.getItem(key)
    return item ? JSON.parse(item) : null
  } catch (e) {
    console.error(`Error getting storage item ${key}:`, e)
    return null
  }
}

// 设置存储项
export function setStorageItem(key: string, value: any): void {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch (e) {
    console.error(`Error setting storage item ${key}:`, e)
  }
}

// 移除存储项
export function removeStorageItem(key: string): void {
  try {
    localStorage.removeItem(key)
  } catch (e) {
    console.error(`Error removing storage item ${key}:`, e)
  }
}

// 清除所有存储
export function clearStorage(): void {
  try {
    localStorage.clear()
  } catch (e) {
    console.error('Error clearing storage:', e)
  }
}

// 会话存储相关方法
export function getSessionItem(key: string): any {
  try {
    const item = sessionStorage.getItem(key)
    return item ? JSON.parse(item) : null
  } catch (e) {
    console.error(`Error getting session item ${key}:`, e)
    return null
  }
}

export function setSessionItem(key: string, value: any): void {
  try {
    sessionStorage.setItem(key, JSON.stringify(value))
  } catch (e) {
    console.error(`Error setting session item ${key}:`, e)
  }
}

export function removeSessionItem(key: string): void {
  try {
    sessionStorage.removeItem(key)
  } catch (e) {
    console.error(`Error removing session item ${key}:`, e)
  }
}

export function clearSession(): void {
  try {
    sessionStorage.clear()
  } catch (e) {
    console.error('Error clearing session:', e)
  }
}
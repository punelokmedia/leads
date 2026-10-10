import { useSyncExternalStore } from 'react'

export const notifyUserSessionChanged = () => window.dispatchEvent(new Event('user-session-changed'))
const subscribe = (listener: () => void) => {
  window.addEventListener('storage', listener)
  window.addEventListener('user-session-changed', listener)
  return () => {
    window.removeEventListener('storage', listener)
    window.removeEventListener('user-session-changed', listener)
  }
}
export const useUserToken = () => useSyncExternalStore(subscribe, () => localStorage.getItem('user_token'), () => null)

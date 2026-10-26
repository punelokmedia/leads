import { useSyncExternalStore } from 'react'

const rememberSignIn = () => {
  if (localStorage.getItem('user_token')) localStorage.setItem('has_signed_in', '1')
}
export const notifyUserSessionChanged = () => {
  rememberSignIn()
  window.dispatchEvent(new Event('user-session-changed'))
}
const subscribe = (listener: () => void) => {
  rememberSignIn()
  window.addEventListener('storage', listener)
  window.addEventListener('user-session-changed', listener)
  return () => {
    window.removeEventListener('storage', listener)
    window.removeEventListener('user-session-changed', listener)
  }
}
export const useUserToken = () => useSyncExternalStore(subscribe, () => localStorage.getItem('user_token'), () => null)

import { API_BASE_URL } from '@/config/api'
import { notifyUserSessionChanged } from './useUserToken'

export const SESSION_MESSAGE = 'Your session has expired. Please sign in again to access your account.'

// Only application requests use this wrapper; external downloads remain untouched.
export async function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const url = new URL(input instanceof Request ? input.url : String(input), window.location.origin)
  if (url.origin !== new URL(API_BASE_URL).origin || !url.pathname.startsWith('/api/v1/')) return fetch(input, init)
  const headers = new Headers(init?.headers ?? (input instanceof Request ? input.headers : undefined))
  headers.set('X-Web-Session', '1')
  const sentToken = headers.get('Authorization')?.replace(/^Bearer /, '')
  const storedToken = localStorage.getItem('user_token')
  // Components can retain an earlier token after a silent renewal.
  if (sentToken && storedToken) headers.set('Authorization', `Bearer ${storedToken}`)
  const response = await fetch(input, { ...init, headers })
  const currentToken = localStorage.getItem('user_token')
  // Ignore responses from a session that was logged out or replaced meanwhile.
  if (sentToken && storedToken && currentToken === storedToken) {
    const renewedToken = response.headers.get('X-Session-Token')
    if (response.ok && renewedToken) localStorage.setItem('user_token', renewedToken)
    if (response.status === 401) {
      const payload = await response.clone().json().catch(() => null)
      if (['SESSION_REQUIRED', 'SESSION_INVALID', 'SESSION_REVOKED', 'SESSION_EXPIRED'].includes(payload?.code)) {
        localStorage.removeItem('user_token')
        localStorage.removeItem('user_profile')
        sessionStorage.setItem('session_expired', '1')
        notifyUserSessionChanged()
      }
    }
  }
  return response
}

import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import { useUserToken } from './useUserToken'
import { apiFetch, SESSION_MESSAGE } from './session'

export function SessionNotice() {
  const token = useUserToken()
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const [checkingError, setCheckingError] = useState('')
  const signedIn = Boolean(token)
  useEffect(() => {
    if (!signedIn) return
    let checking = false
    let disposed = false
    const validate = async () => {
      const current = localStorage.getItem('user_token')
      if (checking || !current || document.visibilityState === 'hidden') return
      checking = true
      try {
        const response = await apiFetch(`${API_BASE_URL}/api/v1/auth/profile`, {
          headers: { Authorization: `Bearer ${current}` }, cache: 'no-store', signal: AbortSignal.timeout(15000),
        })
        if (!disposed) setCheckingError(response.status >= 500 ? 'Unable to check your session. Please try again.' : '')
      } catch { if (!disposed) setCheckingError('Unable to reach the server. Check your connection and try again.') }
      finally { checking = false }
    }
    void validate()
    window.addEventListener('focus', validate)
    document.addEventListener('visibilitychange', validate)
    return () => { disposed = true; window.removeEventListener('focus', validate); document.removeEventListener('visibilitychange', validate) }
  }, [signedIn])
  useEffect(() => { if (signedIn) sessionStorage.removeItem('session_expired') }, [signedIn])
  const expired = !token && sessionStorage.getItem('session_expired') === '1'
  useEffect(() => {
    if (expired && pathname !== '/auth/mobile') navigate('/login?reason=session-expired', { replace: true })
  }, [expired, navigate, pathname])
  if (!expired && !checkingError) return null
  return <div role="alert" className="border-b border-amber-200 bg-amber-50 px-4 py-3 text-center text-sm text-amber-900">
    {expired ? SESSION_MESSAGE : checkingError}{expired && <> <Link to="/login" className="font-bold underline">Sign in</Link></>}
  </div>
}

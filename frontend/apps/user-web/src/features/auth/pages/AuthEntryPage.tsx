import { Navigate, useSearchParams } from 'react-router-dom'
import { MobileAuthDrawerPage } from './MobileAuthDrawerPage'

export function AuthEntryPage() {
  const [params] = useSearchParams()
  if (params.get('method') === 'phone' || ['google', 'membership'].includes(params.get('flow') || '')) return <MobileAuthDrawerPage />
  return <Navigate to={`/login${params.size ? `?${params}` : ''}`} replace />
}

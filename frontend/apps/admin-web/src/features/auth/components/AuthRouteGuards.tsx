import { Navigate, Outlet } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

export function ProtectedAdminRoute() {
  const { isAuthenticated } = useAdminAuth()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return <Outlet />
}

export function PublicOnlyRoute() {
  const { isAuthenticated } = useAdminAuth()

  if (isAuthenticated) {
    return <Navigate to="/" replace />
  }

  return <Outlet />
}

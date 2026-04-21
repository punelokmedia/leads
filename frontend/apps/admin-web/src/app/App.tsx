import { RouterProvider } from 'react-router-dom'
import { router } from '@/app/router'
import { AdminAuthProvider } from '@/features/auth/context/AdminAuthContext'
import { ToastProvider } from '@/components/feedback/ToastProvider'

export function App() {
  return (
    <AdminAuthProvider>
      <ToastProvider>
        <RouterProvider router={router} />
      </ToastProvider>
    </AdminAuthProvider>
  )
}

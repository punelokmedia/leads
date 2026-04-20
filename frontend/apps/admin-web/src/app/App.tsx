import { RouterProvider } from 'react-router-dom'
import { router } from '@/app/router'
import { AdminAuthProvider } from '@/features/auth/context/AdminAuthContext'

export function App() {
  return (
    <AdminAuthProvider>
      <RouterProvider router={router} />
    </AdminAuthProvider>
  )
}

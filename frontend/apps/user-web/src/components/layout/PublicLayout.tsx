import { Outlet } from 'react-router-dom'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { PublicHeader } from '@/components/layout/PublicHeader'

export function PublicLayout() {
  return (
    <div className="flex min-h-dvh flex-col">
      <PublicHeader />
      <main id="account-page-content" className="flex-1">
        <Outlet />
      </main>
      <PublicFooter />
    </div>
  )
}

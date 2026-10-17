import { Outlet } from 'react-router-dom'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { SessionNotice } from '@/features/auth/SessionNotice'

export function PublicLayout() {
  return (
    <div className="flex min-h-dvh flex-col">
      <PublicHeader />
      <SessionNotice />
      <main id="account-page-content" className="flex-1">
        <Outlet />
      </main>
      <PublicFooter />
    </div>
  )
}

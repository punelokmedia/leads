import '@/features/home/pages/home.css'
import { Outlet, useLocation } from 'react-router-dom'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { HomeHeader } from '@/components/layout/HomeHeader'
import { SessionNotice } from '@/features/auth/SessionNotice'
import { useUserToken } from '@/features/auth/useUserToken'

export function PublicLayout() {
  const location = useLocation()
  const isHomepage = location.pathname === '/' && !location.search
  const userToken = useUserToken()
  const showHomeHeader = isHomepage && !userToken
  return (
    <div className={`flex min-h-dvh flex-col ${showHomeHeader ? 'homepage-layout' : ''}`}>
      {showHomeHeader && <HomeHeader />}
      <PublicHeader />
      <SessionNotice />
      <main id="account-page-content" className="flex-1">
        <Outlet />
      </main>
      <PublicFooter />
    </div>
  )
}

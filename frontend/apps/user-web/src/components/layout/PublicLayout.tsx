import { useEffect, useRef } from 'react'
import './motion.css'
import { LoginRequired } from '@/features/auth/LoginRequired'
import { requiresLogin, safeReturnPath } from '@/features/auth/access-policy'
import '@/features/home/pages/home.css'
import { Outlet, useLocation, useNavigate, useNavigation } from 'react-router-dom'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { HomeHeader } from '@/components/layout/HomeHeader'
import { SessionNotice } from '@/features/auth/SessionNotice'
import { useUserToken } from '@/features/auth/useUserToken'

export function PublicLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const navigation = useNavigation()
  const userToken = useUserToken()
  const content = useRef<HTMLElement>(null)
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    const animation = content.current?.animate?.(
      [{ opacity: 0.35 }, { opacity: 1 }],
      { duration: 320, easing: 'ease-out' },
    )
    return () => animation?.cancel()
  }, [location.pathname])
  const locked = !userToken && requiresLogin(location.pathname, location.search)
  useEffect(() => {
    if (!userToken || location.pathname !== '/' || location.search) return
    const target = safeReturnPath(sessionStorage.getItem('login_return_to'))
    sessionStorage.removeItem('login_return_to')
    if (target) navigate(target, { replace: true })
  }, [userToken, location.pathname, location.search, navigate])
  const showHomeHeader = !userToken
  return (
    <div className={`flex min-h-dvh flex-col ${showHomeHeader ? 'homepage-layout' : ''}`}>
      {navigation.state !== 'idle' && <div className="navigation-progress" role="status" aria-label="Loading page" />}
      {showHomeHeader && <HomeHeader />}
      <PublicHeader />
      <SessionNotice />
      <main ref={content} id="account-page-content" className="flex-1">
        {locked ? <LoginRequired returnTo={location.pathname + location.search} /> : <Outlet />}
      </main>
      <PublicFooter />
    </div>
  )
}

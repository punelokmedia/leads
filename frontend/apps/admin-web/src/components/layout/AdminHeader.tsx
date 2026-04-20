import { NavLink, useLocation } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

type MobileNavItem = { to: string; label: string; end?: boolean }

const mobileNav: MobileNavItem[] = [
  { to: '/', label: 'Home', end: true },
  { to: '/leads', label: 'Leads' },
  { to: '/settings', label: 'Settings' },
]

type AdminHeaderProps = {
  onMenuToggle: () => void
}

export function AdminHeader({ onMenuToggle }: AdminHeaderProps) {
  const location = useLocation()
  const { userEmail, logout } = useAdminAuth()

  const pageTitle =
    location.pathname === '/'
      ? 'Dashboard'
      : location.pathname.slice(1).replace('-', ' ')

  return (
    <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur-md">
      <div className="flex h-16 items-center justify-between gap-3 px-4 md:px-8">
        <div className="flex min-w-0 flex-1 items-center gap-2 md:gap-5">
          <button
            type="button"
            onClick={onMenuToggle}
            className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-slate-300 text-slate-700 hover:bg-slate-100 md:hidden"
            aria-label="Open navigation menu"
          >
            ≡
          </button>
          <span className="shrink-0 text-sm font-semibold text-slate-900 md:hidden">
            Leads Sell
          </span>
          <div className="hidden min-w-0 md:block">
            <p className="text-xs uppercase tracking-wide text-slate-500">
              Admin panel
            </p>
            <p className="truncate text-sm font-semibold capitalize text-slate-900">
              {pageTitle}
            </p>
          </div>
          <nav className="-mx-1 flex min-w-0 gap-0.5 overflow-x-auto px-1 md:hidden">
            {mobileNav.map(({ to, label, end }) => (
              <NavLink
                key={to}
                to={to}
                end={end}
                className={({ isActive }) =>
                  [
                    'shrink-0 rounded-lg px-2.5 py-1.5 text-xs font-medium',
                    isActive
                      ? 'bg-violet-600 text-white'
                      : 'text-slate-500',
                  ].join(' ')
                }
              >
                {label}
              </NavLink>
            ))}
          </nav>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <div className="hidden rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5 md:block">
            <p className="max-w-44 truncate text-xs text-slate-600">{userEmail}</p>
          </div>
          <NavLink
            to="/settings"
            className="rounded-lg px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-900"
          >
            Account
          </NavLink>
          <button
            type="button"
            onClick={logout}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 hover:border-slate-400 hover:bg-slate-100"
          >
            Logout
          </button>
        </div>
      </div>
    </header>
  )
}

import { NavLink, useLocation } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

type MobileNavItem = { to: string; label: string; end?: boolean }

const mobileNav: MobileNavItem[] = [
  { to: '/', label: 'Home', end: true },
  { to: '/leads', label: 'Leads' },
  { to: '/web-analytics', label: 'Analytics' },
  { to: '/payments', label: 'Payments' },
  { to: '/admins/add', label: 'Admins' },
  { to: '/leads?create=1', label: 'Create' },
  { to: '/categories', label: 'Category' },
  { to: '/settings', label: 'Settings' },
]

type AdminHeaderProps = {
  onMenuToggle: () => void
}

export function AdminHeader({ onMenuToggle }: AdminHeaderProps) {
  const location = useLocation()
  const { userEmail, logout } = useAdminAuth()

  const activeSectionLabel =
    location.pathname === '/'
      ? 'Dashboard'
      : location.pathname === '/leads'
        ? location.search.includes('upload=1')
          ? 'Bulk Upload'
          : location.search.includes('create=1')
            ? 'Create Lead'
            : 'Leads'
        : location.pathname === '/categories'
          ? location.search.includes('create=1')
            ? 'Add Category'
            : 'Categories'
          : location.pathname.slice(1).replace('-', ' ')

  const greeting = (() => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 18) return 'Good afternoon'
    return 'Good evening'
  })()

  return (
    <header className="sticky top-0 z-20 border-b border-slate-200/80 bg-white/80 shadow-sm backdrop-blur-xl">
      <div className="h-0.5 w-full bg-gradient-to-r from-violet-500 via-indigo-500 to-sky-500" />
      <div className="flex min-h-16 items-center justify-between gap-3 px-4 py-2 md:px-8">
        <div className="flex min-w-0 flex-1 items-center gap-2 md:gap-5">
          <button
            type="button"
            onClick={onMenuToggle}
            className="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-slate-300 text-slate-700 transition-all duration-200 hover:border-violet-300 hover:bg-violet-50 md:hidden"
            aria-label="Open navigation menu"
          >
            ≡
          </button>
          <span className="shrink-0 text-sm font-semibold text-slate-900 md:hidden">
            Leads Sell
          </span>
          <div className="hidden min-w-0 md:block">
            <p className="text-xs uppercase tracking-wide text-violet-600">
              Admin panel
            </p>
            <p className="truncate text-sm font-semibold capitalize text-slate-900">
              {activeSectionLabel}
            </p>
          </div>
          <nav className="-mx-1 flex min-w-0 gap-1 overflow-x-auto px-1 md:hidden">
            {mobileNav.map(({ to, label, end }) => (
              <NavLink
                key={to}
                to={to}
                end={end}
                className={({ isActive }) =>
                  [
                    'shrink-0 rounded-xl border px-2.5 py-1.5 text-xs font-medium transition-all duration-200',
                    isActive
                      ? 'border-violet-600 bg-gradient-to-r from-violet-600 to-indigo-600 text-white shadow-sm'
                      : 'border-slate-200 bg-white text-slate-500 hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700',
                  ].join(' ')
                }
              >
                {label}
              </NavLink>
            ))}
          </nav>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <div className="hidden rounded-xl border border-slate-200 bg-white px-3 py-1.5 shadow-sm md:block">
            <p className="text-[11px] font-medium text-slate-500">{greeting}</p>
            <p className="max-w-44 truncate text-xs font-semibold text-slate-700">{userEmail}</p>
          </div>
          <div className="hidden items-center gap-1 md:flex">
            <NavLink
              to="/leads?create=1"
              className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600 transition-all duration-200 hover:-translate-y-0.5 hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700"
            >
              + Lead
            </NavLink>
            <NavLink
              to="/leads?upload=1"
              className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600 transition-all duration-200 hover:-translate-y-0.5 hover:border-indigo-200 hover:bg-indigo-50 hover:text-indigo-700"
            >
              Upload
            </NavLink>
            <NavLink
              to="/categories?create=1"
              className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600 transition-all duration-200 hover:-translate-y-0.5 hover:border-sky-200 hover:bg-sky-50 hover:text-sky-700"
            >
              + Category
            </NavLink>
          </div>
          <NavLink
            to="/settings"
            className="rounded-xl border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-600 transition-all duration-200 hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700"
          >
            Account
          </NavLink>
          <button
            type="button"
            onClick={logout}
            className="rounded-xl border border-slate-300 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 transition-all duration-200 hover:border-rose-300 hover:bg-rose-50 hover:text-rose-700"
          >
            Logout
          </button>
        </div>
      </div>
    </header>
  )
}

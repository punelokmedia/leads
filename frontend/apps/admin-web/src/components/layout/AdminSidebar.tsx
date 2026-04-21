import { NavLink, useLocation } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

type AdminNavItem = {
  to: string
  label: string
  end?: boolean
  icon: 'dashboard' | 'leads' | 'settings' | 'create' | 'category' | 'admin' | 'payment' | 'analytics'
  hint?: string
}

const primaryNav: AdminNavItem[] = [
  { to: '/', label: 'Dashboard', end: true, icon: 'dashboard', hint: 'Overview' },
  { to: '/leads', label: 'Leads', icon: 'leads', hint: 'Records' },
  { to: '/leads?create=1', label: 'Create Lead', icon: 'create', hint: 'Open side form' },
  { to: '/leads?upload=1', label: 'Bulk Upload', icon: 'create', hint: 'Excel upload' },
  { to: '/categories', label: 'Categories', icon: 'category', hint: 'Category manager' },
  { to: '/categories?create=1', label: 'Add Category', icon: 'create', hint: 'Open side form' },
  { to: '/admins/add', label: 'Add Admin', icon: 'admin', hint: 'Promote user role' },
  { to: '/web-analytics', label: 'Web Analytics', icon: 'analytics', hint: 'Charts & trends' },
  { to: '/payments', label: 'Payment History', icon: 'payment', hint: 'Transaction logs' },
]

type AdminSidebarProps = {
  isOpen: boolean
  onClose: () => void
}

export function AdminSidebar({ isOpen, onClose }: AdminSidebarProps) {
  const { userEmail, logout } = useAdminAuth()
  const location = useLocation()

  function renderIcon(icon: AdminNavItem['icon']) {
    const iconClass = 'h-4 w-4'

    if (icon === 'dashboard') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path d="M4 4h7v7H4V4Zm9 0h7v4h-7V4Zm0 6h7v10h-7V10Zm-9 3h7v7H4v-7Z" fill="currentColor" />
        </svg>
      )
    }
    if (icon === 'leads') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path d="M4 6h16M4 12h12M4 18h10" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
      )
    }
    if (icon === 'settings') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path d="M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z" stroke="currentColor" strokeWidth="1.7" />
          <path d="M19.4 15.1a1 1 0 0 0 .2 1.1l.1.1a1.3 1.3 0 0 1 0 1.8l-.7.7a1.3 1.3 0 0 1-1.8 0l-.1-.1a1 1 0 0 0-1.1-.2 1 1 0 0 0-.6.9V20a1.3 1.3 0 0 1-1.3 1.3h-1a1.3 1.3 0 0 1-1.3-1.3v-.2a1 1 0 0 0-.7-1 1 1 0 0 0-1.1.2l-.1.1a1.3 1.3 0 0 1-1.8 0l-.7-.7a1.3 1.3 0 0 1 0-1.8l.1-.1a1 1 0 0 0 .2-1.1 1 1 0 0 0-.9-.6H4a1.3 1.3 0 0 1-1.3-1.3v-1A1.3 1.3 0 0 1 4 11h.2a1 1 0 0 0 1-.7 1 1 0 0 0-.2-1.1l-.1-.1a1.3 1.3 0 0 1 0-1.8l.7-.7a1.3 1.3 0 0 1 1.8 0l.1.1a1 1 0 0 0 1.1.2 1 1 0 0 0 .6-.9V4A1.3 1.3 0 0 1 10.5 2.7h1A1.3 1.3 0 0 1 12.8 4v.2a1 1 0 0 0 .7 1 1 1 0 0 0 1.1-.2l.1-.1a1.3 1.3 0 0 1 1.8 0l.7.7a1.3 1.3 0 0 1 0 1.8l-.1.1a1 1 0 0 0-.2 1.1 1 1 0 0 0 .9.6H20a1.3 1.3 0 0 1 1.3 1.3v1A1.3 1.3 0 0 1 20 12.8h-.2a1 1 0 0 0-1 .7Z" stroke="currentColor" strokeWidth="1.2" />
        </svg>
      )
    }
    if (icon === 'create') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
      )
    }
    if (icon === 'admin') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path
            d="M12 12a3.25 3.25 0 1 0 0-6.5 3.25 3.25 0 0 0 0 6.5ZM6 19.5a6 6 0 0 1 12 0"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
          />
          <path d="M19 8v4M17 10h4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
      )
    }
    if (icon === 'payment') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <rect x="3.5" y="6" width="17" height="12" rx="2.5" stroke="currentColor" strokeWidth="1.6" />
          <path d="M3.5 10h17" stroke="currentColor" strokeWidth="1.6" />
          <path d="M7 14h4" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
      )
    }
    if (icon === 'analytics') {
      return (
        <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
          <path d="M4 19h16" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          <path d="M7 15v-4M12 15V7M17 15v-6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
      )
    }
    return (
      <svg viewBox="0 0 24 24" fill="none" className={iconClass} aria-hidden="true">
        <path d="M4 7h16M4 12h16M4 17h10" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      </svg>
    )
  }

  function resolveItemActive(item: AdminNavItem, isActive: boolean) {
    if (item.to === '/leads') return location.pathname === '/leads'
    if (item.to === '/categories') return location.pathname === '/categories'
    if (item.to === '/admins/add') return location.pathname === '/admins/add'
    if (item.to === '/web-analytics') return location.pathname === '/web-analytics'
    if (item.to === '/payments') return location.pathname === '/payments'
    if (item.to === '/leads?create=1') {
      return location.pathname === '/leads' && location.search.includes('create=1')
    }
    if (item.to === '/leads?upload=1') {
      return location.pathname === '/leads' && location.search.includes('upload=1')
    }
    if (item.to === '/categories?create=1') {
      return location.pathname === '/categories' && location.search.includes('create=1')
    }
    return isActive
  }

  function renderNavItem(item: AdminNavItem, variant: 'main' | 'quick') {
    return (
      <NavLink
        key={item.to}
        to={item.to}
        end={item.end}
        onClick={onClose}
        className={({ isActive }) =>
          [
            'group rounded-2xl px-3 py-2.5 text-sm font-medium transition-all duration-200',
            variant === 'quick' ? 'border' : '',
            resolveItemActive(item, isActive)
              ? variant === 'quick'
                ? 'border-violet-400/60 bg-violet-500/20 text-violet-100 shadow-sm'
                : 'bg-gradient-to-r from-violet-500/20 to-indigo-500/15 text-white shadow-sm ring-1 ring-violet-300/25'
              : variant === 'quick'
                ? 'border-white/10 text-slate-300 hover:border-violet-300/50 hover:bg-violet-500/15 hover:text-violet-100'
                : 'text-slate-300 hover:bg-white/5 hover:text-white hover:ring-1 hover:ring-white/10',
          ].join(' ')
        }
      >
        {({ isActive }) => {
          const active = resolveItemActive(item, isActive)
          return (
            <div className="flex items-center gap-2.5">
              <span
                className={[
                  'inline-flex h-8 w-8 items-center justify-center rounded-xl transition-all duration-200',
                  active
                    ? variant === 'quick'
                      ? 'bg-violet-400/20 text-violet-100'
                      : 'bg-white/20 text-white'
                    : variant === 'quick'
                      ? 'bg-white/10 text-slate-300 group-hover:bg-violet-400/20 group-hover:text-violet-100'
                      : 'bg-white/10 text-slate-300 group-hover:bg-white/20',
                ].join(' ')}
              >
                {renderIcon(item.icon)}
              </span>
              <div className="min-w-0">
                <p className="truncate">{item.label}</p>
                {item.hint ? (
                  <p
                    className={[
                      'truncate text-[10px]',
                      active
                        ? variant === 'quick'
                          ? 'text-violet-200'
                          : 'text-slate-200'
                        : 'text-slate-400',
                    ].join(' ')}
                  >
                    {item.hint}
                  </p>
                ) : null}
              </div>
            </div>
          )
        }}
      </NavLink>
    )
  }

  return (
    <>
      <div
        className={[
          'fixed inset-0 z-30 bg-slate-950/55 backdrop-blur-sm transition-opacity duration-300 md:hidden',
          isOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        ].join(' ')}
        onClick={onClose}
      />
      <aside
        className={[
          'fixed inset-y-0 left-0 z-40 flex w-72 flex-col border-r border-slate-800/80 bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 text-slate-200 shadow-2xl backdrop-blur transition-transform duration-300 md:static md:z-auto md:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        ].join(' ')}
      >
        <div className="border-b border-white/10 px-4 py-4">
          <div className="flex items-start justify-between gap-2">
            <div className="w-full rounded-2xl border border-white/10 bg-gradient-to-br from-slate-900 to-slate-800 px-3 py-3 shadow-lg shadow-violet-900/10">
              <div className="flex items-center gap-2">
                <span className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500 to-indigo-500 text-[11px] font-semibold text-white">
                  LS
                </span>
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold tracking-tight text-white">
                    Leads Sell
                  </p>
                  <p className="text-[11px] text-slate-400">Admin Workspace</p>
                </div>
              </div>
              <div className="mt-2 flex items-center gap-2 text-[11px] text-slate-300">
                <span className="inline-flex h-2 w-2 rounded-full bg-emerald-500" />
                Live admin mode
              </div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="rounded-lg border border-white/20 px-2 py-1 text-xs text-slate-300 hover:bg-white/10 md:hidden"
            >
              Close
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-3 py-4">
          <div>
            <p className="px-2 pb-2 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              Main
            </p>
            <nav className="flex flex-col gap-1.5">{primaryNav.map((item) => renderNavItem(item, 'main'))}</nav>
          </div>
        </div>

        <div className="mt-auto space-y-3 border-t border-white/10 p-3">
          <div className="rounded-xl border border-white/10 bg-white/5 px-3 py-2">
            <p className="text-[11px] uppercase tracking-wide text-slate-400">
              Logged in as
            </p>
            <p className="mt-1 truncate text-xs font-medium text-slate-200">
              {userEmail}
            </p>
          </div>
          <NavLink
            to="/settings"
            onClick={onClose}
            className={({ isActive }) =>
              [
                'flex items-center gap-2 rounded-xl border px-3 py-2 text-sm font-medium transition-all duration-200',
                isActive
                  ? 'border-violet-400/50 bg-violet-500/20 text-violet-100'
                  : 'border-white/20 bg-white/5 text-slate-200 hover:border-violet-300/40 hover:bg-white/10',
              ].join(' ')
            }
          >
            <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-white/10 text-slate-200">
              {renderIcon('settings')}
            </span>
            <span>Settings</span>
          </NavLink>
          <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-3 py-2">
            <p className="text-[11px] font-medium text-emerald-300">System status</p>
            <p className="mt-0.5 text-xs text-emerald-200">All services healthy</p>
          </div>
          <button
            type="button"
            onClick={logout}
            className="w-full rounded-xl border border-white/20 bg-white/5 px-3 py-2 text-sm font-medium text-slate-200 transition-all duration-200 hover:border-rose-300/40 hover:bg-rose-500/10"
          >
            Logout
          </button>
        </div>
      </aside>
    </>
  )
}

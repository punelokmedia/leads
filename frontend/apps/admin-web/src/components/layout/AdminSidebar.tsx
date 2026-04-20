import { NavLink } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

type AdminNavItem = { to: string; label: string; end?: boolean }

const nav: AdminNavItem[] = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/leads', label: 'Leads' },
  { to: '/settings', label: 'Settings' },
]

type AdminSidebarProps = {
  isOpen: boolean
  onClose: () => void
}

export function AdminSidebar({ isOpen, onClose }: AdminSidebarProps) {
  const { userEmail, logout } = useAdminAuth()

  return (
    <>
      <div
        className={[
          'fixed inset-0 z-30 bg-slate-900/40 transition-opacity md:hidden',
          isOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        ].join(' ')}
        onClick={onClose}
      />
      <aside
        className={[
          'fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-slate-200 bg-white/95 backdrop-blur transition-transform md:static md:z-auto md:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        ].join(' ')}
      >
        <div className="border-b border-slate-200 px-5 py-6">
          <div className="flex items-start justify-between gap-2">
            <div>
              <span className="text-base font-semibold tracking-tight text-slate-900">
                Leads Sell
              </span>
              <p className="mt-1 text-xs text-slate-500">Admin Dashboard</p>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="rounded-lg border border-slate-300 px-2 py-1 text-xs text-slate-600 hover:bg-slate-100 md:hidden"
            >
              Close
            </button>
          </div>
        </div>

        <nav className="flex flex-col gap-1 p-3">
          {nav.map(({ to, label, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              onClick={onClose}
              className={({ isActive }) =>
                [
                  'rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-violet-600 text-white shadow-sm'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900',
                ].join(' ')
              }
            >
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="mt-auto space-y-3 border-t border-slate-200 p-3">
          <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
            <p className="text-[11px] uppercase tracking-wide text-slate-500">
              Logged in as
            </p>
            <p className="mt-1 truncate text-xs font-medium text-slate-700">
              {userEmail}
            </p>
          </div>
          <button
            type="button"
            onClick={logout}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-700 transition hover:border-slate-400 hover:bg-slate-100"
          >
            Logout
          </button>
        </div>
      </aside>
    </>
  )
}

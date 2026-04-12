import { NavLink } from 'react-router-dom'

type AdminNavItem = { to: string; label: string; end?: boolean }

const nav: AdminNavItem[] = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/leads', label: 'Leads' },
  { to: '/settings', label: 'Settings' },
]

export function AdminSidebar() {
  return (
    <aside className="hidden w-56 shrink-0 flex-col border-r border-stone-800 bg-stone-900/80 md:flex">
      <div className="border-b border-stone-800 px-5 py-6">
        <span className="text-sm font-semibold tracking-tight text-white">
          Leads Sell
        </span>
        <p className="mt-0.5 text-xs text-stone-500">Admin</p>
      </div>
      <nav className="flex flex-col gap-0.5 p-3">
        {nav.map(({ to, label, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              [
                'rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-violet-600/20 text-violet-200'
                  : 'text-stone-400 hover:bg-stone-800 hover:text-stone-200',
              ].join(' ')
            }
          >
            {label}
          </NavLink>
        ))}
      </nav>
      <div className="mt-auto border-t border-stone-800 p-3">
        <NavLink
          to="/login"
          className="block rounded-lg px-3 py-2 text-sm text-stone-500 hover:bg-stone-800 hover:text-stone-300"
        >
          Sign in view
        </NavLink>
      </div>
    </aside>
  )
}

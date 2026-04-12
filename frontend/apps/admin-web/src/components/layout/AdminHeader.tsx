import { NavLink } from 'react-router-dom'

type MobileNavItem = { to: string; label: string; end?: boolean }

const mobileNav: MobileNavItem[] = [
  { to: '/', label: 'Home', end: true },
  { to: '/leads', label: 'Leads' },
  { to: '/settings', label: 'Settings' },
]

export function AdminHeader() {
  return (
    <header className="sticky top-0 z-10 border-b border-stone-800 bg-stone-950/90 backdrop-blur-md">
      <div className="flex h-14 items-center justify-between gap-3 px-4 md:px-8">
        <div className="flex min-w-0 flex-1 items-center gap-2 md:gap-4">
          <span className="shrink-0 text-sm font-semibold text-white md:hidden">
            Leads Sell
          </span>
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
                      ? 'bg-violet-600/25 text-violet-200'
                      : 'text-stone-400',
                  ].join(' ')
                }
              >
                {label}
              </NavLink>
            ))}
          </nav>
        </div>
        <NavLink
          to="/settings"
          className="shrink-0 rounded-lg px-3 py-1.5 text-xs font-medium text-stone-400 hover:bg-stone-800 hover:text-stone-200"
        >
          Account
        </NavLink>
      </div>
    </header>
  )
}

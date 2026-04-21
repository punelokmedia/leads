import { NavLink } from 'react-router-dom'

const categoryLinks = [
  'Instagram Reels',
  'Bengaluru Leads',
  'Mumbai/Thane/Navi Leads',
  'Pune Leads',
  'Delhi/NCR',
  'Hyderabad/Secunderabad',
  'Kolkata',
  'Chennai Leads',
  'Lucknow',
  'Ahmedabad',
  'Nagpur',
  'Jaipur',
  'Surat',
]

export function PublicHeader() {
  return (
    <header className="sticky top-0 z-20 border-b border-stone-200 bg-white/95 shadow-sm backdrop-blur">
      <div className="mx-auto max-w-7xl px-4 py-3 sm:px-6">
        <div className="flex items-center justify-between gap-4">
          <NavLink to="/" className="flex min-w-0 items-center gap-3">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-gradient-to-br from-amber-300 via-orange-400 to-red-500 text-xl shadow-md">
              📦
            </div>
            <div className="min-w-0">
              <p className="truncate text-xl font-black tracking-wide text-stone-900">
                LEADS
              </p>
              <p className="-mt-1 truncate text-xs font-medium text-stone-500">
                On Demands
              </p>
            </div>
          </NavLink>

          <div className="hidden items-center gap-2 md:flex">
            <div className="rounded-lg border border-stone-300 bg-white px-4 py-2 text-xs font-semibold text-stone-700 shadow-sm">
              Cart ₹0.00
            </div>
            <NavLink
              to="/contact"
              className="rounded-lg border border-stone-300 px-3 py-2 text-xs font-semibold text-stone-700 hover:bg-stone-100"
            >
              Help
            </NavLink>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-between gap-3 border-t border-stone-200 pt-3">
          <nav className="flex min-w-0 flex-1 items-center gap-2 overflow-x-auto">
            {categoryLinks.map((item) => (
              <button
                key={item}
                type="button"
                className="shrink-0 rounded-full border border-stone-300 bg-white px-3 py-1.5 text-xs font-semibold text-stone-600 transition hover:border-amber-400 hover:text-stone-900"
              >
                {item}
              </button>
            ))}
          </nav>

          <div className="hidden shrink-0 items-center gap-1 sm:flex">
            <NavLink
              to="/pricing"
              className="rounded-lg px-3 py-1.5 text-xs font-semibold text-stone-600 hover:bg-stone-100"
            >
              Login
            </NavLink>
            <NavLink
              to="/contact"
              className="rounded-lg px-3 py-1.5 text-xs font-semibold text-stone-600 hover:bg-stone-100"
            >
              My account
            </NavLink>
          </div>
        </div>
      </div>
    </header>
  )
}

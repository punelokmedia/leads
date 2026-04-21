import { useEffect, useMemo, useState } from 'react'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type DashboardOverview = {
  totalUsers: number
  totalAdmins: number
  totalLeads: number
  activeLeads: number
  soldLeads: number
  expiredLeads: number
  totalOrders: number
  totalRevenue: number
}

const initialOverview: DashboardOverview = {
  totalUsers: 0,
  totalAdmins: 0,
  totalLeads: 0,
  activeLeads: 0,
  soldLeads: 0,
  expiredLeads: 0,
  totalOrders: 0,
  totalRevenue: 0,
}

function getToken() {
  if (typeof window === 'undefined') return ''
  const raw = window.localStorage.getItem(AUTH_STORAGE_KEY)
  if (!raw) return ''
  try {
    const parsed = JSON.parse(raw) as { token?: string }
    return parsed.token ?? ''
  } catch {
    return ''
  }
}

function formatAmount(amount: number) {
  return `₹${amount.toLocaleString('en-IN')}`
}

export function DashboardPage() {
  const [overview, setOverview] = useState<DashboardOverview>(initialOverview)
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let isMounted = true

    async function loadOverview() {
      const token = getToken()
      if (!token) {
        if (isMounted) {
          setLoading(false)
          setErrorMessage('Admin token not found. Please login again.')
        }
        return
      }

      try {
        setLoading(true)
        setErrorMessage('')
        const response = await fetch(`${API_BASE_URL}/api/v1/admin/dashboard/overview`, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        })
        const payload = (await response.json()) as {
          success?: boolean
          message?: string
          data?: Partial<DashboardOverview>
        }

        if (!response.ok || payload.success === false || !payload.data) {
          throw new Error(payload.message || 'Failed to fetch dashboard overview')
        }

        if (isMounted) {
          setOverview((previous) => ({
            ...previous,
            ...payload.data,
          }))
        }
      } catch (error) {
        if (isMounted) {
          setErrorMessage(
            error instanceof Error ? error.message : 'Failed to fetch dashboard overview',
          )
        }
      } finally {
        if (isMounted) {
          setLoading(false)
        }
      }
    }

    void loadOverview()

    return () => {
      isMounted = false
    }
  }, [])

  const metrics = useMemo(
    () => [
      { label: 'Total admins', value: String(overview.totalAdmins), short: 'AD' },
      { label: 'Total users', value: String(overview.totalUsers), short: 'US' },
      { label: 'Total leads', value: String(overview.totalLeads), short: 'LD' },
      { label: 'Paid orders', value: String(overview.totalOrders), short: 'OR' },
      { label: 'Revenue', value: formatAmount(overview.totalRevenue), short: 'RV' },
    ],
    [overview],
  )

  return (
    <div className="space-y-5 md:space-y-6">
      {errorMessage ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {errorMessage}
        </div>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {metrics.map((item) => (
          <div key={item.label} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs uppercase tracking-wide text-slate-500">{item.label}</p>
              <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-slate-100 text-[10px] font-semibold text-slate-600">
                {item.short}
              </span>
            </div>
            <p className="mt-2 text-3xl font-semibold tabular-nums text-slate-900">
              {loading ? '...' : item.value}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}

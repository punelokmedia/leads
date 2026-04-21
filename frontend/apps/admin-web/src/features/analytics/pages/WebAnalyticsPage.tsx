import { useCallback, useEffect, useMemo, useState } from 'react'
import { useToast } from '@/components/feedback/ToastProvider'

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
  pendingOrders: number
  totalRevenue: number
}

type RevenuePoint = {
  _id?: { month?: number; year?: number }
  total?: number
}

type TopCategory = {
  totalSold?: number
  categoryId?: string
  categoryName?: string
}

const initialOverview: DashboardOverview = {
  totalUsers: 0,
  totalAdmins: 0,
  totalLeads: 0,
  activeLeads: 0,
  soldLeads: 0,
  expiredLeads: 0,
  totalOrders: 0,
  pendingOrders: 0,
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

function formatMonthYear(value?: { month?: number; year?: number }) {
  if (!value?.month || !value?.year) return '-'
  const date = new Date(value.year, value.month - 1, 1)
  return date.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
}

export function WebAnalyticsPage() {
  const toast = useToast()
  const [overview, setOverview] = useState<DashboardOverview>(initialOverview)
  const [revenueData, setRevenueData] = useState<RevenuePoint[]>([])
  const [topCategories, setTopCategories] = useState<TopCategory[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [lastUpdatedAt, setLastUpdatedAt] = useState('')

  const loadAnalytics = useCallback(async (silent = false, manual = false) => {
    const token = getToken()
    if (!token) {
      setLoading(false)
      setRefreshing(false)
      const message = 'Admin token not found. Please login again.'
      setErrorMessage(message)
      toast.error(message)
      return
    }

    try {
      if (silent) {
        setRefreshing(true)
      } else {
        setLoading(true)
      }
      setErrorMessage('')

      const [overviewRes, revenueRes, topCategoriesRes] = await Promise.all([
        fetch(`${API_BASE_URL}/api/v1/admin/dashboard/overview`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/api/v1/admin/dashboard/revenue`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${API_BASE_URL}/api/v1/admin/dashboard/top-categories`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ])

      const overviewPayload = (await overviewRes.json()) as {
        success?: boolean
        message?: string
        data?: Partial<DashboardOverview>
      }
      const revenuePayload = (await revenueRes.json()) as {
        success?: boolean
        message?: string
        data?: RevenuePoint[]
      }
      const topCategoriesPayload = (await topCategoriesRes.json()) as {
        success?: boolean
        message?: string
        data?: TopCategory[]
      }

      if (!overviewRes.ok || overviewPayload.success === false || !overviewPayload.data) {
        throw new Error(overviewPayload.message || 'Failed to fetch dashboard overview')
      }
      if (!revenueRes.ok || revenuePayload.success === false) {
        throw new Error(revenuePayload.message || 'Failed to fetch revenue analytics')
      }
      if (!topCategoriesRes.ok || topCategoriesPayload.success === false) {
        throw new Error(topCategoriesPayload.message || 'Failed to fetch top categories')
      }

      setOverview((previous) => ({ ...previous, ...overviewPayload.data }))
      setRevenueData(revenuePayload.data ?? [])
      setTopCategories(topCategoriesPayload.data ?? [])
      setLastUpdatedAt(
        new Date().toLocaleTimeString('en-IN', {
          hour: '2-digit',
          minute: '2-digit',
        }),
      )
      if (manual) {
        toast.success('Web analytics refreshed')
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to fetch analytics'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [toast])

  useEffect(() => {
    void loadAnalytics(false)
  }, [loadAnalytics])

  const maxRevenue = useMemo(
    () => Math.max(1, ...revenueData.map((item) => Number(item.total ?? 0))),
    [revenueData],
  )
  const revenueChartRows = useMemo(() => {
    return revenueData.map((point) => {
      const value = Number(point.total ?? 0)
      return {
        label: formatMonthYear(point._id),
        value,
        heightPct: Math.max(10, (value / maxRevenue) * 100),
      }
    })
  }, [maxRevenue, revenueData])

  const leadStatusRows = useMemo(() => {
    const total = Math.max(1, overview.totalLeads)
    return [
      { label: 'Active leads', value: overview.activeLeads, color: 'bg-emerald-500', pct: (overview.activeLeads / total) * 100 },
      { label: 'Sold leads', value: overview.soldLeads, color: 'bg-indigo-500', pct: (overview.soldLeads / total) * 100 },
      { label: 'Expired leads', value: overview.expiredLeads, color: 'bg-rose-500', pct: (overview.expiredLeads / total) * 100 },
    ]
  }, [overview.activeLeads, overview.expiredLeads, overview.soldLeads, overview.totalLeads])

  const orderGaugeStyle = useMemo(() => {
    const paid = overview.totalOrders
    const pending = overview.pendingOrders
    const total = Math.max(1, paid + pending)
    const paidPct = (paid / total) * 100
    return {
      background: `conic-gradient(#10b981 ${paidPct}%, #f59e0b ${paidPct}% 100%)`,
    }
  }, [overview.pendingOrders, overview.totalOrders])

  const avgOrderValue = useMemo(() => {
    if (overview.totalOrders <= 0) return 0
    return overview.totalRevenue / overview.totalOrders
  }, [overview.totalOrders, overview.totalRevenue])

  const rankedCategories = useMemo(
    () =>
      [...topCategories].sort(
        (a, b) => Number(b.totalSold ?? 0) - Number(a.totalSold ?? 0),
      ),
    [topCategories],
  )

  const maxCategorySold = useMemo(
    () => Math.max(1, ...rankedCategories.map((item) => Number(item.totalSold ?? 0))),
    [rankedCategories],
  )

  const kpis = [
    {
      label: 'Total Revenue',
      value: formatAmount(overview.totalRevenue),
      note: `Avg order ${formatAmount(Math.round(avgOrderValue))}`,
      tone: 'from-violet-600 to-indigo-600',
    },
    {
      label: 'Total Users',
      value: String(overview.totalUsers),
      note: `${overview.totalAdmins} admins active`,
      tone: 'from-sky-600 to-cyan-600',
    },
    {
      label: 'Orders Health',
      value: `${overview.totalOrders} paid`,
      note: `${overview.pendingOrders} pending`,
      tone: 'from-amber-500 to-orange-500',
    },
  ]

  return (
    <div className="space-y-5">
      <section className="py-1">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-violet-600">
              Admin intelligence suite
            </p>
            <h1 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
              Web Analytics
            </h1>
            <p className="mt-1.5 max-w-2xl text-sm text-slate-600">
              One unified view of revenue, lead flow, order status and category performance with a cleaner,
              executive-level presentation.
            </p>
          </div>
          <div className="flex items-center gap-2 self-end">
            <div className="rounded-lg border border-violet-200/70 px-3 py-1.5 text-right">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-violet-700">
                Last Updated
              </p>
              <p className="mt-0.5 text-xs text-violet-700">{lastUpdatedAt || '--:--'}</p>
            </div>
            <button
              type="button"
              onClick={() => {
                void loadAnalytics(true, true)
              }}
              disabled={loading || refreshing}
              className="rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition-all duration-200 hover:border-violet-300 hover:bg-violet-50 hover:text-violet-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {refreshing ? 'Refreshing...' : 'Refresh'}
            </button>
          </div>
        </div>
      </section>

      {errorMessage ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {errorMessage}
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-3">
        {kpis.map((item) => (
          <div
            key={item.label}
            className="relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-4 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:shadow-md"
          >
            <div className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${item.tone}`} />
            <p className="text-xs uppercase tracking-wide text-slate-500">{item.label}</p>
            <p className="mt-2 text-3xl font-semibold text-slate-900">{loading ? '...' : item.value}</p>
            <p className="mt-1 text-xs text-slate-500">{item.note}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-5 lg:grid-cols-3">
        <section className="rounded-2xl p-4">
          <h2 className="text-sm font-semibold text-slate-800">Order Split</h2>
          <div className="mt-4 flex items-center justify-center">
            <div className="relative h-32 w-32 rounded-full p-2" style={orderGaugeStyle}>
              <div className="absolute inset-4 rounded-full bg-white shadow-inner" />
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <p className="text-lg font-semibold text-slate-800">{overview.totalOrders + overview.pendingOrders}</p>
                  <p className="text-[11px] uppercase tracking-wide text-slate-500">Total</p>
                </div>
              </div>
            </div>
          </div>
          <div className="mt-4 space-y-2 text-xs text-slate-700">
            <div className="flex items-center justify-between rounded-lg border border-emerald-100 bg-emerald-50 px-3 py-2">
              <span className="inline-flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" />
                Paid Orders
              </span>
              <span className="font-semibold">{overview.totalOrders}</span>
            </div>
            <div className="flex items-center justify-between rounded-lg border border-amber-100 bg-amber-50 px-3 py-2">
              <span className="inline-flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-amber-500" />
                Pending Orders
              </span>
              <span className="font-semibold">{overview.pendingOrders}</span>
            </div>
          </div>
        </section>

        <section className="rounded-2xl p-4">
          <h2 className="text-sm font-semibold text-slate-800">Leads Distribution</h2>
          <div className="mt-4 space-y-3">
            {loading ? (
              <p className="text-xs text-slate-500">Loading lead performance...</p>
            ) : (
              leadStatusRows.map((row) => (
                <div key={row.label}>
                  <div className="mb-1.5 flex items-center justify-between text-xs text-slate-600">
                    <p>{row.label}</p>
                    <p className="font-medium">{`${row.value} (${row.pct.toFixed(0)}%)`}</p>
                  </div>
                  <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                    <div
                      className={`${row.color} h-full rounded-full transition-[width] duration-300`}
                      style={{ width: `${row.pct}%` }}
                    />
                  </div>
                </div>
              ))
            )}
          </div>

          <div className="mt-5 grid gap-2 sm:grid-cols-3">
            <div className="rounded-xl border border-emerald-100 bg-emerald-50 px-3 py-2">
              <p className="text-[11px] uppercase tracking-wide text-emerald-700">Active</p>
              <p className="mt-1 text-lg font-semibold text-emerald-800">{overview.activeLeads}</p>
            </div>
            <div className="rounded-xl border border-indigo-100 bg-indigo-50 px-3 py-2">
              <p className="text-[11px] uppercase tracking-wide text-indigo-700">Sold</p>
              <p className="mt-1 text-lg font-semibold text-indigo-800">{overview.soldLeads}</p>
            </div>
            <div className="rounded-xl border border-rose-100 bg-rose-50 px-3 py-2">
              <p className="text-[11px] uppercase tracking-wide text-rose-700">Expired</p>
              <p className="mt-1 text-lg font-semibold text-rose-800">{overview.expiredLeads}</p>
            </div>
          </div>
        </section>

        <section className="rounded-2xl p-4">
          <h2 className="text-sm font-semibold text-slate-800">Top Categories Performance</h2>
          <div className="mt-4 space-y-3">
            {loading ? (
              <p className="text-xs text-slate-500">Loading top categories...</p>
            ) : rankedCategories.length === 0 ? (
              <p className="text-xs text-slate-500">No category performance data found.</p>
            ) : (
              rankedCategories.map((item, idx) => {
                const sold = Number(item.totalSold ?? 0)
                const widthPct = Math.max(6, (sold / maxCategorySold) * 100)
                return (
                  <div key={`${item.categoryId ?? idx}`} className="rounded-xl border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between gap-2">
                      <div>
                        <p className="text-sm font-semibold text-slate-800">{item.categoryName || 'Unknown'}</p>
                        <p className="text-[11px] text-slate-500">{item.categoryId || '-'}</p>
                      </div>
                      <p className="rounded-lg bg-violet-50 px-2 py-1 text-xs font-semibold text-violet-700">
                        {sold} sold
                      </p>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-violet-500 to-indigo-500"
                        style={{ width: `${widthPct}%` }}
                      />
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </section>
      </div>

      <section className="px-1 xl:px-0">
        <div className="mb-2 flex items-center justify-between">
          <h2 className="text-xs uppercase tracking-wide text-slate-500">Revenue Bar Graph</h2>
          <p className="text-[11px] text-slate-500">Monthly</p>
        </div>
        {loading ? (
          <p className="py-8 text-center text-xs text-slate-500">Loading graph...</p>
        ) : revenueData.length === 0 ? (
          <p className="py-8 text-center text-xs text-slate-500">No revenue data found.</p>
        ) : (
          <>
            <div className="rounded-xl border border-slate-200 bg-white p-3">
              <div className="grid grid-cols-[66px_minmax(0,1fr)] gap-3">
                <div className="flex h-44 flex-col justify-between py-1 text-[10px] font-medium text-slate-400">
                  {[100, 75, 50, 25, 0].map((percent) => (
                    <p key={percent}>
                      {formatAmount(Math.round((maxRevenue * percent) / 100))}
                    </p>
                  ))}
                </div>

                <div className="relative">
                  <div className="pointer-events-none absolute inset-0 grid grid-rows-5">
                    {[0, 1, 2, 3].map((line) => (
                      <div key={line} className="border-b border-dashed border-slate-200" />
                    ))}
                    <div />
                  </div>

                  <div className="relative grid h-44 items-end gap-2.5 [grid-template-columns:repeat(auto-fit,minmax(72px,1fr))]">
                    {revenueChartRows.map((point, idx) => (
                      <div
                        key={`${point.label}-${idx}`}
                        className="flex h-full min-w-0 flex-col justify-end"
                      >
                        <div className="flex h-36 w-full items-end justify-center">
                          <div
                            className="w-9 rounded-t-lg bg-gradient-to-t from-violet-600 via-indigo-500 to-sky-400 shadow-sm sm:w-10"
                            style={{ height: `${point.heightPct}%` }}
                          />
                        </div>
                        <p className="mt-2 truncate text-center text-[11px] font-medium text-slate-700">
                          {point.label}
                        </p>
                        <p className="truncate text-center text-[10px] text-slate-500">
                          {formatAmount(point.value)}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <p className="mt-2 truncate text-[11px] text-slate-500">
              {formatMonthYear(revenueData[revenueData.length - 1]?._id) || '-'}{' '}
              <span className="font-semibold text-slate-700">
                {formatAmount(Number(revenueData[revenueData.length - 1]?.total ?? 0))}
              </span>
            </p>
          </>
        )}
      </section>
    </div>
  )
}

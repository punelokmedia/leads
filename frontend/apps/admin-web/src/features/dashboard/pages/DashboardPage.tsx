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

type RecentOrder = {
  _id: string
  user?: {
    firstname?: string
    lastname?: string
    email?: string
  }
  leads?: Array<{
    lead?: string
    price?: number
    quantity?: number
    _id?: string
  }>
  totalAmount?: number
  currency?: string
  status?: string
  createdAt?: string
}

type RecentOrdersMeta = {
  total: number
  page: number
  limit: number
  totalPages: number
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

export function DashboardPage() {
  const toast = useToast()
  const [overview, setOverview] = useState<DashboardOverview>(initialOverview)
  const [loadingSummary, setLoadingSummary] = useState(true)
  const [loadingOrders, setLoadingOrders] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')
  const [revenueData, setRevenueData] = useState<RevenuePoint[]>([])
  const [topCategories, setTopCategories] = useState<TopCategory[]>([])
  const [recentOrders, setRecentOrders] = useState<RecentOrder[]>([])
  const [recentOrdersMeta, setRecentOrdersMeta] = useState<RecentOrdersMeta>({
    total: 0,
    page: 1,
    limit: 5,
    totalPages: 1,
  })
  const [recentOrdersPage, setRecentOrdersPage] = useState(1)

  const loadSummary = useCallback(async () => {
    const token = getToken()
    if (!token) {
      setLoadingSummary(false)
      const message = 'Admin token not found. Please login again.'
      setErrorMessage(message)
      toast.error(message)
      return
    }

    try {
      setLoadingSummary(true)
      setErrorMessage('')
      const [overviewRes, revenueRes, categoryRes] = await Promise.all([
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
      const categoryPayload = (await categoryRes.json()) as {
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
      if (!categoryRes.ok || categoryPayload.success === false) {
        throw new Error(categoryPayload.message || 'Failed to fetch top categories')
      }

      setOverview((previous) => ({ ...previous, ...overviewPayload.data }))
      setRevenueData(revenuePayload.data ?? [])
      setTopCategories(categoryPayload.data ?? [])
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to fetch dashboard data'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setLoadingSummary(false)
    }
  }, [toast])

  const loadRecentOrders = useCallback(async () => {
    const token = getToken()
    if (!token) {
      setLoadingOrders(false)
      toast.error('Admin token not found. Please login again.')
      return
    }

    try {
      setLoadingOrders(true)
      const response = await fetch(
        `${API_BASE_URL}/api/v1/admin/dashboard/recent-orders?page=${recentOrdersPage}&limit=5`,
        {
          headers: { Authorization: `Bearer ${token}` },
        },
      )
      const payload = (await response.json()) as {
        success?: boolean
        message?: string
        data?: RecentOrder[]
        meta?: Partial<RecentOrdersMeta>
      }

      if (!response.ok || payload.success === false) {
        throw new Error(payload.message || 'Failed to fetch recent orders')
      }

      setRecentOrders(payload.data ?? [])
      setRecentOrdersMeta((previous) => ({
        total: Number(payload.meta?.total ?? previous.total),
        page: Number(payload.meta?.page ?? recentOrdersPage),
        limit: Number(payload.meta?.limit ?? previous.limit),
        totalPages: Math.max(1, Number(payload.meta?.totalPages ?? previous.totalPages)),
      }))
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to fetch recent orders'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setLoadingOrders(false)
    }
  }, [recentOrdersPage, toast])

  useEffect(() => {
    void loadSummary()
  }, [loadSummary])

  useEffect(() => {
    void loadRecentOrders()
  }, [loadRecentOrders])

  const metrics = useMemo(
    () => [
      { label: 'Total admins', value: String(overview.totalAdmins), short: 'AD' },
      { label: 'Total users', value: String(overview.totalUsers), short: 'US' },
      { label: 'Total leads', value: String(overview.totalLeads), short: 'LD' },
      { label: 'Paid orders', value: String(overview.totalOrders), short: 'OR' },
      { label: 'Pending orders', value: String(overview.pendingOrders), short: 'PO' },
      { label: 'Revenue', value: formatAmount(overview.totalRevenue), short: 'RV' },
    ],
    [overview],
  )

  function formatMonthYear(value?: { month?: number; year?: number }) {
    if (!value?.month || !value?.year) return '-'
    const date = new Date(value.year, value.month - 1, 1)
    return date.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
  }

  return (
    <div className="space-y-5 md:space-y-6">
      {errorMessage ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {errorMessage}
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-3">
        {metrics.map((item) => (
          <div
            key={item.label}
            className="rounded-2xl border border-slate-200 bg-gradient-to-br from-white to-slate-50 p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs uppercase tracking-wide text-slate-500">{item.label}</p>
              <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl bg-slate-100 text-[10px] font-semibold text-slate-600">
                {item.short}
              </span>
            </div>
            <p className="mt-2 text-3xl font-semibold tabular-nums text-slate-900">
              {loadingSummary ? '...' : item.value}
            </p>
          </div>
        ))}
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <h2 className="text-sm font-semibold text-slate-800">Revenue Analytics</h2>
          <div className="mt-3 space-y-2">
            {loadingSummary ? (
              <p className="text-xs text-slate-500">Loading revenue...</p>
            ) : revenueData.length === 0 ? (
              <p className="text-xs text-slate-500">No revenue data available.</p>
            ) : (
              revenueData.map((item, idx) => (
                <div
                  key={`${item._id?.month ?? idx}-${item._id?.year ?? idx}`}
                  className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2 text-xs"
                >
                  <p className="font-medium text-slate-700">{formatMonthYear(item._id)}</p>
                  <p className="font-semibold text-slate-900">{formatAmount(Number(item.total ?? 0))}</p>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <h2 className="text-sm font-semibold text-slate-800">Top Categories</h2>
          <div className="mt-3 space-y-2">
            {loadingSummary ? (
              <p className="text-xs text-slate-500">Loading categories...</p>
            ) : topCategories.length === 0 ? (
              <p className="text-xs text-slate-500">No category sales data available.</p>
            ) : (
              topCategories.map((item, idx) => (
                <div
                  key={`${item.categoryId ?? item.categoryName ?? idx}`}
                  className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2 text-xs"
                >
                  <div>
                    <p className="font-medium text-slate-700">{item.categoryName || 'Unknown'}</p>
                    <p className="text-slate-500">{item.categoryId || '-'}</p>
                  </div>
                  <p className="font-semibold text-slate-900">{Number(item.totalSold ?? 0)}</p>
                </div>
              ))
            )}
          </div>
        </section>
      </div>

      <section className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-sm font-semibold text-slate-800">Recent Orders</h2>
          <button
            type="button"
            onClick={() => {
              void loadSummary()
              void loadRecentOrders()
              toast.success('Dashboard refresh started')
            }}
            className="rounded border border-slate-300 px-2.5 py-1 text-[11px] font-medium text-slate-700 hover:bg-slate-100"
          >
            Refresh Dashboard
          </button>
        </div>
        <div className="mt-3 overflow-x-auto">
          <table className="min-w-full text-xs">
            <thead className="text-left text-slate-500">
              <tr>
                <th className="px-2 py-2">Order ID</th>
                <th className="px-2 py-2">User</th>
                <th className="px-2 py-2">Leads</th>
                <th className="px-2 py-2">Amount</th>
                <th className="px-2 py-2">Status</th>
                <th className="px-2 py-2">Created</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loadingOrders ? (
                <tr>
                  <td className="px-2 py-4 text-slate-500" colSpan={6}>
                    Loading recent orders...
                  </td>
                </tr>
              ) : recentOrders.length === 0 ? (
                <tr>
                  <td className="px-2 py-4 text-slate-500" colSpan={6}>
                    No recent orders found.
                  </td>
                </tr>
              ) : (
                recentOrders.map((order) => (
                  <tr key={order._id}>
                    <td className="px-2 py-2 font-medium text-slate-700">{order._id}</td>
                    <td className="px-2 py-2 text-slate-600">
                      {(order.user?.firstname || '') + ' ' + (order.user?.lastname || '')}
                      <p className="text-slate-500">{order.user?.email || '-'}</p>
                    </td>
                    <td className="px-2 py-2 text-slate-600">{order.leads?.length ?? 0}</td>
                    <td className="px-2 py-2 font-semibold text-slate-800">
                      {formatAmount(Number(order.totalAmount ?? 0))}
                    </td>
                    <td className="px-2 py-2">
                      <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-emerald-700">
                        {order.status || '-'}
                      </span>
                    </td>
                    <td className="px-2 py-2 text-slate-600">
                      {order.createdAt ? new Date(order.createdAt).toLocaleString('en-IN') : '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <div className="mt-3 flex items-center justify-between text-xs text-slate-600">
          <p>
            Showing page {recentOrdersMeta.page} / {recentOrdersMeta.totalPages} (Total{' '}
            {recentOrdersMeta.total})
          </p>
          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={loadingOrders || recentOrdersMeta.page <= 1}
              onClick={() => setRecentOrdersPage((prev) => Math.max(1, prev - 1))}
              className="rounded border border-slate-300 px-2.5 py-1 text-[11px] font-medium text-slate-700 disabled:opacity-50"
            >
              Prev
            </button>
            <button
              type="button"
              disabled={loadingOrders || recentOrdersMeta.page >= recentOrdersMeta.totalPages}
              onClick={() =>
                setRecentOrdersPage((prev) =>
                  Math.min(recentOrdersMeta.totalPages, prev + 1),
                )
              }
              className="rounded border border-slate-300 px-2.5 py-1 text-[11px] font-medium text-slate-700 disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </section>
    </div>
  )
}

import { useCallback, useEffect, useMemo, useState } from 'react'
import { useToast } from '@/components/feedback/ToastProvider'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'
const PAGE_SIZE = 10
const PERIOD_OPTIONS = [
  { id: 'today', label: 'Today' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'quarterly', label: 'Quarterly' },
  { id: 'yearly', label: 'Yearly' },
] as const

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
  }>
  totalAmount?: number
  currency?: string
  status?: string
  razorpayOrderId?: string
  razorpayPaymentId?: string
  createdAt?: string
  paidAt?: string
}

type OrdersMeta = {
  total: number
  page: number
  limit: number
  totalPages: number
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

function formatAmount(amount?: number, currency = 'INR') {
  const safeValue = Number(amount ?? 0)
  return `${currency === 'INR' ? '₹' : ''}${safeValue.toLocaleString('en-IN')}`
}

export function PaymentHistoryPage() {
  const toast = useToast()
  const [orders, setOrders] = useState<RecentOrder[]>([])
  const [meta, setMeta] = useState<OrdersMeta>({
    total: 0,
    page: 1,
    limit: PAGE_SIZE,
    totalPages: 1,
  })
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [period, setPeriod] = useState<'all' | 'today' | 'weekly' | 'monthly' | 'quarterly' | 'yearly' | 'custom'>('all')
  const [selectedDate, setSelectedDate] = useState('')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  const loadPayments = useCallback(async (manual = false) => {
    const token = getToken()
    if (!token) {
      setErrorMessage('Admin token not found. Please login again.')
      toast.error('Admin token not found. Please login again.')
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setErrorMessage('')
      const periodParams =
        period === 'all'
          ? ''
          : period === 'custom' && selectedDate
            ? `&period=custom&date=${encodeURIComponent(selectedDate)}`
            : `&period=${period}`
      const response = await fetch(
        `${API_BASE_URL}/api/v1/admin/dashboard/recent-orders?page=${page}&limit=${PAGE_SIZE}${periodParams}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      )
      const payload = (await response.json()) as {
        success?: boolean
        message?: string
        data?: RecentOrder[]
        meta?: Partial<OrdersMeta>
      }

      if (!response.ok || payload.success === false) {
        throw new Error(payload.message || 'Failed to fetch payment history')
      }

      setOrders(payload.data ?? [])
      setMeta((prev) => ({
        total: Number(payload.meta?.total ?? prev.total),
        page: Number(payload.meta?.page ?? page),
        limit: Number(payload.meta?.limit ?? PAGE_SIZE),
        totalPages: Math.max(1, Number(payload.meta?.totalPages ?? prev.totalPages)),
      }))
      if (manual) {
        toast.success('Payment history refreshed')
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to fetch payment history'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }, [page, period, selectedDate, toast])

  useEffect(() => {
    void loadPayments()
  }, [loadPayments])

  const filteredOrders = useMemo(() => {
    const query = search.trim().toLowerCase()
    if (!query) return orders
    return orders.filter((order) => {
      const fullName = `${order.user?.firstname ?? ''} ${order.user?.lastname ?? ''}`.toLowerCase()
      const email = (order.user?.email ?? '').toLowerCase()
      const orderId = order._id.toLowerCase()
      const razorpayOrderId = (order.razorpayOrderId ?? '').toLowerCase()
      const razorpayPaymentId = (order.razorpayPaymentId ?? '').toLowerCase()
      return (
        fullName.includes(query) ||
        email.includes(query) ||
        orderId.includes(query) ||
        razorpayOrderId.includes(query) ||
        razorpayPaymentId.includes(query)
      )
    })
  }, [orders, search])

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
              Payment History
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Track all paid orders with customer details and payment references.
            </p>
          </div>
          <div className="rounded-xl border border-indigo-200 bg-indigo-50 px-3 py-2">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-indigo-700">
              Finance
            </p>
            <p className="mt-0.5 text-xs text-indigo-600">Live payment records</p>
          </div>
        </div>
      </div>

      {errorMessage ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {errorMessage}
        </div>
      ) : null}

      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-1 flex-wrap items-center gap-2">
            <input
              type="text"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search by order ID, payment ID, name, email..."
              className="w-full max-w-md rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500"
            />
            <button
              type="button"
              onClick={() => {
                setPeriod('all')
                setSelectedDate('')
                setPage(1)
              }}
              className={`rounded-lg border px-3 py-2 text-xs font-medium transition ${
                period === 'all'
                  ? 'border-violet-300 bg-violet-50 text-violet-700'
                  : 'border-slate-300 bg-white text-slate-700 hover:bg-slate-100'
              }`}
            >
              All
            </button>
            {PERIOD_OPTIONS.map((option) => (
              <button
                key={option.id}
                type="button"
                onClick={() => {
                  setPeriod(option.id)
                  setSelectedDate('')
                  setPage(1)
                }}
                className={`rounded-lg border px-3 py-2 text-xs font-medium transition ${
                  period === option.id
                    ? 'border-violet-300 bg-violet-50 text-violet-700'
                    : 'border-slate-300 bg-white text-slate-700 hover:bg-slate-100'
                }`}
              >
                {option.label}
              </button>
            ))}
            <input
              type="date"
              value={selectedDate}
              onChange={(event) => {
                const value = event.target.value
                setSelectedDate(value)
                setPeriod(value ? 'custom' : 'all')
                setPage(1)
              }}
              className="rounded-lg border border-slate-300 px-3 py-2 text-xs outline-none focus:border-violet-500"
            />
          </div>
          <button
            type="button"
            onClick={() => void loadPayments(true)}
            className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100"
          >
            Refresh
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full text-xs">
            <thead className="text-left text-slate-500">
              <tr>
                <th className="px-2 py-2">Order</th>
                <th className="px-2 py-2">Customer</th>
                <th className="px-2 py-2">Items</th>
                <th className="px-2 py-2">Amount</th>
                <th className="px-2 py-2">Status</th>
                <th className="px-2 py-2">Payment Ref</th>
                <th className="px-2 py-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-2 py-5 text-center text-slate-500">
                    Loading payment history...
                  </td>
                </tr>
              ) : filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-2 py-5 text-center text-slate-500">
                    No payments found.
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => (
                  <tr key={order._id}>
                    <td className="px-2 py-2">
                      <p className="font-semibold text-slate-700">{order._id}</p>
                      <p className="text-slate-500">{order.razorpayOrderId || '-'}</p>
                    </td>
                    <td className="px-2 py-2">
                      <p className="font-medium text-slate-700">
                        {`${order.user?.firstname ?? ''} ${order.user?.lastname ?? ''}`.trim() || '-'}
                      </p>
                      <p className="text-slate-500">{order.user?.email || '-'}</p>
                    </td>
                    <td className="px-2 py-2 text-slate-600">{order.leads?.length ?? 0}</td>
                    <td className="px-2 py-2 font-semibold text-slate-800">
                      {formatAmount(order.totalAmount, order.currency)}
                    </td>
                    <td className="px-2 py-2">
                      <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-emerald-700">
                        {order.status || '-'}
                      </span>
                    </td>
                    <td className="px-2 py-2 text-slate-600">{order.razorpayPaymentId || '-'}</td>
                    <td className="px-2 py-2 text-slate-600">
                      {order.createdAt ? new Date(order.createdAt).toLocaleString('en-IN') : '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex items-center justify-between text-xs text-slate-600">
          <p>
            Page {meta.page} / {meta.totalPages} (Total {meta.total})
          </p>
          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={loading || page <= 1}
              onClick={() => setPage((prev) => Math.max(1, prev - 1))}
              className="rounded border border-slate-300 px-2.5 py-1 text-[11px] font-medium text-slate-700 disabled:opacity-50"
            >
              Prev
            </button>
            <button
              type="button"
              disabled={loading || page >= meta.totalPages}
              onClick={() => setPage((prev) => Math.min(meta.totalPages, prev + 1))}
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

import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import { ReceiptButton } from '@/components/ReceiptButton'

type Order = { orderId: string; status: string; totalAmount: number; paidAt?: string; paymentMethod?: string; items: { leadId: string; title: string; city: string; total: number }[] }
export function OrderDetailsPage() {
  const { orderId } = useParams()
  const token = useUserToken()
  const [order, setOrder] = useState<Order | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reload, setReload] = useState(0)
  useEffect(() => {
    const controller = new AbortController()
    setLoading(true); setOrder(null); setError('')
    if (!token) { setLoading(false); return }
    void apiFetch(`${API_BASE_URL}/api/v1/leads/history`, { headers: { Authorization: `Bearer ${token}` }, signal: controller.signal }).then(async response => {
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load order.')
      const selected = (payload.data as Order[]).find(row => row.orderId === orderId)
      if (!selected) throw new Error('Order not found.')
      setOrder(selected)
    }).catch(failure => { if (!controller.signal.aborted) setError(failure instanceof Error ? failure.message : 'Unable to load order.') }).finally(() => { if (!controller.signal.aborted) setLoading(false) })
    return () => controller.abort()
  }, [token, orderId, reload])
  return <main style={{ maxWidth: 780, margin: '40px auto', padding: 24, color: '#071D49', background: '#f1f7ff', borderRadius: 20 }}>
    <h1>{order?.status === 'PAID' ? 'Payment successful' : 'Order Details'}</h1>
    {!token ? <Link to="/login">Sign in to view your order</Link> : loading ? <p role="status">Confirming payment…</p> : error ? <p role="alert">{error} <button onClick={() => setReload(value => value + 1)}>Retry</button></p> : order && <>
      <p>Order ID: {order.orderId}</p><p>Status: {order.status}</p>
      <p>Paid at: {order.paidAt ? new Date(order.paidAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) + ' IST' : 'Not provided'}</p>
      <p>Payment method: {order.paymentMethod || 'Not provided'}</p>
      <ul>{order.items.map((item, index) => <li key={`${item.leadId}-${index}`}><Link to={`/leads/${item.leadId}`}>{item.title}</Link> — {item.city} — ₹{item.total.toLocaleString('en-IN')}</li>)}</ul>
      <h2>Amount paid: ₹{order.totalAmount.toLocaleString('en-IN')}</h2>
      {order.status === 'PAID' && <ReceiptButton orderId={order.orderId} />}
    </>}
    <p><Link to="/my-leads">View purchase history</Link></p>
  </main>
}

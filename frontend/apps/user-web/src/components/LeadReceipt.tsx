import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { ReceiptButton } from './ReceiptButton'

export function LeadReceipt({ leadId }: { leadId: string }) {
  const token = useUserToken()
  const [orderId, setOrderId] = useState('')
  const [error, setError] = useState(false)
  const [reload, setReload] = useState(0)
  useEffect(() => {
    const controller = new AbortController()
    setOrderId(''); setError(false)
    if (!token) return
    void apiFetch(`${API_BASE_URL}/api/v1/leads/history`, { headers: { Authorization: `Bearer ${token}` }, signal: controller.signal }).then(async response => {
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error('Order unavailable')
      const order = (payload.data as { orderId: string; status: string; items: { leadId: string }[] }[]).find(row => row.status === 'PAID' && row.items.some(item => item.leadId === leadId))
      if (!controller.signal.aborted && order) setOrderId(order.orderId)
    }).catch(() => { if (!controller.signal.aborted) setError(true) })
    return () => controller.abort()
  }, [leadId, token, reload])
  return orderId ? <div style={{ marginTop: 16 }}><ReceiptButton orderId={orderId} /><p><Link to={`/orders/${orderId}`}>View Order Details</Link></p></div> : error ? <button onClick={() => setReload(value => value + 1)}>Retry receipt</button> : null
}

import { useState } from 'react'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'

export function ReceiptButton({ orderId }: { orderId: string }) {
  const token = useUserToken()
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  async function download() {
    if (busy || !token) return
    setBusy(true); setMessage('')
    try {
      const response = await apiFetch(`${API_BASE_URL}/api/v1/leads/receipt/${encodeURIComponent(orderId)}`, {
        headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(45000),
      })
      if (!response.ok) {
        const payload = await response.json().catch(() => null)
        throw new Error(payload?.message || 'Unable to download receipt. Please retry.')
      }
      if (!response.headers.get('content-type')?.includes('application/pdf')) throw new Error('Receipt unavailable. Please retry.')
      const url = URL.createObjectURL(await response.blob())
      const link = document.createElement('a')
      link.href = url; link.download = `NextLead_Receipt_${orderId}.pdf`
      document.body.appendChild(link); link.click(); link.remove()
      window.setTimeout(() => URL.revokeObjectURL(url), 60000)
      setMessage('Receipt download started.')
    } catch (failure) { setMessage(failure instanceof Error ? failure.message : 'Receipt download failed. Please retry.') }
    finally { setBusy(false) }
  }
  return <span><button type="button" disabled={busy || !token} onClick={() => void download()}>{busy ? 'Preparing PDF…' : 'Download Receipt'}</button>{message && <span role="status" style={{ display: 'block', fontSize: 12 }}>{message}</span>}</span>
}

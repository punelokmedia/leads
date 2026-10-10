import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import { useUserToken } from '@/features/auth/useUserToken'

type Entry = { _id: string; kind: string; amountPaise: number; createdAt: string }
type Wallet = { balancePaise: number; referralCreditPaise: number; frozen?: boolean; entries: Entry[]; nextCursor: string | null }
const money = (paise: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(paise / 100)
const labels: Record<string, string> = { TOPUP: 'Money added via Razorpay', REFERRAL: 'Referral reward', LEAD: 'Lead purchase', MEMBERSHIP: 'Membership purchase', REVERSAL: 'Payment or referral reversal' }
let checkoutScript: Promise<void> | undefined
async function loadCheckout() {
  if (window.Razorpay) return
  checkoutScript ??= new Promise<void>((resolve, reject) => {
    const script = document.createElement('script')
    script.src = 'https://checkout.razorpay.com/v1/checkout.js'
    script.onload = () => resolve()
    script.onerror = () => { checkoutScript = undefined; script.remove(); reject(new Error('Unable to load payment checkout. Please retry.')) }
    document.head.appendChild(script)
  })
  await checkoutScript
}

export function WalletPage() {
  const token = useUserToken()
  const [wallet, setWallet] = useState<Wallet | null>(null)
  const [amount, setAmount] = useState('500')
  const [loading, setLoading] = useState(false)
  const [busy, setBusy] = useState(false)
  const [historyLoading, setHistoryLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const paymentLock = useRef(false)
  const mounted = useRef(true)
  useEffect(() => { mounted.current = true; return () => { mounted.current = false } }, [])
  const request = useCallback(async (path: string, body?: unknown) => {
    let response: Response
    try { response = await fetch(`${API_BASE_URL}/api/v1/wallet${path}`, {
      signal: AbortSignal.timeout(15000),
      method: body === undefined ? 'GET' : 'POST',
      headers: { Authorization: `Bearer ${token}`, ...(body === undefined ? {} : { 'Content-Type': 'application/json' }) },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    }) } catch { throw new Error('Unable to reach the wallet server. Check that the backend is running, then retry.') }
    if (response.status === 401) throw new Error('Your session has expired. Sign in again to access your wallet.')
    if (response.status === 404) throw new Error('Wallet is unavailable on this server. The backend needs the wallet update.')
    if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('The wallet server returned an unexpected response. Please retry.')
    const payload = await response.json()
    if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to complete wallet request.')
    return payload.data
  }, [token])
  const refresh = useCallback(async () => {
    setLoading(true)
    setError('')
    try { const data: Wallet = await request(''); if (mounted.current) setWallet(data) }
    catch (failure) { if (mounted.current) setError(failure instanceof Error ? failure.message : 'Unable to load wallet.') }
    finally { if (mounted.current) setLoading(false) }
  }, [request])
  useEffect(() => { setWallet(null); if (token) void refresh() }, [token, refresh])
  const releasePayment = () => { paymentLock.current = false; if (mounted.current) setBusy(false) }

  async function addMoney(event: FormEvent) {
    event.preventDefault()
    if (paymentLock.current) return
    const paise = Math.round(Number(amount) * 100)
    if (!/^\d+(\.\d{1,2})?$/.test(amount) || !Number.isSafeInteger(paise) || paise < 100 || paise > 1000000) {
      setError('Enter an amount between ₹1 and ₹10,000, with up to two decimal places.')
      return
    }
    paymentLock.current = true
    setBusy(true); setError(''); setMessage('')
    try {
      await loadCheckout()
      const order = await request('/topup', { amountPaise: paise })
      if (!mounted.current) { releasePayment(); return }
      if (!window.Razorpay || !order.keyId || !order.razorpayOrderId) throw new Error('Payment checkout is unavailable.')
      const checkout = new window.Razorpay({
        key: order.keyId, order_id: order.razorpayOrderId, amount: order.amountPaise,
        currency: 'INR', name: 'Next Leads', description: 'Wallet top-up', theme: { color: '#F8B020' },
        modal: { ondismiss: releasePayment },
        handler: async (payment: { razorpay_order_id: string; razorpay_payment_id: string; razorpay_signature: string }) => {
          try {
            await request('/verify', { razorpayOrderId: payment.razorpay_order_id, razorpayPaymentId: payment.razorpay_payment_id, razorpaySignature: payment.razorpay_signature })
            if (mounted.current) { setMessage('Payment confirmed. Money has been added to your wallet.'); await refresh() }
          } catch {
            if (mounted.current) { await refresh(); if (mounted.current) setError('Payment confirmation is pending. Refresh your balance before paying again.') }
          } finally { releasePayment() }
        },
      })
      checkout.on('payment.failed', () => { if (mounted.current) setError('Payment failed. Please check your balance before retrying.') })
      checkout.open()
    } catch (failure) {
      if (mounted.current) setError(failure instanceof Error ? failure.message : 'Unable to start payment.')
      releasePayment()
    }
  }
  async function olderHistory() {
    if (!wallet?.nextCursor || historyLoading) return
    setHistoryLoading(true); setError('')
    try {
      const data: Pick<Wallet, 'entries' | 'nextCursor'> = await request(`/history?cursor=${encodeURIComponent(wallet.nextCursor)}`)
      if (mounted.current) setWallet(current => current && ({ ...current, entries: [...new Map([...current.entries, ...data.entries].map(entry => [entry._id, entry])).values()], nextCursor: data.nextCursor }))
    } catch (failure) { if (mounted.current) setError(failure instanceof Error ? failure.message : 'Unable to load history.') }
    finally { if (mounted.current) setHistoryLoading(false) }
  }

  if (!token) return <section className="bg-stone-50 px-4 py-20 text-center"><h1 className="text-3xl font-bold">Your wallet, in one place</h1><p className="mt-3 text-stone-600">Sign in to add money and see your wallet transactions.</p><Link to="/auth/mobile" className="mt-6 inline-block rounded-xl bg-[#F8B020] px-8 py-3 font-semibold text-stone-900">Sign in</Link></section>
  return <section className="min-h-[70vh] bg-[#f6f5f2] px-4 py-8 sm:py-12"><div className="mx-auto max-w-5xl">
    <div className="mb-8 flex flex-wrap items-center justify-between gap-4"><div><p className="text-xs font-bold uppercase tracking-[0.2em] text-stone-500">Your account</p><h1 className="mt-2 text-3xl font-bold text-stone-900 sm:text-4xl">My Wallet</h1><p className="mt-2 text-stone-600">Add money today. Keep every transaction in view.</p></div><button onClick={() => void refresh()} disabled={loading || historyLoading} className="rounded-xl border border-stone-300 bg-white px-5 py-2.5 text-sm font-semibold disabled:opacity-50">{loading ? 'Refreshing…' : 'Refresh balance'}</button></div>
    {error && <p role="alert" className="mb-5 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">{error}</p>}
    {wallet?.frozen && <p role="alert" className="mb-5 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">Your wallet is under security review. Contact support before adding money or making purchases.</p>}
    {message && <p role="status" className="mb-5 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">{message}</p>}
    <div className="grid gap-6 md:grid-cols-2">
      <div className="rounded-3xl bg-stone-900 p-7 text-white sm:p-9"><div className="flex items-center justify-between"><p className="text-sm text-stone-300">Available balance</p><span aria-hidden="true" className="text-2xl">₹</span></div><p aria-live="polite" className="mt-5 text-5xl font-bold tracking-tight">{wallet ? money(wallet.balancePaise) : loading ? 'Loading…' : '—'}</p><p className="mt-5 text-sm text-stone-300">Use your wallet for leads and lifetime membership on web and mobile.</p><Link to="/auth/mobile?flow=membership" className="mt-3 inline-block text-sm font-semibold text-amber-300">Activate membership →</Link><div className="mt-8 border-t border-white/15 pt-5"><p className="text-sm text-stone-300">Lifetime referral rewards</p><p className="mt-1 text-lg font-semibold">{wallet ? money(wallet.referralCreditPaise) : '—'} <span className="text-sm font-normal text-stone-400">of ₹100</span></p><Link to="/referrals" className="mt-3 inline-block text-sm font-semibold text-amber-300">Refer & earn →</Link></div></div>
      <form onSubmit={addMoney} className="rounded-3xl border border-stone-200 bg-white p-7 sm:p-9"><h2 className="text-xl font-bold">Add money</h2><p className="mt-2 text-sm text-stone-500">Pay with Razorpay. Your balance updates after confirmation.</p><label htmlFor="wallet-amount" className="mt-6 block text-sm font-semibold">Amount in rupees</label><div className="mt-2 flex items-center rounded-xl border border-stone-300 px-4 focus-within:ring-2 focus-within:ring-amber-400"><span className="text-stone-500">₹</span><input id="wallet-amount" inputMode="decimal" value={amount} onChange={event => setAmount(event.target.value)} disabled={busy} className="w-full bg-transparent px-3 py-3 text-xl outline-none" placeholder="500" required /></div><div className="mt-3 flex flex-wrap gap-2">{[100, 500, 1000, 2000].map(value => <button key={value} type="button" disabled={busy} aria-pressed={amount === String(value)} onClick={() => setAmount(String(value))} className={`rounded-lg border px-3 py-2 text-sm font-semibold ${amount === String(value) ? 'border-amber-400 bg-amber-50 text-amber-900' : 'border-stone-200 text-stone-600'}`}>₹{value.toLocaleString('en-IN')}</button>)}</div><button disabled={busy || !wallet} className="mt-6 w-full rounded-xl bg-[#F8B020] py-3.5 font-bold text-stone-900 transition hover:bg-[#E2A11D] disabled:opacity-50">{busy ? 'Payment in progress…' : 'Add money with Razorpay'}</button><p className="mt-3 text-xs text-stone-500">Minimum ₹1 · Maximum ₹10,000 per top-up</p></form>
    </div>
    <div className="mt-8 overflow-hidden rounded-3xl border border-stone-200 bg-white"><div className="border-b border-stone-100 p-6"><h2 className="text-xl font-bold">Wallet history</h2><p className="mt-1 text-sm text-stone-500">Top-ups, referral rewards, and purchases. Latest first.</p></div>{!wallet ? <p role="status" className="p-8 text-stone-500">{loading ? 'Loading transactions…' : 'Refresh to load your transactions.'}</p> : wallet.entries.length === 0 ? <div className="p-12 text-center"><p className="font-semibold">No transactions yet</p><p className="mt-2 text-sm text-stone-500">Your first confirmed top-up will appear here.</p></div> : <ul className="divide-y divide-stone-100">{wallet.entries.map(entry => <li key={entry._id} className="flex items-center gap-4 px-5 py-5 sm:px-7"><span aria-hidden="true" className={`grid h-10 w-10 shrink-0 place-items-center rounded-full text-lg ${entry.amountPaise >= 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-stone-100 text-stone-600'}`}>{entry.amountPaise >= 0 ? '↙' : '↗'}</span><div className="min-w-0 flex-1"><p className="text-sm font-semibold sm:text-base">{labels[entry.kind] || 'Wallet transaction'}</p><time dateTime={entry.createdAt} className="mt-1 block text-xs text-stone-500">{new Date(entry.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</time></div><p className={`shrink-0 text-sm font-bold sm:text-base ${entry.amountPaise >= 0 ? 'text-emerald-700' : 'text-stone-800'}`}>{entry.amountPaise >= 0 ? '+' : '−'}{money(Math.abs(entry.amountPaise))}</p></li>)}</ul>}{wallet?.nextCursor && <div className="border-t border-stone-100 p-5 text-center"><button disabled={historyLoading || loading} onClick={() => void olderHistory()} className="rounded-xl border border-stone-300 px-6 py-2.5 text-sm font-semibold disabled:opacity-50">{historyLoading ? 'Loading…' : 'Load older transactions'}</button></div>}</div>
  </div></section>
}

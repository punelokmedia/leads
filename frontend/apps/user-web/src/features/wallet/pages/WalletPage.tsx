import { apiFetch } from '@/features/auth/session'
import { RowsSkeleton, Skeleton } from '@/components/loading/Skeleton'
import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { PaymentReview } from '@/components/PaymentReview'
import './wallet.css'
import { API_BASE_URL } from '@/config/api'
import { useUserToken } from '@/features/auth/useUserToken'

type Entry = { _id: string; kind: string; amountPaise: number; createdAt: string }
type Wallet = { balancePaise: number; referralCreditPaise: number; frozen?: boolean; entries: Entry[]; nextCursor: string | null }
const money = (paise: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(paise / 100)
const labels: Record<string, string> = { TOPUP: 'Added Money', REFERRAL: 'Referral Reward', LEAD: 'Purchase Leads', MEMBERSHIP: 'Membership Plan', REVERSAL: 'Payment or referral reversal' }
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
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const [review, setReview] = useState(false)
  const [filter, setFilter] = useState('ALL')
  const token = useUserToken()
  const [wallet, setWallet] = useState<Wallet | null>(null)
  const [amount, setAmount] = useState(params.get('amount') || '500')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [historyLoading, setHistoryLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const paymentLock = useRef(false)
  const mounted = useRef(true)
  useEffect(() => { mounted.current = true; return () => { mounted.current = false } }, [])
  const request = useCallback(async (path: string, body?: unknown) => {
    let response: Response
    try { response = await apiFetch(`${API_BASE_URL}/api/v1/wallet${path}`, {
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

  async function addMoney(event?: FormEvent) {
    event?.preventDefault()
    if (paymentLock.current) return
    const paise = Math.round(Number(amount) * 100)
    if (!/^\d+(\.\d{1,2})?$/.test(amount) || !Number.isSafeInteger(paise) || paise < 100 || paise > 10000000) {
      setError('Enter an amount between ₹1 and ₹1,00,000, with up to two decimal places.')
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
        currency: 'INR', name: 'Next Leads', description: 'Wallet top-up', theme: { color: '#0066ff' },
        modal: { ondismiss: releasePayment },
        handler: async (payment: { razorpay_order_id: string; razorpay_payment_id: string; razorpay_signature: string }) => {
          try {
            const topup = await request('/verify', { razorpayOrderId: order.razorpayOrderId, razorpayPaymentId: payment.razorpay_payment_id, razorpaySignature: payment.razorpay_signature })
            if (mounted.current) navigate(`/wallet/success/${topup._id}${params.get('return') === 'membership' ? '?return=membership' : ''}`, { replace: true })
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

  function reviewPayment(event: FormEvent) {
    event.preventDefault()
    const paise = Math.round(Number(amount) * 100)
    if (!/^\d+(\.\d{1,2})?$/.test(amount) || !Number.isSafeInteger(paise) || paise < 100 || paise > 10000000) {
      setError('Enter an amount between ₹1 and ₹1,00,000, with up to two decimal places.'); return
    }
    setError(''); setReview(true)
  }
  if (token && review) return <PaymentReview kind="topup" amountPaise={Math.round(Number(amount) * 100)} balance={wallet?.balancePaise ?? null} frozen={wallet?.frozen} busy={busy} error={error} onBack={() => setReview(false)} onPay={() => void addMoney()} />
  if (!token) return <section className="bg-stone-50 px-4 py-20 text-center"><h1 className="text-3xl font-bold">Your wallet, in one place</h1><p className="mt-3 text-stone-600">Sign in to add money and see your wallet transactions.</p><Link to="/auth/mobile" className="mt-6 inline-block rounded-xl bg-[#0066ff] px-8 py-3 font-semibold text-white">Sign in</Link></section>
  const entries = wallet?.entries.filter(entry => filter === 'ALL' || entry.kind === filter) ?? []
  return <section className="wallet-page"><div className="wallet-container">
    <header className="wallet-heading"><div><h1><Link to="/" aria-label="Back to home">&#8592;</Link> Wallet</h1><p>Manage your wallet, view transactions and add funds.</p></div></header>
    {error && <p role="alert" className="wallet-alert wallet-alert-error">{error} <button disabled={loading} onClick={() => void refresh()}>Retry</button></p>}
    {wallet?.frozen && <p role="alert" className="wallet-alert wallet-alert-error">Your wallet is under security review. Contact support before adding money or making purchases.</p>}
    {message && <p role="status" className="wallet-alert wallet-alert-success">{message}</p>}
    <div className="wallet-top-grid">
      <section className="wallet-balance-card" aria-label="Wallet balance">
        <div className="wallet-balance-copy"><h2>AVAILABLE BALANCE</h2><p className="wallet-balance" aria-live="polite">{wallet ? money(wallet.balancePaise) : loading ? <Skeleton style={{ width: 150, height: 40 }} /> : '—'}</p><p className="wallet-balance-description">Use wallet balance to purchase<br />leads and membership plans.</p></div>
        <svg className="wallet-art" viewBox="0 0 130 120" fill="none" aria-hidden="true"><defs><linearGradient id="wallet-body" x1="20" y1="30" x2="95" y2="110" gradientUnits="userSpaceOnUse"><stop stopColor="#45a6ff"/><stop offset="1" stopColor="#164be9"/></linearGradient></defs><rect x="23" y="15" width="89" height="62" rx="10" fill="#235de1" transform="rotate(-8 23 15)"/><rect x="17" y="12" width="90" height="65" rx="10" fill="#387ef4" transform="rotate(-6 17 12)"/><rect x="8" y="26" width="112" height="72" rx="15" fill="url(#wallet-body)"/><path d="M8 46h112" stroke="#65b7ff" strokeWidth="7"/><circle cx="87" cy="79" r="25" fill="#1658ed" stroke="#fff" strokeWidth="2"/><circle cx="87" cy="79" r="20" stroke="#76adff"/><text x="87" y="89" textAnchor="middle" fill="white" fontSize="31" fontWeight="700">&#8377;</text></svg>
        <div className="wallet-balance-actions"><button type="button" onClick={() => { document.getElementById('wallet-add')?.scrollIntoView({ behavior: 'smooth', block: 'center' }); document.getElementById('wallet-amount')?.focus() }}><span aria-hidden="true">+</span> Add Money</button><a href="#wallet-history"><span aria-hidden="true">&#9719;</span> View History</a></div>
      </section>
      <form id="wallet-add" onSubmit={reviewPayment} className="wallet-add-card"><h2>Quick Add Money</h2><div className="wallet-presets">{[500, 1000, 2000, 5000].map(value => <button key={value} type="button" disabled={busy} aria-pressed={amount === String(value)} onClick={() => setAmount(String(value))}>{money(value * 100)}</button>)}</div><label htmlFor="wallet-amount">Custom amount</label><div className="wallet-amount-input"><span>&#8377;</span><input id="wallet-amount" inputMode="decimal" value={amount} onChange={event => setAmount(event.target.value)} disabled={busy} required /></div><button className="wallet-add-button" disabled={busy || !wallet || wallet.frozen}>{busy ? 'Payment in progress...' : 'Add ' + money(Math.round((Number(amount) || 0) * 100))}<span aria-hidden="true">&#8594;</span></button></form>
    </div>
    <section id="wallet-history" className="wallet-history"><header><h2>Transaction History</h2><label className="wallet-history-filter"><span className="sr-only">Filter transactions</span><select value={filter} onChange={event => setFilter(event.target.value)}><option value="ALL">Filter</option>{Object.entries(labels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label></header>
      {!wallet && loading ? <RowsSkeleton /> : !wallet ? <div className="wallet-empty" role="status"><p>{loading ? 'Loading transactions…' : 'Unable to load your transactions.'}</p>{!loading && <button onClick={() => void refresh()}>Refresh wallet</button>}</div> : entries.length === 0 ? <div className="wallet-empty"><div className="wallet-empty-art" aria-hidden="true"><i/><i/><i/><span>◷</span></div><h3>{wallet.entries.length ? 'No matching transactions' : 'No transactions yet'}</h3><p>{wallet.entries.length ? 'Choose another transaction type or load older transactions.' : 'Your top-ups, purchases and referral rewards will appear here.'}</p></div> : <ul className="wallet-entries">{entries.map(entry => <li key={entry._id}><span className={entry.kind === 'MEMBERSHIP' ? 'wallet-membership-icon' : entry.amountPaise >= 0 ? 'wallet-credit-icon' : 'wallet-debit-icon'} aria-hidden="true">{entry.amountPaise >= 0 ? '↙' : '↗'}</span><div><h3>{labels[entry.kind] || 'Wallet transaction'}</h3><time dateTime={entry.createdAt}>{new Date(entry.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Kolkata' })} IST</time></div><strong className={entry.amountPaise >= 0 ? 'wallet-credit' : 'wallet-debit'}>{entry.amountPaise >= 0 ? '+' : '−'}{money(Math.abs(entry.amountPaise))}<small className="wallet-entry-status">Completed</small></strong></li>)}</ul>}
      {wallet?.nextCursor && <div className="wallet-load-more"><button disabled={historyLoading || loading} onClick={() => void olderHistory()}>{historyLoading ? 'Loading…' : 'Load older transactions'}</button></div>}
    </section>
  </div></section>
}

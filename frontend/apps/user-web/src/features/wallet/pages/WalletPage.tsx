import { apiFetch } from '@/features/auth/session'
import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { PaymentReview } from '@/components/PaymentReview'
import './wallet.css'
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
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const [review, setReview] = useState(false)
  const [filter, setFilter] = useState('ALL')
  const token = useUserToken()
  const [wallet, setWallet] = useState<Wallet | null>(null)
  const [amount, setAmount] = useState(params.get('amount') || '100')
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
    <header className="wallet-heading"><div><p className="wallet-eyebrow">YOUR ACCOUNT</p><h1>My Wallet</h1><p>Add money to unlock leads and manage your transactions.</p></div><Link className="wallet-close" to="/">Close</Link></header>
    {error && <p role="alert" className="wallet-alert wallet-alert-error">{error} <button disabled={loading} onClick={() => void refresh()}>Retry</button></p>}
    {wallet?.frozen && <p role="alert" className="wallet-alert wallet-alert-error">Your wallet is under security review. Contact support before adding money or making purchases.</p>}
    {message && <p role="status" className="wallet-alert wallet-alert-success">{message}</p>}
    <div className="wallet-top-grid">
      <section className="wallet-balance-card" aria-label="Wallet balance"><div className="wallet-balance-copy"><h2>Available Balance</h2><p className="wallet-balance" aria-live="polite">{wallet ? money(wallet.balancePaise) : loading ? 'Loading…' : '—'}</p><p className="wallet-balance-description">Use your wallet to purchase leads, access premium features and manage your membership on web and mobile.</p><Link className="wallet-membership-link" to="/pricing">View Membership Plans <span>→</span></Link></div>
        <div className="wallet-art" aria-hidden="true"><div /><div /><div><strong>₹</strong><span>○</span></div></div>
        <div className="wallet-rewards"><div><p>Lifetime Referral Rewards</p><strong>{wallet ? money(wallet.referralCreditPaise) : '—'} <small>of ₹100</small></strong></div><Link to="/referrals">Refer &amp; Earn →</Link></div>
      </section>
      <form onSubmit={reviewPayment} className="wallet-add-card"><h2>Add Money</h2><p>Pay securely with Razorpay. Your balance will be updated after confirmation.</p><label htmlFor="wallet-amount">Amount (in Rupees)</label><div className="wallet-amount-input"><span>₹</span><input id="wallet-amount" inputMode="decimal" value={amount} onChange={event => setAmount(event.target.value)} disabled={busy} required /></div><div className="wallet-presets">{[100, 500, 1000, 2000].map(value => <button key={value} type="button" disabled={busy} aria-pressed={amount === String(value)} onClick={() => setAmount(String(value))}>₹{value.toLocaleString('en-IN')}</button>)}</div><button className="wallet-add-button" disabled={busy || !wallet || wallet.frozen}><svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><rect x="3" y="5" width="18" height="15" rx="2"/><path d="M3 9h18m-6 5h3"/></svg>{busy ? 'Payment in progress…' : 'Add Money with Razorpay'}</button><p className="wallet-topup-limits">Minimum ₹1 · Maximum ₹1,00,000 per top-up</p></form>
    </div>
    <section className="wallet-history"><header><div><h2>Wallet History</h2><p>Top-ups, referral rewards, and purchases. Latest first.</p></div><label className="wallet-history-filter"><span className="sr-only">Filter transactions</span><select value={filter} onChange={event => setFilter(event.target.value)}><option value="ALL">All Transactions</option>{Object.entries(labels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label></header>
      {!wallet ? <div className="wallet-empty" role="status"><p>{loading ? 'Loading transactions…' : 'Unable to load your transactions.'}</p>{!loading && <button onClick={() => void refresh()}>Refresh wallet</button>}</div> : entries.length === 0 ? <div className="wallet-empty"><div className="wallet-empty-art" aria-hidden="true"><i/><i/><i/><span>◷</span></div><h3>{wallet.entries.length ? 'No matching transactions' : 'No transactions yet'}</h3><p>{wallet.entries.length ? 'Choose another transaction type or load older transactions.' : 'Your top-ups, purchases and referral rewards will appear here.'}</p></div> : <ul className="wallet-entries">{entries.map(entry => <li key={entry._id}><span className={entry.amountPaise >= 0 ? 'wallet-credit-icon' : 'wallet-debit-icon'} aria-hidden="true">{entry.amountPaise >= 0 ? '↙' : '↗'}</span><div><h3>{labels[entry.kind] || 'Wallet transaction'}</h3><time dateTime={entry.createdAt}>{new Date(entry.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Kolkata' })} IST</time></div><strong className={entry.amountPaise >= 0 ? 'wallet-credit' : ''}>{entry.amountPaise >= 0 ? '+' : '−'}{money(Math.abs(entry.amountPaise))}</strong></li>)}</ul>}
      {wallet?.nextCursor && <div className="wallet-load-more"><button disabled={historyLoading || loading} onClick={() => void olderHistory()}>{historyLoading ? 'Loading…' : 'Load older transactions'}</button></div>}
    </section>
  </div></section>
}

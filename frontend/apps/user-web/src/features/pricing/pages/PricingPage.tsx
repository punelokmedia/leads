import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import './membership.css'
import { PaymentReview } from '@/components/PaymentReview'

const benefits = [
  ['◎', 'Discover Business Leads', 'Find relevant leads and grow your business category.'],
  ['♛', 'Lifetime Membership Access', 'Pay once and access your membership without recurring membership fees.'],
  ['♧', 'Find Opportunities by Location', 'Explore leads relevant to your preferred city and service area.'],
  ['↗', 'Grow Your Business', 'Discover new projects and expand your network by connecting with potential customers.'],
]
let scriptPromise: Promise<void> | undefined
async function loadCheckout() {
  if (window.Razorpay) return
  scriptPromise ??= new Promise<void>((resolve, reject) => {
    const script = document.createElement('script')
    script.src = 'https://checkout.razorpay.com/v1/checkout.js'
    script.onload = () => resolve()
    script.onerror = () => { scriptPromise = undefined; script.remove(); reject(new Error('Unable to load Razorpay. Please retry.')) }
    document.head.appendChild(script)
  })
  await scriptPromise
}
export function PricingPage() {
  const [params] = useSearchParams()
  const token = useUserToken()
  const navigate = useNavigate()
  const [choosing, setChoosing] = useState(false)
  const [busy, setBusy] = useState(false)
  const [active, setActive] = useState(false)
  const [checking, setChecking] = useState(Boolean(token))
  const [balance, setBalance] = useState<number | null>(null)
  const [frozen, setFrozen] = useState(false)
  const [error, setError] = useState('')
  const lock = useRef(false)
  const mounted = useRef(true)
  useEffect(() => { mounted.current = true; return () => { mounted.current = false } }, [])
  async function request(path: string, body?: object) {
    const response = await apiFetch(`${API_BASE_URL}/api/v1${path}`, {
      method: body ? 'POST' : 'GET', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      ...(body ? { body: JSON.stringify(body) } : {}),
    })
    const payload = await response.json()
    if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to complete your request.')
    return payload.data
  }
  useEffect(() => {
    let cancelled = false
    setActive(false); setBalance(null); setError(''); setChoosing(params.has('checkout'))
    if (!token) { setChecking(false); return }
    setChecking(true)
    const read = async (path: string) => {
      const response = await apiFetch(`${API_BASE_URL}/api/v1${path}`, { headers: { Authorization: `Bearer ${token}` } })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load account.')
      return payload.data
    }
    void Promise.all([read('/auth/profile'), read('/wallet').catch(() => null)]).then(([profile, wallet]) => {
      if (!cancelled) { setActive(Boolean(profile.registrationFeePaid)); setBalance(wallet?.balancePaise ?? null); setFrozen(Boolean(wallet?.frozen)) }
    }).catch(failure => { if (!cancelled) setError(failure instanceof Error ? failure.message : 'Unable to load membership.') })
      .finally(() => { if (!cancelled) setChecking(false) })
    return () => { cancelled = true }
  }, [token, params])
  const release = () => { lock.current = false; if (mounted.current) setBusy(false) }
  const activate = async () => {
    const profile = await request('/auth/profile')
    if (!profile.registrationFeePaid) throw new Error('Membership confirmation is pending. Refresh before paying again.')
    localStorage.setItem('user_profile', JSON.stringify(profile))
    if (mounted.current) navigate('/membership/success', { replace: true, state: { verifiedMembership: profile } })
  }
  async function pay(method: 'razorpay' | 'wallet') {
    if (lock.current || active) return
    if (!token) { navigate('/login'); return }
    lock.current = true; setBusy(true); setError('')
    try {
      if (method === 'wallet') { await request('/wallet/membership', {}); await activate(); release(); return }
      await loadCheckout()
      const order = await request('/auth/mobile/create-registration-order', {})
      if (!mounted.current) { release(); return }
      if (!window.Razorpay || !order.keyId || order.amount !== 49900 || order.currency !== 'INR') throw new Error('Membership checkout is unavailable. Please retry.')
      const checkout = new window.Razorpay({
        key: order.keyId, order_id: order.orderId, amount: order.amount, currency: order.currency,
        name: 'NextLead', description: 'Lifetime Membership', theme: { color: '#0066ff' },
        modal: { ondismiss: release },
        handler: async (payment: { razorpay_payment_id: string; razorpay_signature: string }) => {
          try {
            await request('/auth/mobile/verify-registration-payment', { razorpayOrderId: order.orderId, razorpayPaymentId: payment.razorpay_payment_id, razorpaySignature: payment.razorpay_signature })
            await activate()
          } catch (failure) {
            if (mounted.current) setError(`${failure instanceof Error ? failure.message : 'Payment confirmation is pending.'} If charged, refresh before paying again or contact support.`)
          } finally { release() }
        },
      })
      checkout.on('payment.failed', () => { if (mounted.current) setError('Payment failed. You can retry or choose your wallet.') })
      checkout.open()
    } catch (failure) { if (mounted.current) setError(failure instanceof Error ? failure.message : 'Unable to start payment.'); release() }
  }
  if (choosing && !active) return <PaymentReview kind="membership" amountPaise={49900} balance={balance} frozen={frozen} busy={busy || checking} error={error} onBack={() => { setChoosing(false); navigate('/pricing', { replace: true }) }} onPay={method => void pay(method)} onAddMoney={() => navigate(`/wallet?amount=${Math.max(1, (49900 - (balance ?? 0)) / 100)}&return=membership`)} />
  return <div className="membership-page">
    <img className="membership-ribbon ribbon-left" src="/NextLead Arrow only.png" alt="" aria-hidden="true" />
    <img className="membership-ribbon ribbon-right" src="/NextLead Arrow only.png" alt="" aria-hidden="true" />
    <section className="membership-card" aria-labelledby="membership-title">
      <div className="membership-heading"><p>Only <strong>₹499<span aria-hidden="true">♛</span></strong></p><h1 id="membership-title">Lifetime <b>Membership Plan</b></h1><p className="membership-description">One-time payment. Lifetime membership. A smarter way to discover business opportunities.</p></div>
      <div className="membership-benefits">{benefits.map(([icon, title, copy], index) => <article key={title}><span className="membership-benefit-icon" aria-hidden="true">{icon}</span><small>0{index + 1}</small><h2>{title}</h2><p>{copy}</p></article>)}</div>
      {error && <p className="membership-error" role="alert">{error}</p>}
      {active ? <div className="membership-success" role="status"><h2>Your lifetime membership is active</h2><Link to="/?browse=1">Explore leads →</Link></div> : <>
        <button className="membership-pay" disabled={checking || busy} onClick={() => { if (!token) navigate('/login'); else setChoosing(true) }}>{checking ? 'Checking membership…' : 'Get Lifetime Membership →'}</button>
        <p className="membership-note">Join service professionals who are growing with NextLead.</p>
        <p className="membership-fine-print">Membership is a one-time purchase. Leads are purchased separately.</p>
      </>}
    </section>
  </div>
}

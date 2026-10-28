import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import './membership-success.css'

type Membership = { _id: string; registrationFeePaid: boolean; registrationFeePaidAt?: string; registrationPayment?: { amount?: number; razorpayPaymentId?: string } }
const benefits = [
  ['◎', 'Discover Business Leads', 'Find relevant leads across your service category.'],
  ['∞', 'Lifetime Membership Access', 'Pay once and access your membership without recurring fees.'],
  ['▤', 'Access Lead Details', 'Unlock eligible lead information and connect with potential customers.'],
  ['⌖', 'Find Opportunities by Location', 'Explore leads relevant to your preferred city and service area.'],
  ['↗', 'Grow Your Business', 'Discover new projects and spend less time searching for customers.'],
]
export function MembershipSuccessPage() {
  const token = useUserToken()
  const location = useLocation()
  const [attempt, setAttempt] = useState(0)
  const confirmed = attempt === 0 ? location.state?.verifiedMembership as Membership | undefined : undefined
  return <MembershipSuccessContent key={`${token}:${location.key}:${attempt}`} token={token} confirmed={confirmed} retry={() => setAttempt(value => value + 1)} />
}
function MembershipSuccessContent({ token, confirmed, retry }: { token: string | null; confirmed?: Membership; retry: () => void }) {
  const [profile, setProfile] = useState<Membership | null>(() => token && confirmed?.registrationFeePaid ? confirmed : null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(() => !(token && confirmed?.registrationFeePaid))
  useEffect(() => {
    let cancelled = false
    if (!token) return
    void apiFetch(`${API_BASE_URL}/api/v1/auth/profile`, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(15000) })
      .then(async response => {
        const payload = await response.json()
        if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to confirm membership.')
        if (!cancelled) setProfile(payload.data)
      }).catch(failure => { if (!cancelled) { setProfile(null); setError(failure instanceof Error ? failure.message : 'Unable to confirm membership.') } })
      .finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [token])
  if (!token || loading || !profile?.registrationFeePaid) return <section className="membership-status"><h1>{token && loading ? 'Confirming your membership…' : !token ? 'Sign in to view your membership' : error ? 'Unable to confirm membership' : 'Membership payment is not confirmed'}</h1>{error && <p role="alert">{error}</p>}<p>Your membership status is checked securely with your account.</p>{!token ? <Link to="/login">Sign in</Link> : <><button onClick={retry}>Check again</button><Link to="/pricing">Back to Membership</Link></>}</section>
  const payment = profile.registrationPayment
  const date = profile.registrationFeePaidAt ? new Date(profile.registrationFeePaidAt) : null
  const formattedDate = date && !Number.isNaN(date.getTime()) ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Kolkata' }).format(date) + ' IST' : 'Unavailable'
  return <div className="membership-success-page"><div className="membership-success-inner">
    <header className="membership-success-heading"><div className="success-confetti" aria-hidden="true"><i /><i /><i /><i /><i /><span>✓</span></div><h1>Payment <span>Successful!</span></h1><h2>Your Lifetime Membership is now active.</h2><p>You can now explore business leads, access eligible lead details and connect with<br className="success-desktop-break" /> potential customers on NextLead.</p></header>
    <section className="success-details" aria-labelledby="membership-details-title"><div><h2 id="membership-details-title">Membership Details</h2><dl><div><dt>Plan</dt><dd>Lifetime Membership Plan</dd></div><div><dt>Amount Paid</dt><dd><strong>{typeof payment?.amount === 'number' ? new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(payment.amount) : 'Unavailable'}</strong></dd></div><div><dt>Payment Date</dt><dd>{formattedDate}</dd></div><div><dt>{payment?.razorpayPaymentId ? 'Payment ID' : 'Wallet Reference'}</dt><dd className="success-reference">{payment?.razorpayPaymentId || `membership:${profile._id}`}</dd></div></dl></div><div className="success-receipt" aria-hidden="true"><div className="receipt-back" /><div className="receipt-paper"><img src="/optimized/home/logo.webp" alt="" /><div /><div /><div /><span>✓</span></div></div></section>
    <section className="success-includes" aria-labelledby="membership-includes-title"><h2 id="membership-includes-title">Your Membership Includes</h2><div className="success-benefits">{benefits.map(([icon, title, copy]) => <article key={title}><span aria-hidden="true">{icon}</span><h3>{title}</h3><p>{copy}</p></article>)}</div><p className="success-lead-note">Leads are purchased separately.</p></section>
    <div className="success-actions"><Link to="/?browse=1">Explore Leads Now →</Link><Link to="/profile">Go to Dashboard</Link></div>
  </div></div>
}

import { useEffect, useState } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import './wallet-success.css'

type Receipt = { topup: { _id: string; status: string; amountPaise: number; paymentId: string; paidAt: string; reversedPaise: number; disputed: boolean }; balancePaise: number }
const money = (paise: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(paise / 100)
export function WalletSuccessPage() {
  const { topupId } = useParams()
  const token = useUserToken()
  const [attempt, setAttempt] = useState(0)
  return <WalletSuccessContent key={`${token}:${topupId}:${attempt}`} retry={() => setAttempt(value => value + 1)} />
}
function WalletSuccessContent({ retry }: { retry: () => void }) {
  const { topupId } = useParams()
  const [params] = useSearchParams()
  const token = useUserToken()
  const [receipt, setReceipt] = useState<Receipt | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)
  useEffect(() => {
    let cancelled = false

    if (!token) return
    void apiFetch(`${API_BASE_URL}/api/v1/wallet/topups/${encodeURIComponent(topupId || '')}`, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(15000) })
      .then(async response => {
        const payload = await response.json()
        if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load payment details.')
        if (!cancelled) setReceipt(payload.data)
      }).catch(failure => { if (!cancelled) setError(failure instanceof Error ? failure.message : 'Unable to confirm your top-up.') })
      .finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [token, topupId])
  const confirmed = receipt?.topup.status === 'PAID' && !receipt.topup.reversedPaise && !receipt.topup.disputed
  if (!token || loading || !confirmed) return <section className="wallet-success-status"><h1>{token && loading ? 'Confirming your wallet top-up…' : !token ? 'Sign in to view this payment' : 'Wallet top-up is not confirmed'}</h1><p role={error ? 'alert' : 'status'}>{error || (!loading && token ? 'Return to your wallet to check your balance and transaction history.' : '')}</p>{!token ? <Link to="/login">Sign in</Link> : <><button onClick={retry}>Check again</button><Link to="/wallet">Go to Wallet</Link></>}</section>
  const { topup, balancePaise } = receipt
  const date = new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Kolkata' }).format(new Date(topup.paidAt))
  async function copyReference() {
    try { await navigator.clipboard.writeText(topup.paymentId); setCopied(true) }
    catch { setCopied(false); setError('Unable to copy automatically. Select and copy the transaction ID.') }
  }
  return <section className="wallet-success-page"><div className="wallet-success-card">
    <header className="wallet-success-heading"><div className="wallet-success-confetti" aria-hidden="true">{Array.from({ length: 8 }, (_, index) => <i key={index} />)}<span>✓</span></div><h1>Payment Successful!</h1><p>Your wallet has been topped up successfully. You can now purchase leads<br className="wallet-success-break" /> and access premium features.</p></header>
    <div className="wallet-success-receipt"><dl>
      <div><dt><span aria-hidden="true">▤</span>Transaction ID</dt><dd className="wallet-success-reference">{topup.paymentId}<button onClick={() => void copyReference()} aria-label="Copy transaction ID">{copied ? '✓' : '⧉'}</button></dd></div>
      <div><dt><span aria-hidden="true">▦</span>Date &amp; Time</dt><dd>{date} IST</dd></div>
      <div><dt><span aria-hidden="true">₹</span>Amount Added</dt><dd><strong>{money(topup.amountPaise)}</strong></dd></div>
      <div><dt><span aria-hidden="true">▣</span>Payment Method</dt><dd>Razorpay</dd></div>
      <div><dt><span aria-hidden="true">▱</span>Updated Wallet Balance</dt><dd><strong>{money(balancePaise)}</strong></dd></div>
    </dl></div>
    <div className="wallet-success-illustration" aria-hidden="true"><div /><div className="wallet-success-pocket"><b>₹</b><span>●</span></div><i>✓</i></div>
    {copied && <p className="wallet-success-copy" role="status">Transaction ID copied.</p>}{error && <p className="wallet-success-copy" role="alert">{error}</p>}
    <div className="wallet-success-actions"><Link to={params.get('return') === 'membership' ? '/pricing?checkout=1' : '/?browse=1'}>{params.get('return') === 'membership' ? 'Continue to Membership' : 'Explore Leads'} →</Link><Link to="/wallet">Go to Wallet</Link></div>
  </div></section>
}

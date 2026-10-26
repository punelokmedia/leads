import { useState } from 'react'
import { Link } from 'react-router-dom'
import './payment-review.css'

const money = (value: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(value / 100)
type Props = {
  kind: 'membership' | 'topup'; amountPaise: number; balance: number | null; frozen?: boolean
  busy: boolean; error: string; onBack: () => void; onPay: (method: 'wallet' | 'razorpay') => void
  onAddMoney?: () => void
}
export function PaymentReview({ kind, amountPaise, balance, frozen, busy, error, onBack, onPay, onAddMoney }: Props) {
  const [method, setMethod] = useState<'wallet' | 'razorpay'>('razorpay')
  const membership = kind === 'membership'
  const insufficient = method === 'wallet' && (balance === null || balance < amountPaise || frozen)
  const title = membership ? 'Lifetime Membership Plan' : 'NextLead Wallet Top-up'
  return <section className="payment-review">
    <button className="payment-back" disabled={busy} onClick={onBack}>← Back to {membership ? 'Membership' : 'Wallet'}</button>
    <header className="payment-title"><h1>{membership ? <>Complete Your <span>Membership</span></> : <>Add Money to Your <span>Wallet</span></>}</h1><p>{membership ? 'You’re one step away from unlocking more business opportunities.' : 'Review your top-up before continuing to secure payment.'}</p></header>
    <div className="payment-columns"><div>
      <section className="payment-panel"><h2>Select Payment Method</h2><div className="payment-methods">
        <div className="payment-method-list" role="group" aria-label="Payment method">
          <button disabled={busy} aria-pressed={method === 'razorpay'} onClick={() => setMethod('razorpay')}>◈ Razorpay</button>
          {membership && <button disabled={busy} aria-pressed={method === 'wallet'} onClick={() => setMethod('wallet')}>▣ NextLead Wallet</button>}
        </div><div className="payment-method-description">{method === 'razorpay' ? <><div className="payment-method-symbol" aria-hidden="true">↗</div><h3>Pay securely with Razorpay</h3><p>Choose UPI, card, net banking or a supported payment wallet in Razorpay checkout.</p><div className="payment-method-tags"><span>UPI</span><span>Cards</span><span>Net Banking</span></div></> : <><div className="payment-method-symbol" aria-hidden="true">▣</div><h3>Your NextLead Wallet</h3><strong>{balance === null ? 'Balance unavailable' : money(balance)}</strong><p>{frozen ? 'Your wallet is under review. Contact support.' : balance === null ? 'Return to your wallet to refresh the balance.' : balance < amountPaise ? `Add ${money(amountPaise - balance)} to complete your membership purchase.` : `${money(amountPaise)} will be deducted after you confirm.`}</p>{!frozen && balance !== null && balance < amountPaise && <button className="payment-add-money" disabled={busy} onClick={onAddMoney}>Add {money(amountPaise - balance)} →</button>}</>}</div>
      </div></section>
      <section className="payment-panel payment-details"><h2>Payment Details</h2><dl><div><dt>{membership ? 'Plan' : 'Purpose'}</dt><dd>{title}</dd></div><div><dt>Amount</dt><dd>{money(amountPaise)}</dd></div>{!membership && balance !== null && <><div><dt>Current wallet balance</dt><dd>{money(balance)}</dd></div><div><dt>Balance after top-up</dt><dd>{money(balance + amountPaise)}</dd></div></>}</dl><div className="payment-total"><strong>Total Payable</strong><strong>{money(amountPaise)}</strong></div>
        {error && <p role="alert" className="payment-error">{error}</p>}
        <button className="payment-confirm" disabled={busy || Boolean(insufficient) || Boolean(!membership && frozen)} onClick={() => onPay(method)}>{busy ? 'Processing…' : `Pay ${money(amountPaise)} ${membership ? 'and Activate Membership' : 'and Add to Wallet'} →`}</button><p className="payment-caption">{method === 'wallet' ? 'Payment from your NextLead wallet balance' : 'Secure payment powered by Razorpay'}</p>
      </section>
    </div><aside><section className="payment-plan"><span>{membership ? 'One-time payment' : 'Wallet credit'}</span>{membership && <svg className="payment-plan-crown" viewBox="0 0 100 90" fill="currentColor" aria-hidden="true"><path d="M8 12 30 32 50 5 70 32 92 12 80 65H20L8 12Z" /><rect x="21" y="70" width="58" height="15" rx="3" /></svg>}<h2>{title}</h2><strong>{money(amountPaise).replace('.00', '')}</strong><p>{membership ? 'One payment. Lifetime access.' : 'Add money now. Use it for leads and membership.'}</p></section>
      <section className="payment-panel"><h2>{membership ? 'Plan Includes' : 'Your Wallet'}</h2><ul className="payment-benefits">{(membership ? ['Discover Business Leads', 'Lifetime Membership Access', 'Find Opportunities by Location', 'Grow Your Business'] : ['Use your balance to purchase leads', 'Pay for lifetime membership', 'Track every wallet transaction', 'Balance updates after payment verification']).map((label, index) => <li key={label}><span aria-hidden="true">{['◎', '∞', '⌖', '↗'][index]}</span><div><h3>{label}</h3><p>{membership ? ['Find relevant leads across your service category.', 'Pay once without recurring membership fees.', 'Explore leads in your preferred city and service area.', 'Discover new projects and connect with potential customers.'][index] : 'Available across your NextLead account.'}</p></div></li>)}</ul>{membership && <p className="payment-caption">Leads are purchased separately.</p>}</section>
      <section className="payment-security"><strong>✓ Secure Payment</strong><p>{membership ? 'Membership activates after payment is confirmed.' : 'Your wallet is credited only after payment is confirmed.'}</p><Link to="/contact-support">Need help? Contact support</Link></section>
    </aside></div>
  </section>
}

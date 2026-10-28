import { useEffect, useState, type Dispatch, type SetStateAction } from 'react'
import { Link } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import './referral.css'
import { RowsSkeleton, Skeleton } from '@/components/loading/Skeleton'

type Summary = { referralCode: string; referralLink: string; invited: number; qualified: number; pending: number }
type Entry = { _id: string; status: 'PENDING' | 'QUALIFIED' | 'REVIEW'; createdAt: string; qualifiedAt?: string }
export function ReferralPage() {
  const token = useUserToken()
  const [filter, setFilter] = useState('ALL')
  const [page, setPage] = useState(1)
  const [reload, setReload] = useState(0)
  useEffect(() => { window.scrollTo(0, 0) }, [])
  return <ReferralContent key={`${token}:${reload}`} filter={filter} setFilter={setFilter} page={page} setPage={setPage} setReload={setReload} />
}
function ReferralContent({ filter, setFilter, page, setPage, setReload }: {
  filter: string; setFilter: Dispatch<SetStateAction<string>>; page: number
  setPage: Dispatch<SetStateAction<number>>; setReload: Dispatch<SetStateAction<number>>
}) {
  const token = useUserToken()
  const [summary, setSummary] = useState<Summary | null>(null)
  const [rewards, setRewards] = useState<number | null>(null)
  const [rewardsLoading, setRewardsLoading] = useState(true)
  const [entries, setEntries] = useState<Entry[]>([])


  const [total, setTotal] = useState(0)
  const requestKey = `${filter}:${page}`
  const [settledRequest, setSettledRequest] = useState('')
  const loading = settledRequest !== requestKey
  const [error, setError] = useState('')
  const [historyError, setHistoryError] = useState('')
  const [message, setMessage] = useState('')


  useEffect(() => {
    let cancelled = false

    if (!token) return
    const get = async (path: string) => {
      const response = await apiFetch(`${API_BASE_URL}/api/v1${path}`, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(15000) })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load referrals.')
      return payload.data
    }
    void get('/referrals/me').then(data => { if (!cancelled) setSummary(data) }).catch(failure => { if (!cancelled) setError(failure instanceof Error ? failure.message : 'Unable to load referrals.') })
    void get('/wallet').then(data => { if (!cancelled) setRewards(data.referralCreditPaise) }).catch(() => { /* Show unavailable rather than an invented reward total. */ }).finally(() => { if (!cancelled) setRewardsLoading(false) })
    return () => { cancelled = true }
  }, [token])
  useEffect(() => {
    let cancelled = false

    if (!token) return
    const query = new URLSearchParams({ page: String(page), limit: '20' })
    if (filter !== 'ALL') query.set('status', filter)
    void apiFetch(`${API_BASE_URL}/api/v1/referrals/history?${query}`, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(15000) }).then(async response => {
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load referral history.')
      if (!cancelled) { setEntries(payload.data); setTotal(payload.pagination.total); setHistoryError('') }
    }).catch(failure => { if (!cancelled) { setEntries([]); setHistoryError(failure instanceof Error ? failure.message : 'Unable to load history.') } }).finally(() => { if (!cancelled) setSettledRequest(requestKey) })
    return () => { cancelled = true }
  }, [token, filter, page, requestKey])
  const invite = summary ? `Join me on NextLead to discover business leads. Use my referral code ${summary.referralCode} when you sign up: ${summary.referralLink}` : ''
  async function copy(text: string, label: string) {
    try { await navigator.clipboard.writeText(text); setMessage(`${label} copied.`) }
    catch { setMessage('Unable to copy automatically. Select and copy your referral code below.') }
  }
  async function share() {
    if (!summary) return
    if (navigator.share) {
      try { await navigator.share({ title: 'Join NextLead', text: invite }); return }
      catch (failure) { if (failure instanceof DOMException && failure.name === 'AbortError') return }
    }
    await copy(invite, 'Invite message')
  }
  if (!token) return <section className="referral-signin"><h1>Refer &amp; Earn</h1><p>Sign in to get your referral code and track your rewards.</p><Link to="/login">Sign in</Link></section>
  return <div className="referral-page"><div className="referral-container">
    <section className="referral-hero"><div className="referral-hero-copy"><p className="referral-eyebrow">GROW TOGETHER</p><h1>Refer &amp; <span>Earn</span></h1><p>Know a vendor who could benefit from more business leads?<br/>Invite them to NextLead and get rewarded.</p>
      <div className="referral-share-card"><label htmlFor="referral-code">Your Referral Code</label><div className="referral-code-row"><div><input id="referral-code" readOnly value={summary?.referralCode || (error ? 'Unavailable' : 'Loading…')} /><button disabled={!summary} onClick={() => void copy(summary!.referralCode, 'Referral code')}>⧉ Copy code</button></div><button className="referral-primary" disabled={!summary} onClick={() => void share()}>♧ Share referral invite</button></div><div className="referral-social-row"><p>Share your unique code with your network.</p><div><a className="referral-whatsapp" aria-label="Share invite on WhatsApp" aria-disabled={!summary} href={summary ? `https://wa.me/?text=${encodeURIComponent(invite)}` : undefined} target="_blank" rel="noopener noreferrer"><img src="/referral/whatsapp.svg" alt="" /></a><a className="referral-email" aria-label="Share invite by email" aria-disabled={!summary} href={summary ? `mailto:?subject=Join%20NextLead&body=${encodeURIComponent(invite)}` : undefined}>✉</a><button aria-label="Copy invitation link" disabled={!summary} onClick={() => void copy(summary!.referralLink, 'Invite link')}><img src="/referral/link-small.svg" alt="" /></button><button aria-label="More sharing options" disabled={!summary} onClick={() => void share()}>•••</button></div></div></div>
    </div><div className="referral-network" aria-hidden="true"><div className="referral-speech">Help your network<br/>grow with NextLead</div><div className="referral-people"><span><img src="/referral/invite-person.svg" alt="" /></span><b><img src="/referral/link.svg" alt="" /></b><span><img src="/referral/invite-person.svg" alt="" /></span></div></div></section>
    {(error || historyError) && <p role="alert" className="referral-error">{error || historyError} <button onClick={() => setReload(value => value + 1)}>Retry</button></p>}{message && <p role="status" className="referral-message">{message}</p>}
    <div className="referral-stats">{[['people.svg', summary?.invited ?? '—', 'Total referrals'], ['success.svg', summary?.qualified ?? '—', 'Successful referrals'], ['gift.svg', rewards === null ? '₹ —' : new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(rewards / 100), 'Rewards earned']].map(([icon, value, label]) => <article key={label}><span aria-hidden="true"><img src={`/referral/${icon}`} alt="" /></span><div><strong>{(label === 'Rewards earned' ? rewardsLoading : !summary && !error) ? <Skeleton style={{ width: 80, height: 28 }} /> : <span className="content-reveal">{value}</span>}</strong><p>{label}</p></div></article>)}</div>
    <section className="referral-how"><h2>How it works</h2>{[['Share your code','Send your unique code to vendors in your network.'],['They join NextLead','Your referral signs up using your referral code.'],['Track your rewards','Rewards qualify after their first eligible lead purchase.']].map(([title,copy],index) => <div key={title}><span aria-label={`Step ${index+1}`}><img src={`/referral/step-${index+1}.svg`} alt="" /></span><span className="referral-step-icon" aria-hidden="true"><img src={`/referral/${['link.svg','invite-person.svg','trophy.svg'][index]}`} alt="" /></span><div><h3>{title}</h3><p>{copy}</p></div>{index<2 && <b aria-hidden="true">→</b>}</div>)}</section><p className="referral-policy">Earn ₹50 per eligible referral, up to ₹100 lifetime. Rewards are subject to eligibility checks.</p>
    <section className="referral-history"><header><div><h2>Referral history</h2><p>Track all your referrals and their status.</p></div><div className="referral-tabs" role="group" aria-label="Filter referral history">{[['ALL','All referrals'],['QUALIFIED','Successful'],['PENDING','Pending']].map(([value,label]) => <button key={value} aria-pressed={filter===value} onClick={() => { setFilter(value); setPage(1) }}>{label}</button>)}</div></header>
      {loading && <RowsSkeleton />}<div className="referral-table-scroll" hidden={loading}><table><thead><tr><th>#</th><th>REFERRAL REFERENCE</th><th>JOIN DATE</th><th>STATUS</th><th>QUALIFIED DATE</th></tr></thead><tbody>{entries.map((entry,index) => <tr key={entry._id}><td>{(page-1)*20+index+1}</td><td className="referral-reference">{entry._id}</td><td>{new Date(entry.createdAt).toLocaleDateString('en-IN', { timeZone:'Asia/Kolkata' })}</td><td><span className={`referral-status status-${entry.status.toLowerCase()}`}>{entry.status === 'QUALIFIED' ? 'Successful' : entry.status === 'REVIEW' ? 'Under review' : 'Pending'}</span></td><td>{entry.qualifiedAt ? new Date(entry.qualifiedAt).toLocaleDateString('en-IN', { timeZone:'Asia/Kolkata' }) : '—'}</td></tr>)}</tbody></table></div>
      {!loading && !entries.length && <div className="referral-empty"><span aria-hidden="true"><img src="/referral/empty-referrals.svg" alt="" /></span><h3>{loading ? 'Loading referrals…' : historyError ? 'Unable to load referrals' : filter === 'ALL' ? 'No referrals yet' : 'No matching referrals'}</h3><p>{loading ? 'Getting your latest referral activity.' : 'Your referrals will appear here after you invite vendors.'}</p><button disabled={!summary} onClick={() => void copy(invite, 'Invite message')}>Copy invite message</button></div>}
      {!loading && total>20 && <nav className="referral-pagination" aria-label="Referral history pages"><button disabled={page===1} onClick={() => setPage(value => value-1)}>Previous</button><span>Page {page} of {Math.ceil(total/20)}</span><button disabled={page*20>=total} onClick={() => setPage(value => value+1)}>Next</button></nav>}
    </section>
  </div></div>
}

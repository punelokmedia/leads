import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import './lead-details.css'
import { PageSkeleton } from '@/components/loading/Skeleton'

type Lead = { _id: string; title: string; leadDisplayId: string; description?: string; category?: { name?: string }; createdAt: string; city: string; state: string; isPurchased: boolean; status: string; price: number; customerName?: string; primaryPhone?: string; phone?: string; alternatePhone?: string; email?: string; address?: string; areaLocality?: string; requirement?: string; propertyType?: string; areaSize?: string; budgetRange?: string; timeline?: string; clientType?: string }
export function LeadDetailsPage() {
  const { leadId } = useParams()
  const token = useUserToken()
  const navigate = useNavigate()
  const [lead, setLead] = useState<Lead | null>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [reload, setReload] = useState(0)
  const [tab, setTab] = useState('client')
  useEffect(() => {
    let cancelled = false
    setLead(null); setError(''); setLoading(true)
    void apiFetch(`${API_BASE_URL}/api/v1/leads/get-lead/${encodeURIComponent(leadId || '')}`, { headers: token ? { Authorization: `Bearer ${token}` } : {}, signal: AbortSignal.timeout(15000) }).then(async response => {
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load lead.')
      if (!cancelled) setLead(payload.data)
    }).catch(failure => { if (!cancelled) setError(failure instanceof Error ? failure.message : 'Unable to load lead.') }).finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [leadId, token, reload])
  async function purchase() {
    if (!lead || busy || lead.isPurchased) return
    if (!token) { navigate('/login'); return }
    setBusy(true); setError('')
    try {
      const request = async (path: string, body: object) => {
        const response = await apiFetch(`${API_BASE_URL}/api/v1${path}`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) })
        const payload = await response.json()
        if (payload.code === 'MEMBERSHIP_REQUIRED') { navigate('/pricing'); return false }
        if (payload.code === 'INSUFFICIENT_BALANCE') { navigate('/wallet'); return false }
        if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to purchase lead.')
        return true
      }
      if (!await request('/cart/add-cart', { leadId: lead._id, quantity: 1 })) return
      window.dispatchEvent(new Event('cart:updated'))
      if (!await request('/wallet/purchase', { leadIds: [lead._id], expectedTotalPaise: Math.round(lead.price * 100) })) return
      window.dispatchEvent(new Event('cart:updated')); setReload(value => value + 1)
    } catch (failure) { setError(failure instanceof Error ? failure.message : 'Purchase confirmation pending. Check history before retrying.') }
    finally { setBusy(false) }
  }
  if (loading) return <PageSkeleton />
  if (!lead) return <section className="lead-detail-state"><h1>Unable to load lead</h1>{error && <p role="alert">{error}</p>}<Link to="/?browse=1">Back to leads</Link><button onClick={() => setReload(value => value + 1)}>Retry</button></section>
  const unlocked = lead.isPurchased
  const phone = lead.primaryPhone || lead.phone
  const safePhone = (value?: string) => value?.replace(/[^+\d]/g, '') || ''
  const city = [lead.city, lead.state].filter(Boolean).join(', ')
  const address = unlocked ? [lead.address, lead.areaLocality, city].filter(Boolean).join(', ') : city
  const maps = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`
  const imageIndex = (parseInt(lead._id.slice(-1), 16) || 0) % 3 + 1
  const buyLabel = busy ? 'Purchasing…' : `Buy for ₹${lead.price.toLocaleString('en-IN')} to Unlock`
  return <div className="lead-detail-page"><div className="lead-detail-container">
    <div className="lead-detail-top"><nav aria-label="Breadcrumb"><Link to="/">Home</Link> › <Link to="/categories">All Categories</Link> › {lead.category?.name && <><Link to={`/?category=${encodeURIComponent((lead.category as { _id?: string })._id || '')}`}>{lead.category.name}</Link> › </>}<span>Lead Details</span></nav><span className={unlocked ? 'lead-access unlocked' : 'lead-access'}>{unlocked ? '✓ Lead Unlocked' : 'Customer Details Locked'}</span></div>
    <section className="lead-detail-summary"><img src={`/lead-room-${imageIndex}.jpg`} alt="" /><div><span className="lead-project-tag">{lead.requirement || 'Project enquiry'}</span><h1>{lead.title}</h1><p className="lead-detail-meta">Lead ID: {lead.leadDisplayId} <span> | </span> Posted on {new Date(lead.createdAt).toLocaleDateString('en-IN', { timeZone:'Asia/Kolkata' })}</p><p>{lead.description || `Explore this ${lead.category?.name || 'business'} opportunity in ${city}.`}</p></div></section>
    <nav className="lead-detail-tabs" aria-label="Lead information">{[['client','Client Details'],['requirements','Project Requirements'],['property','Property Details'],['additional','Additional Info']].map(([value,label]) => <a key={value} href={`#lead-${value}`} aria-current={tab===value ? 'location' : undefined} onClick={() => setTab(value)}>{label}</a>)}</nav>
    {error && <p className="lead-detail-error" role="alert">{error}</p>}
    <div className="lead-detail-grid"><div>
      <section id="lead-requirements" className="lead-detail-panel lead-requirements-highlight"><div className="lead-requirements-heading"><div><p className="lead-requirements-eyebrow">THE OPPORTUNITY</p><h2>What the customer needs</h2></div><span>Project Requirements</span></div><p className="lead-requirements-intro">Review the scope and see how this project fits your services before purchasing.</p><div className="lead-opportunity-facts">{[['Customer project budget',lead.budgetRange],['Expected timeline',lead.timeline],['Property type',lead.propertyType],['Project size',lead.areaSize]].filter(([,value]) => Boolean(value?.trim())).map(([label,value]) => <div key={label}><span>{label}</span><strong>{value}</strong></div>)}</div><dl className="lead-specifications">{[['Service Needed',lead.category?.name],['Work Required',lead.requirement],['Client Type',lead.clientType],['Project Location',city]].map(([label,value]) => <div key={label}><dt>{label}</dt><dd>{value || 'Not specified'}</dd></div>)}</dl>{!unlocked && <div className="lead-requirements-next"><div><h3>Is this the right project for your business?</h3><p>Unlock the available customer contact details to discuss the scope and share your quote.</p></div><a href="#lead-client">View unlock options →</a></div>}</section>
      <section id="lead-client" className="lead-detail-panel"><h2>Client Information</h2>{unlocked ? <dl className="lead-client-fields">{[['Client Name',lead.customerName],['Alternate Number',lead.alternatePhone],['Phone Number',phone],['Email Address',lead.email],['Location',address]].map(([label,value]) => <div key={label}><dt>{label}</dt><dd>{value || 'Not provided'}</dd></div>)}</dl> : <div className="lead-locked-content"><div className="lead-locked-placeholders" aria-hidden="true">{['Client Name','Phone Number','Email Address','Exact Location'].map(label => <div key={label}><span>{label}</span><b>••••••••••</b></div>)}</div><div className="lead-lock-prompt"><img src="/leads/shield-lock.svg" alt="" /><h3>Unlock Customer Details</h3><p>Purchase this lead to access the customer’s name, phone number, email and exact location when provided.</p><button disabled={busy || lead.status !== 'ACTIVE'} onClick={() => void purchase()}>{lead.status !== 'ACTIVE' ? 'Lead unavailable' : buyLabel}</button></div></div>}</section>

      <section id="lead-property" className="lead-detail-panel"><h2>Property Details</h2><dl className="lead-specifications">{[['Property Type',lead.propertyType],['Area Size',lead.areaSize],['Client Type',lead.clientType],['City',city]].map(([label,value]) => <div key={label}><dt>{label}</dt><dd>{value || 'Not specified'}</dd></div>)}</dl></section>
      <section id="lead-additional" className="lead-detail-panel"><h2>Additional Information</h2><p className="lead-detail-note">{unlocked ? 'Your purchase gives you access to the available customer details above. Introduce your services clearly and share relevant portfolio examples.' : 'Customer contact information is available after purchasing this lead. Membership and individual lead purchases are separate.'}</p></section>
    </div><aside><section className="lead-detail-panel lead-status-panel"><h2>✓ Lead Status</h2>{unlocked ? <><h3>Payment Successful</h3><p>You can now view and connect with the client.</p>{phone && <a className="lead-detail-primary" href={`tel:${safePhone(phone)}`}>Call Client Now</a>}<div className="lead-contact-actions">{lead.email && <a href={`mailto:${lead.email}`}>Send Email</a>}{phone && <a href={`https://wa.me/${safePhone(phone).replace(/^\+/, '').replace(/^(\d{10})$/, '91$1')}`} target="_blank" rel="noopener noreferrer">WhatsApp</a>}</div><p className="lead-detail-tip">Tip: Introduce your services and share relevant references for a better conversation.</p></> : <><div className="lead-status-lock"><img src="/leads/shield-lock.svg" alt="" /></div><h3>Contact Details Locked</h3><p>Buy this lead to connect directly with the customer.</p><strong className="lead-unlock-price">₹{lead.price.toLocaleString('en-IN')}</strong><button className="lead-detail-primary" disabled={busy || lead.status !== 'ACTIVE'} onClick={() => void purchase()}>{lead.status !== 'ACTIVE' ? 'Lead unavailable' : buyLabel}</button><p className="lead-detail-caption">Paid from your NextLead wallet. One purchase per lead.</p></>}</section>
      <section className="lead-detail-panel"><h2>Location Details</h2><div className="lead-location-preview"><span aria-hidden="true">⌖</span><strong>{city}</strong><p>{unlocked ? lead.areaLocality || 'Customer location' : 'Exact address unlocks after purchase'}</p></div>{unlocked && <a className="lead-map-link" href={maps} target="_blank" rel="noopener noreferrer">Open in Google Maps ↗</a>}</section>
    </aside></div>
  </div></div>
}

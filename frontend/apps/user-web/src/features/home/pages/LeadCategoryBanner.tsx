import { resolveCategory } from './category-resolution'
import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useUserToken } from '@/features/auth/useUserToken'
import { API_BASE_URL } from '@/config/api'
import { apiFetch } from '@/features/auth/session'
import { categories } from './category-catalog'

type Category = { _id: string; name: string }
export function LeadCategoryBanner(props: { count: number; loading: boolean }) {
  const [params] = useSearchParams()
  return <CategoryBannerContent key={params.get('category') || ''} {...props} />
}
function CategoryBannerContent({ count, loading }: { count: number; loading: boolean }) {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const token = useUserToken()
  const [savingAlerts, setSavingAlerts] = useState(false)
  const [alertsEnabled, setAlertsEnabled] = useState(false)
  const [alertError, setAlertError] = useState('')
  async function enableAlerts() {
    if (!token) { navigate('/login'); return }
    if (savingAlerts || alertsEnabled) return
    setSavingAlerts(true)
    setAlertError('')
    try {
      const response = await apiFetch(`${API_BASE_URL}/api/v1/notifications/preferences`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ newLeads: true }),
      })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to enable alerts. Please try again.')
      setAlertsEnabled(true)
    } catch (error) {
      setAlertError(error instanceof Error ? error.message : 'Unable to enable alerts. Please try again.')
    } finally { setSavingAlerts(false) }
  }
  const categoryId = params.get('category')
  const [resolved, setResolved] = useState<Category | null>(null)
  const query = params.get('search')?.trim() || ''
  const known = [...categories, { name: 'Real Estate', image: '/lead-room-1.jpg' }]
  useEffect(() => {
    let cancelled = false
    if (!categoryId) return
    void apiFetch(`${API_BASE_URL}/api/v1/categories/get-all-categories`)
      .then(async response => {
        const payload = await response.json()
        if (!response.ok || !payload.success || !Array.isArray(payload.data)) return
        const category = (payload.data as Category[]).find(item => item._id === categoryId)
        if (!cancelled) setResolved(category ?? null)
      }).catch(() => { /* Keep the generic heading if category lookup is unavailable. */ })
    return () => { cancelled = true }
  }, [categoryId])
  const selected = resolved ? known.find(item => resolveCategory(item.name, [resolved])) : known.find(item => item.name.toLowerCase() === query.toLowerCase())
  const title = categoryId ? resolved?.name || 'Category Leads' : selected?.name || (query ? `Results for “${query}”` : 'All Leads')
  const image = selected?.image
  return <section className="lead-category-banner" aria-label="Current lead category">
    {image ? <img src={encodeURI(image.startsWith('/') ? image : `/categories Images/${image}`)} alt="" /> : <span className="lead-category-symbol" aria-hidden="true">▦</span>}
    <div><h1>{title}</h1><p>{selected || resolved ? `Find genuine ${title.toLowerCase()} leads from your city and nearby areas.` : 'Discover business opportunities from your city and nearby areas.'}</p><small>{loading ? 'Loading leads…' : `${count} ${count === 1 ? 'lead' : 'leads'} shown`}</small></div>
    <div className="lead-category-notify">
      <button type="button" onClick={() => void enableAlerts()} disabled={savingAlerts || alertsEnabled}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M10 21h4M12 2V1" /></svg>
        {savingAlerts ? 'Enabling…' : alertsEnabled ? 'Alerts Enabled' : 'Get Notified'}
      </button>
      <p aria-live="polite">{alertsEnabled ? 'Lead alerts enabled for your profile’s services and location.' : 'Be the first to know new leads'}</p>
      {alertError && <p role="alert">{alertError}</p>}
    </div>
  </section>
}

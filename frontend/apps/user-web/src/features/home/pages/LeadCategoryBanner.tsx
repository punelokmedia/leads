import { resolveCategory } from './category-resolution'
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
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
  </section>
}

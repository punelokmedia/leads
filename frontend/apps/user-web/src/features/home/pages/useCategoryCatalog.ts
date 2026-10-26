import { useEffect, useState } from 'react'
import { API_BASE_URL } from '@/config/api'
import { apiFetch } from '@/features/auth/session'
import type { ApiCategory } from './category-resolution'
let pending: Promise<ApiCategory[]> | undefined
function load() {
  pending ??= apiFetch(`${API_BASE_URL}/api/v1/categories/get-all-categories`).then(async response => {
    const payload = await response.json()
    if (!response.ok || !payload.success || !Array.isArray(payload.data)) throw new Error('Unable to load categories.')
    return payload.data as ApiCategory[]
  }).catch(error => { pending = undefined; throw error })
  return pending
}
export function useCategoryCatalog() {
  const [items, setItems] = useState<ApiCategory[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    let cancelled = false
    void load().then(data => { if (!cancelled) setItems(data) }).catch(() => { if (!cancelled) setError('Unable to load categories. Refresh to retry.') }).finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [])
  return { items, error, loading }
}

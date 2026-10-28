import { LeadFilters } from './LeadFilters'
import { CardSkeletons } from '@/components/loading/Skeleton'
import { LoadingImage } from '@/components/loading/LoadingImage'
import './leads-marketplace.css'
import { LeadCategoryBanner } from './LeadCategoryBanner'
import { useUserToken } from '@/features/auth/useUserToken'
import { apiFetch } from '@/features/auth/session'
import { API_BASE_URL } from '@/config/api'
import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import { useSearchParams, useNavigate } from 'react-router-dom'

const PAGE_LIMIT = 10
const API_BASE_URL_CANDIDATES = [API_BASE_URL]
type LeadsApiItem = {
  _id: string
  leadDisplayId?: string
  title: string
  city: string
  state: string
  description?: string
  clientType?: string
  propertyType?: string
  areaSize?: string
  budgetRange?: string
  timeline?: string
  requirement?: string
  price: number
  originalPrice?: number | null
  buyersCount: number
  maxBuyers: number
  remainingSlots?: number
  createdAt: string
  status: 'ACTIVE' | 'SOLD_OUT' | 'EXPIRED' | string
}

type HomeLead = {
  id: string
  leadDisplayId?: string
  title: string
  image: string
  location: string
  sharing: string
  buyersCount: number
  maxBuyers: number
  remainingSlots: number
  oldPrice: number
  price: number
  clientType?: string
  propertyType?: string
  areaSize?: string
  budgetRange?: string
  timeline?: string
  requirement?: string
  createdAt: string
  isSoldOut: boolean
  unavailableLabel: string
}

type LeadsPagination = {
  page: number
  totalPages: number
}

const mapLeadsForCards = (items: LeadsApiItem[], startIndex: number): HomeLead[] =>
  items.map((lead, index) => ({
    id: lead._id,
    leadDisplayId:
      lead.leadDisplayId ||
      `NL${String(lead._id || '')
        .slice(-8)
        .toUpperCase()}`,
    title: lead.title,
    image: `/lead-room-${((startIndex + index) % 3) + 1}.jpg`,
    location: `${lead.city}, ${lead.state}`,
    sharing: `Sharing Leads (${lead.buyersCount}/${lead.maxBuyers})`,
    buyersCount: lead.buyersCount,
    maxBuyers: lead.maxBuyers,
    remainingSlots: lead.remainingSlots ?? Math.max(0, 2 - lead.buyersCount),
    oldPrice:
      typeof lead.originalPrice === 'number' && lead.originalPrice > lead.price
        ? lead.originalPrice
        : lead.price,
    price: lead.price,
    clientType: lead.clientType,
    propertyType: lead.propertyType,
    areaSize: lead.areaSize,
    budgetRange: lead.budgetRange,
    timeline: lead.timeline,
    requirement: lead.requirement,
    createdAt: lead.createdAt,
    isSoldOut: ['SOLD_OUT', 'RESERVED', 'EXPIRED'].includes(lead.status),
    unavailableLabel: lead.status === 'RESERVED' ? 'Currently unavailable' : lead.status === 'EXPIRED' ? 'Expired' : 'Out of stock',
  }))

const trustPoints = [
  {
    title: 'Human-Verified Leads',
    description:
      'Every enquiry is called and verified by our team before hitting the marketplace.',
  },
  {
    title: 'Instant Lead Alerts',
    description:
      'Get notified the second a high-intent lead matches your service area.',
  },
]

const WHATSAPP_NUMBER = '919067777034'
const WHATSAPP_MESSAGE = encodeURIComponent(
  'Hi, I want to know more about leads for my service category.',
)
const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0 },
}

export function LeadsMarketplacePage() {
  const reducedMotion = useReducedMotion()
  const requestVersion = useRef(0)
  const navigate = useNavigate()
  const [buyingLeadId, setBuyingLeadId] = useState<string | null>(null)
  const [searchParams] = useSearchParams()
  const filterKeys = ['nearby', 'radiusKm', 'priceMin', 'priceMax', 'projectTypes', 'propertyTypes', 'postedFrom', 'postedTo']
  const filterQuery = new URLSearchParams(filterKeys.flatMap(key => searchParams.has(key) ? [[key, searchParams.get(key)!]] : [])).toString()
  const categoryIdParam = searchParams.get('category')
  const cityParam = searchParams.get('city')
  const appliedSearch = searchParams.get('search') ?? ''
  const [selectedSort, setSelectedSort] = useState<'latest' | 'cheapest' | 'expensive'>('latest')
  const [allLeads, setAllLeads] = useState<HomeLead[]>([])
  const [isLeadsLoading, setIsLeadsLoading] = useState(true)
  const [reload, setReload] = useState(0)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [activeCartLeadId, setActiveCartLeadId] = useState<string | null>(null)
  const [cartFeedback, setCartFeedback] = useState('')
  const [leadsError, setLeadsError] = useState('')
  const [pagination, setPagination] = useState<LeadsPagination>({ page: 1, totalPages: 1 })
  const selectedCity = cityParam?.trim() ?? ''
  const hasMoreLeads = pagination.page < pagination.totalPages
  const userToken = useUserToken()



  useEffect(() => {
    const version = ++requestVersion.current
    const fetchLeads = async (page: number, append: boolean) => {
      if (append) {
        setIsLoadingMore(true)
      } else {
        setIsLeadsLoading(true)
        setLeadsError('')
      }

      let networkError: Error | null = null
      for (const baseUrl of API_BASE_URL_CANDIDATES) {
        const controller = new AbortController()
        const timeoutId = window.setTimeout(() => controller.abort(), 10000)
        try {
          const params = new URLSearchParams({
            page: String(page),
            limit: String(PAGE_LIMIT),
            sort: selectedSort,
          })
          if (appliedSearch.trim()) params.set('search', appliedSearch.trim())
          if (selectedCity) params.set('city', selectedCity)
          if (categoryIdParam) params.set('category', categoryIdParam)
          new URLSearchParams(filterQuery).forEach((value, key) => params.set(key, value))

          const response = await apiFetch(
            `${baseUrl}/api/v1/leads/get-all-leads?${params.toString()}`,
            {
            method: 'GET',
            headers: userToken ? { Authorization: 'Bearer ' + userToken } : {},
            signal: controller.signal,
            },
          )
          const payload = await response.json()
          window.clearTimeout(timeoutId)
          if (version !== requestVersion.current) return

          if (!response.ok || !payload?.success) {
            throw new Error(payload?.message ?? 'Unable to fetch leads right now.')
          }

          const items = Array.isArray(payload?.data) ? (payload.data as LeadsApiItem[]) : []
          setAllLeads((prev) => {
            const startIndex = append ? prev.length : 0
            const mapped = mapLeadsForCards(items, startIndex)
            return append ? [...prev, ...mapped] : mapped
          })
          const nextPage = Number(payload?.pagination?.page) || page
          const totalPages = Number(payload?.pagination?.totalPages) || nextPage
          setPagination({ page: nextPage, totalPages })
          setIsLeadsLoading(false)
          setIsLoadingMore(false)
          return
        } catch (error) {
          window.clearTimeout(timeoutId)
          if (version !== requestVersion.current) return
          networkError =
            error instanceof Error ? error : new Error('Unable to fetch leads right now.')
        }
      }

      if (!append) {
        setAllLeads([])
      }
      setLeadsError(networkError?.message ?? 'Unable to fetch leads right now.')
      setIsLeadsLoading(false)
      setIsLoadingMore(false)
    }

    void fetchLeads(1, false)
    return () => { requestVersion.current = version + 1 }
  }, [appliedSearch, selectedCity, selectedSort, categoryIdParam, filterQuery, userToken, reload])

  const handleLoadMore = () => {
    if (isLeadsLoading || isLoadingMore || !hasMoreLeads) return

    const version = requestVersion.current
    const nextPage = pagination.page + 1
    setIsLoadingMore(true)
    setLeadsError('')

    ;(async () => {
      let networkError: Error | null = null
      for (const baseUrl of API_BASE_URL_CANDIDATES) {
        const controller = new AbortController()
        const timeoutId = window.setTimeout(() => controller.abort(), 10000)
        try {
          const params = new URLSearchParams({
            page: String(nextPage),
            limit: String(PAGE_LIMIT),
            sort: selectedSort,
          })
          if (appliedSearch.trim()) params.set('search', appliedSearch.trim())
          if (selectedCity) params.set('city', selectedCity)
          if (categoryIdParam) params.set('category', categoryIdParam)
          new URLSearchParams(filterQuery).forEach((value, key) => params.set(key, value))

          const response = await apiFetch(
            `${baseUrl}/api/v1/leads/get-all-leads?${params.toString()}`,
            {
            method: 'GET',
            headers: userToken ? { Authorization: 'Bearer ' + userToken } : {},
            signal: controller.signal,
            },
          )
          const payload = await response.json()
          window.clearTimeout(timeoutId)
          if (version !== requestVersion.current) return

          if (!response.ok || !payload?.success) {
            throw new Error(payload?.message ?? 'Unable to fetch leads right now.')
          }

          const items = Array.isArray(payload?.data) ? (payload.data as LeadsApiItem[]) : []
          setAllLeads((prev) => [...prev, ...mapLeadsForCards(items, prev.length)])
          const pageValue = Number(payload?.pagination?.page) || nextPage
          const totalPages = Number(payload?.pagination?.totalPages) || pageValue
          setPagination({ page: pageValue, totalPages })
          setIsLoadingMore(false)
          return
        } catch (error) {
          window.clearTimeout(timeoutId)
          if (version !== requestVersion.current) return
          networkError =
            error instanceof Error ? error : new Error('Unable to fetch leads right now.')
        }
      }

      setLeadsError(networkError?.message ?? 'Unable to fetch leads right now.')
      setIsLoadingMore(false)
    })()
  }


  const handleAddToCart = async (leadId: string) => {
    if (!userToken) {
      setCartFeedback('Please login first to add leads in cart.')
      return
    }

    setActiveCartLeadId(leadId)
    setCartFeedback('')
    let networkError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        const response = await apiFetch(`${baseUrl}/api/v1/cart/add-cart`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${userToken}`,
          },
          body: JSON.stringify({ leadId, quantity: 1 }),
        })
        const payload = await response.json()

        if (!response.ok || !payload?.success) {
          throw new Error(payload?.message ?? 'Unable to add lead in cart.')
        }

        setCartFeedback(payload?.message ?? 'Added to cart successfully.')
        window.dispatchEvent(new Event('cart:updated'))
        setActiveCartLeadId(null)
        return
      } catch (error) {
        networkError = error instanceof Error ? error : new Error('Unable to add lead in cart.')
      }
    }

    setCartFeedback(networkError?.message ?? 'Unable to add lead in cart.')
    setActiveCartLeadId(null)
  }

  const handleBuyNow = async (leadId: string) => {
    if (buyingLeadId || activeCartLeadId) return
    if (!userToken) { navigate('/login'); return }
    setBuyingLeadId(leadId)
    setCartFeedback('')
    try {
      const addResponse = await apiFetch(`${API_BASE_URL}/api/v1/cart/add-cart`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userToken}` },
        body: JSON.stringify({ leadId, quantity: 1 }),
      })
      const added = await addResponse.json()
      if (!addResponse.ok || !added.success) throw new Error(added.message || 'Unable to prepare this lead.')
      window.dispatchEvent(new Event('cart:updated'))
      const response = await apiFetch(`${API_BASE_URL}/api/v1/wallet/purchase`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userToken}` },
        body: JSON.stringify({ leadIds: [leadId] }),
      })
      const payload = await response.json()
      if (payload.code === 'MEMBERSHIP_REQUIRED') { navigate('/auth/mobile?flow=membership'); return }
      if (payload.code === 'INSUFFICIENT_BALANCE') { navigate('/wallet'); return }
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to purchase this lead.')
      window.dispatchEvent(new Event('cart:updated'))
      navigate('/my-leads')
    } catch (error) { setCartFeedback(error instanceof Error ? error.message : 'Purchase failed. Check history before retrying.') }
    finally { setBuyingLeadId(null) }
  }

  const handleViewDetails = (leadId: string) => navigate(/leads/ + leadId)

  return (
    <div className="leads-marketplace bg-[#f8fafc]">
      <div className="lead-browse-layout">
        <LeadFilters key={searchParams.toString()} />


      <motion.section
        className="mx-auto max-w-7xl px-4 py-12 sm:px-6"
        initial={false}
        animate="visible"
        viewport={{ once: true, amount: 0.2 }}
        variants={fadeUp}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
        <LeadCategoryBanner count={allLeads.length} loading={isLeadsLoading} />
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="text-3xl font-black text-stone-900">Available Leads</h2>
            <p className="mt-1 text-sm text-stone-500">
              Hand-picked leads from bangalore and beyond
            </p>
          </div>
          <label className="text-sm font-semibold text-stone-600">
            Sort by
            <select
              value={selectedSort}
              onChange={(event) =>
                setSelectedSort(event.target.value as 'latest' | 'cheapest' | 'expensive')
              }
              className="mt-1 ml-2 rounded-lg border border-stone-300 bg-white px-3 py-1.5 text-sm text-stone-700 outline-none"
            >
              <option value="latest">Latest</option>
              <option value="cheapest">Cheapest</option>
              <option value="expensive">Expensive</option>
            </select>
          </label>
        </div>
        {isLeadsLoading && !allLeads.length ? (
          <CardSkeletons />
        ) : leadsError ? (
          <p className="mt-7 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {leadsError} <button type="button" onClick={() => setReload(value => value + 1)}>Retry</button>
          </p>
        ) : allLeads.length === 0 ? (
          <p className="mt-7 rounded-xl border border-stone-200 bg-white px-4 py-3 text-sm text-stone-600">
            No leads available right now.
          </p>
        ) : (
          <div className="lead-results-grid content-reveal" aria-busy={isLeadsLoading}>
            <AnimatePresence mode="popLayout">
              {allLeads.map((lead, index) => (
                <motion.article
                  key={lead.id}
                  layout
                  initial={reducedMotion ? false : { opacity: 0, y: 16 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={reducedMotion ? { opacity: 1 } : { opacity: 0, y: 12 }}
                  transition={{ duration: reducedMotion ? 0 : 0.2, delay: reducedMotion ? 0 : Math.min(index, 5) * 0.025 }}
                  className={`market-lead-card${lead.isSoldOut ? ' market-lead-unavailable' : ''}`}
                >
                  <div className="market-lead-image">
                    <LoadingImage src={lead.image} alt={lead.title} loading="lazy" />
                    {lead.isSoldOut && <span className="market-lead-status">{lead.unavailableLabel}</span>}
                  </div>
                  <div className="market-lead-body">
                    <h3><button type="button" onClick={() => void handleViewDetails(lead.id)}>{lead.title}</button></h3>
                    <p className="market-lead-id">Lead ID: {lead.leadDisplayId || '—'}</p>
                    <p className="market-lead-budget">Customer Budget: {lead.budgetRange || 'Not specified'}</p>
                    <p className="market-lead-location"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="2.5"/></svg>{lead.location}</p>
                    <p className="market-lead-type">{[lead.propertyType, lead.requirement].filter(Boolean).join(' | ') || lead.clientType || 'Project enquiry'}</p>
                    <time className="market-lead-date" dateTime={lead.createdAt}>{new Date(lead.createdAt).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}</time>
                    <div className="market-lead-actions">
                      <span className="market-lead-price" aria-label={`Lead price ${lead.price} rupees`}>₹{lead.price.toLocaleString('en-IN')}</span>
                      <button type="button" className="market-lead-cart" onClick={() => void handleAddToCart(lead.id)} disabled={lead.isSoldOut || activeCartLeadId !== null || buyingLeadId !== null}>{activeCartLeadId === lead.id ? 'Adding…' : 'Add to cart'}</button>
                      <button type="button" className="market-lead-buy" onClick={() => void handleBuyNow(lead.id)} disabled={lead.isSoldOut || buyingLeadId !== null || activeCartLeadId !== null} aria-busy={buyingLeadId === lead.id}>{buyingLeadId === lead.id ? 'Buying…' : 'Buy Now'}</button>
                    </div>
                  </div>
                </motion.article>
              ))}
            </AnimatePresence>
          </div>
        )}
        {cartFeedback ? (
          <div className="pointer-events-none fixed inset-x-0 top-4 z-[100] flex justify-center px-4">
            <div role="status" aria-live="polite" className="pointer-events-auto flex w-full max-w-lg items-center justify-between gap-4 rounded-xl border border-[#0066ff]/40 bg-[#edf5ff] px-4 py-3 text-sm font-medium text-stone-700 shadow-lg">
              <p>{cartFeedback}</p>
              <button type="button" onClick={() => setCartFeedback('')} aria-label="Dismiss notification" className="shrink-0 rounded-lg px-2 py-1 font-semibold hover:bg-amber-100">Dismiss</button>
            </div>
          </div>
        ) : null}

        {hasMoreLeads && !isLeadsLoading ? (
          <div className="mt-10 flex justify-center">
            <motion.button
              type="button"
              onClick={handleLoadMore}
              disabled={isLoadingMore}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.96 }}
              className="rounded-xl bg-[#0066ff] px-8 py-3 text-lg font-bold text-white transition hover:bg-[#0050cb] disabled:cursor-not-allowed disabled:opacity-70"
            >
              {isLoadingMore ? 'Loading...' : 'Load More Leads'}
            </motion.button>
          </div>
        ) : null}
      </motion.section>
      </div>

      <motion.section
        className="mx-auto max-w-7xl px-4 pb-14 sm:px-6"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.2 }}
        variants={fadeUp}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
        <motion.div
          className="rounded-2xl border border-stone-300 bg-[#f8fafc] p-5 shadow-md sm:p-8"
          whileHover={{ y: -3 }}
          transition={{ duration: 0.2 }}
        >
          <div className="grid items-center gap-8 lg:grid-cols-2">
            <div>
              <h2 className="max-w-md text-4xl font-black leading-tight text-stone-900">
                Why Service Professionals Trust Our Network
              </h2>

              <div className="mt-6 space-y-4">
                {trustPoints.map((point, index) => (
                  <motion.div
                    key={`${point.title}-${index}`}
                    className="flex gap-4"
                    initial={{ opacity: 0, x: -16 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.35, delay: index * 0.08 }}
                  >
                    <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl border border-red-300 bg-red-100 text-red-400">
                      <svg
                        viewBox="0 0 24 24"
                        className="h-5 w-5"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                      >
                        <path d="M12 3 5 7v5c0 5 3.5 7.5 7 9 3.5-1.5 7-4 7-9V7l-7-4Z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="text-2xl font-bold text-stone-900">{point.title}</h3>
                      <p className="mt-1 text-sm text-stone-500">{point.description}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>

            <div className="overflow-hidden rounded-3xl">
              <img
                src="/trust-team.jpg"
                alt="Service professionals discussing a project"
                className="h-72 w-full object-cover"
              />
            </div>
          </div>
        </motion.div>
      </motion.section>

      <motion.a
        href={`https://wa.me/${WHATSAPP_NUMBER}?text=${WHATSAPP_MESSAGE}`}
        target="_blank"
        rel="noreferrer"
        aria-label="Chat on WhatsApp"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: [0, -2, 0] }}
        transition={{
          opacity: { duration: 0.4, ease: 'easeOut', delay: 0.2 },
          y: { duration: 2.6, repeat: Infinity, ease: 'easeInOut' },
        }}
        whileHover={{ scale: 1.06 }}
        whileTap={{ scale: 0.95 }}
        className="fixed right-4 bottom-4 z-30 inline-flex items-center gap-2 rounded-full bg-[#25D366] px-4 py-3 text-sm font-bold text-white shadow-lg transition hover:bg-[#1eb95b] sm:right-6 sm:bottom-6"
      >
        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden="true">
          <path d="M12.04 2C6.59 2 2.2 6.39 2.2 11.84c0 1.92.55 3.77 1.6 5.36L2 22l4.97-1.74a9.8 9.8 0 0 0 5.07 1.38h.01c5.44 0 9.84-4.4 9.84-9.84A9.85 9.85 0 0 0 12.04 2Zm0 17.99h-.01a8.14 8.14 0 0 1-4.16-1.14l-.3-.18-2.95 1.03.99-2.87-.2-.3a8.1 8.1 0 0 1-1.25-4.34c0-4.46 3.63-8.1 8.1-8.1a8.1 8.1 0 0 1 8.1 8.1 8.11 8.11 0 0 1-8.11 8.1Zm4.45-6.1c-.24-.12-1.44-.71-1.66-.8-.22-.08-.38-.12-.54.12-.16.24-.62.8-.76.96-.14.16-.28.18-.52.06-.24-.12-1.02-.38-1.95-1.22-.72-.64-1.2-1.43-1.34-1.67-.14-.24-.01-.37.1-.49.1-.1.24-.28.36-.42.12-.14.16-.24.24-.4.08-.16.04-.3-.02-.42-.06-.12-.54-1.3-.74-1.79-.2-.47-.4-.4-.54-.41h-.46a.9.9 0 0 0-.66.3c-.22.24-.86.84-.86 2.06 0 1.22.88 2.4 1 2.56.12.16 1.74 2.65 4.22 3.72.59.25 1.05.4 1.41.52.6.19 1.14.16 1.57.1.48-.07 1.44-.59 1.64-1.16.2-.57.2-1.06.14-1.16-.06-.1-.22-.16-.46-.28Z" />
        </svg>
        WhatsApp
      </motion.a>
    </div>
  )
}

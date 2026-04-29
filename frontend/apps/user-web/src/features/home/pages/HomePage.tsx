import { useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useSearchParams } from 'react-router-dom'

const PAGE_LIMIT = 10
const CONFIGURED_API_BASE_URL = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
const API_BASE_URL_CANDIDATES = Array.from(
  new Set(['http://localhost:5000', CONFIGURED_API_BASE_URL].filter(Boolean)),
)
type CityOption = {
  _id: string
  name: string
}

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
}

type LeadDetails = {
  _id: string
  leadDisplayId?: string
  title: string
  city?: string
  state?: string
  description?: string
  clientType?: string
  propertyType?: string
  areaSize?: string
  budgetRange?: string
  timeline?: string
  requirement?: string
  buyersCount?: number
  maxBuyers?: number
  price?: number
}

const formatBudgetValue = (value?: string) => {
  const raw = String(value ?? '').trim()
  if (!raw) return 'N/A'
  const digitsOnly = raw.replace(/[^\d]/g, '')
  if (!digitsOnly) return raw
  return `₹${Number(digitsOnly).toLocaleString('en-IN')}`
}

const formatAreaValue = (value?: string) => {
  const raw = String(value ?? '').trim()
  if (!raw) return '-'
  if (/sq\.?\s*ft|square\s*feet|sqft/i.test(raw)) return raw
  return `${raw} Sq. Ft.`
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
    remainingSlots: Math.max(0, lead.maxBuyers - lead.buyersCount),
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
    isSoldOut: lead.status === 'SOLD_OUT',
  }))

const trustPoints = [
  {
    title: 'Human- Verified Leads',
    description:
      'Every enquiry is called and verified by our team before hitting the marketplace.',
  },
  {
    title: 'Human- Verified Leads',
    description:
      'Get notified the second a high-intend lead matches your service area.',
  },
]

const WHATSAPP_NUMBER = '916205878945'
const WHATSAPP_MESSAGE = encodeURIComponent(
  'Hi, I want to know more about your interior design leads.',
)
const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0 },
}

export function HomePage() {
  const [cityLinks, setCityLinks] = useState<string[]>([])
  const firstRowCategories = cityLinks.slice(0, 6)
  const secondRowCategories = cityLinks.slice(6)
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)
  const [searchParams] = useSearchParams()
  const categoryIdParam = searchParams.get('category')
  const cityParam = searchParams.get('city')
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [selectedSort, setSelectedSort] = useState<'latest' | 'cheapest' | 'expensive'>('latest')
  const [allLeads, setAllLeads] = useState<HomeLead[]>([])
  const [isLeadsLoading, setIsLeadsLoading] = useState(false)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [activeCartLeadId, setActiveCartLeadId] = useState<string | null>(null)
  const [cartFeedback, setCartFeedback] = useState('')
  const [leadQuantities, setLeadQuantities] = useState<Record<string, number>>({})
  const [leadsError, setLeadsError] = useState('')
  const [selectedLeadDetails, setSelectedLeadDetails] = useState<LeadDetails | null>(null)
  const [isLeadDetailsLoading, setIsLeadDetailsLoading] = useState(false)
  const [pagination, setPagination] = useState<LeadsPagination>({ page: 1, totalPages: 1 })
  const selectedCity = cityParam ? cityParam.trim() : selectedCategory ? selectedCategory : ''
  const hasMoreLeads = pagination.page < pagination.totalPages
  const userToken = localStorage.getItem('user_token')

  useEffect(() => {
    const fetchCities = async () => {
      let networkError: Error | null = null
      for (const baseUrl of API_BASE_URL_CANDIDATES) {
        try {
          const response = await fetch(`${baseUrl}/api/v1/cities/get-all-cities`, { method: 'GET' })
          const payload = await response.json()
          if (!response.ok || !payload?.success) {
            throw new Error(payload?.message ?? 'Unable to fetch cities right now.')
          }
          const cityNames = Array.isArray(payload?.data)
            ? (payload.data as CityOption[]).map((item) =>
                item.name
                  .split(' ')
                  .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
                  .join(' '),
              )
            : []
          setCityLinks(cityNames)
          return
        } catch (error) {
          networkError = error instanceof Error ? error : new Error('Unable to fetch cities right now.')
        }
      }
      console.error(networkError?.message ?? 'Unable to fetch cities right now.')
      setCityLinks([])
    }

    void fetchCities()
  }, [])

  useEffect(() => {
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

          const response = await fetch(
            `${baseUrl}/api/v1/leads/get-all-leads?${params.toString()}`,
            {
            method: 'GET',
            signal: controller.signal,
            },
          )
          const payload = await response.json()
          window.clearTimeout(timeoutId)

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
  }, [appliedSearch, selectedCity, selectedSort, categoryIdParam])

  const handleLoadMore = () => {
    if (isLeadsLoading || isLoadingMore || !hasMoreLeads) return

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

          const response = await fetch(
            `${baseUrl}/api/v1/leads/get-all-leads?${params.toString()}`,
            {
            method: 'GET',
            signal: controller.signal,
            },
          )
          const payload = await response.json()
          window.clearTimeout(timeoutId)

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
          networkError =
            error instanceof Error ? error : new Error('Unable to fetch leads right now.')
        }
      }

      setLeadsError(networkError?.message ?? 'Unable to fetch leads right now.')
      setIsLoadingMore(false)
    })()
  }

  useEffect(() => {
    setLeadQuantities((prev) => {
      const next: Record<string, number> = {}
      for (const lead of allLeads) {
        const maxAllowed = Math.max(1, Math.min(3, lead.remainingSlots || 1))
        const current = prev[lead.id] ?? 1
        next[lead.id] = Math.min(Math.max(current, 1), maxAllowed)
      }
      return next
    })
  }, [allLeads])

  const handleAddToCart = async (leadId: string, quantity: number) => {
    if (!userToken) {
      setCartFeedback('Please login first to add leads in cart.')
      return
    }

    setActiveCartLeadId(leadId)
    setCartFeedback('')
    let networkError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        const response = await fetch(`${baseUrl}/api/v1/cart/add-cart`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${userToken}`,
          },
          body: JSON.stringify({ leadId, quantity }),
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

  const handleViewDetails = async (leadId: string) => {
    if (!userToken) return
    setIsLeadDetailsLoading(true)
    setLeadsError('')
    let networkError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        const response = await fetch(`${baseUrl}/api/v1/leads/get-lead/${leadId}`, {
          method: 'GET',
          headers: {
            Authorization: `Bearer ${userToken}`,
          },
        })
        const payload = await response.json()
        if (!response.ok || !payload?.success) {
          throw new Error(payload?.message ?? 'Unable to fetch lead details.')
        }
        setSelectedLeadDetails((payload?.data as LeadDetails) ?? null)
        setIsLeadDetailsLoading(false)
        return
      } catch (error) {
        networkError = error instanceof Error ? error : new Error('Unable to fetch lead details.')
      }
    }

    setLeadsError(networkError?.message ?? 'Unable to fetch lead details.')
    setIsLeadDetailsLoading(false)
  }

  return (
    <div className="bg-[#efefef]">
      <motion.section
        className="border-b border-stone-200"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.2 }}
        variants={fadeUp}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
        <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 sm:py-12">
          <motion.p
            className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white"
            variants={fadeUp}
            transition={{ duration: 0.35, delay: 0.05 }}
          >
            New Leads Available
          </motion.p>

          <motion.h1
            className="mt-3 max-w-4xl text-4xl font-black leading-[1.1] tracking-tight text-stone-900 sm:text-6xl"
            variants={fadeUp}
            transition={{ duration: 0.45, delay: 0.1 }}
          >
            Premium Interior Design
            <br />
            Leads, <span className="italic text-red-500">Verified</span> & Ready.
          </motion.h1>

          <motion.p
            className="mt-4 max-w-3xl text-sm font-medium text-stone-600 sm:text-lg"
            variants={fadeUp}
            transition={{ duration: 0.45, delay: 0.15 }}
          >
            Access high-conversion interior design opportunities curated by experts.
            Stop chasing cold prospects and start building beautiful spaced today.
          </motion.p>

          <motion.div
            className="mt-8 flex max-w-3xl flex-col gap-3 rounded-2xl border border-stone-300 bg-white p-2.5 shadow-sm sm:flex-row sm:items-center sm:gap-4"
            variants={fadeUp}
            transition={{ duration: 0.45, delay: 0.2 }}
          >
            <div className="ml-2 hidden text-stone-400 sm:block">
              <svg
                viewBox="0 0 24 24"
                className="h-5 w-5"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="11" cy="11" r="7" />
                <path d="M20 20l-3.5-3.5" />
              </svg>
            </div>
            <input
              type="text"
              placeholder="Search by BHK, Location, or project type..."
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  event.preventDefault()
                  setAppliedSearch(searchInput)
                }
              }}
              className="h-11 w-full min-w-0 flex-1 border-none bg-transparent px-2 text-sm text-stone-700 outline-none placeholder:text-stone-400 sm:px-0"
            />
            <button
              type="button"
              onClick={() => setAppliedSearch(searchInput)}
              className="h-11 w-full shrink-0 rounded-xl bg-[#F8B020] px-7 text-sm font-bold text-white transition hover:bg-[#E2A11D] sm:w-auto"
            >
              Find Leads
            </button>
          </motion.div>
          <motion.div
            className="mt-9 space-y-3.5"
            variants={fadeUp}
            transition={{ duration: 0.45, delay: 0.25 }}
          >
            <div className="flex flex-wrap items-center gap-2.5 sm:gap-3.5">
              {firstRowCategories.map((item) => (
                <motion.button
                  key={item}
                  type="button"
                  onClick={() => setSelectedCategory((prev) => (prev === item ? null : item))}
                  aria-pressed={selectedCategory === item}
                  whileHover={{ y: -2, scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  transition={{ type: 'spring', stiffness: 350, damping: 24 }}
                  className={`rounded-xl border px-3 py-2 text-xs font-semibold transition sm:px-4 sm:text-sm ${
                    item === selectedCategory
                      ? 'border-[#F8B020] bg-[#F8B020] text-white'
                      : 'border-[#F8B020] bg-white text-stone-500 hover:bg-[#FFF7E8]'
                  }`}
                >
                  {item}
                </motion.button>
              ))}
            </div>
            <div className="flex flex-wrap items-center gap-2.5 sm:gap-3.5">
              {secondRowCategories.map((item) => (
                <motion.button
                  key={item}
                  type="button"
                  onClick={() => setSelectedCategory((prev) => (prev === item ? null : item))}
                  aria-pressed={selectedCategory === item}
                  whileHover={{ y: -2, scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  transition={{ type: 'spring', stiffness: 350, damping: 24 }}
                  className={`rounded-xl border px-3 py-2 text-xs font-semibold transition sm:px-4 sm:text-sm ${
                    item === selectedCategory
                      ? 'border-[#F8B020] bg-[#F8B020] text-white'
                      : 'border-[#F8B020] bg-white text-stone-500 hover:bg-[#FFF7E8]'
                  }`}
                >
                  {item}
                </motion.button>
              ))}
            </div>
          </motion.div>
        </div>
      </motion.section>

      <motion.section
        className="mx-auto max-w-7xl px-4 py-12 sm:px-6"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.2 }}
        variants={fadeUp}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
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
        {isLeadsLoading ? (
          <p className="mt-7 text-sm font-semibold text-stone-600">Loading leads...</p>
        ) : leadsError ? (
          <p className="mt-7 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {leadsError}
          </p>
        ) : allLeads.length === 0 ? (
          <p className="mt-7 rounded-xl border border-stone-200 bg-white px-4 py-3 text-sm text-stone-600">
            No leads available right now.
          </p>
        ) : (
          <div className="mt-7 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            <AnimatePresence mode="popLayout">
              {allLeads.map((lead, index) => (
                <motion.article
                  key={lead.id}
                  layout
                  initial={{ opacity: 0, y: 24 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 12 }}
                  transition={{ duration: 0.35, delay: index * 0.03 }}
                  whileHover={{ y: -6, boxShadow: '0 14px 26px rgba(0,0,0,0.10)' }}
                  className={`relative overflow-hidden rounded-2xl border border-stone-300 shadow-sm ${
                    lead.isSoldOut ? 'bg-stone-200' : 'bg-[#efefef]'
                  }`}
                >
                  <div className="relative">
                    <img
                      src={lead.image}
                      alt={lead.title}
                      className={`h-44 w-full rounded-t-2xl object-cover ${
                        lead.isSoldOut ? 'grayscale-[35%] brightness-90' : ''
                      }`}
                    />
                    {lead.isSoldOut ? (
                      <div className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center">
                        <img
                          src="/sold-out-stamp.png"
                          alt="Sold Out"
                          className="h-20 w-20 object-contain sm:h-24 sm:w-24"
                        />
                      </div>
                    ) : null}
                  </div>
                  <div className="space-y-2.5 p-3">
                    <h3 className="text-[22px] leading-tight font-extrabold text-stone-900">
                      {lead.title}
                    </h3>
                    <p className="text-[11px] font-semibold tracking-wide text-stone-500">
                      Lead ID: {lead.leadDisplayId || '-'}
                    </p>
                    <p className="text-xs font-semibold text-indigo-700">
                      Budget Range: {lead.budgetRange || 'N/A'}
                    </p>
                    <p className="text-xs leading-relaxed text-stone-600">
                      {lead.location}
                      <br />
                      {lead.sharing}
                    </p>
                    <div className="flex items-center justify-between gap-3">
                      <p className="text-sm font-bold text-green-600">
                        {lead.oldPrice > lead.price ? (
                          <span className="mr-1 text-red-500 line-through">₹{lead.oldPrice.toFixed(2)}</span>
                        ) : null}
                        ₹{lead.price}/-
                      </p>
                      <div className="flex items-center gap-2">
                        <div className="inline-flex items-center rounded-full border border-stone-300 bg-white">
                          <button
                            type="button"
                            onClick={() =>
                              setLeadQuantities((prev) => ({
                                ...prev,
                                [lead.id]: Math.max(1, (prev[lead.id] ?? 1) - 1),
                              }))
                            }
                            className="h-8 w-8 rounded-l-full text-base font-bold text-stone-700 hover:bg-stone-100 disabled:cursor-not-allowed disabled:opacity-40"
                            disabled={lead.isSoldOut || (leadQuantities[lead.id] ?? 1) <= 1}
                            aria-label="Decrease quantity"
                          >
                            -
                          </button>
                          <span className="min-w-7 text-center text-sm font-semibold text-stone-800">
                            {leadQuantities[lead.id] ?? 1}
                          </span>
                          <button
                            type="button"
                            onClick={() =>
                              setLeadQuantities((prev) => ({
                                ...prev,
                                [lead.id]: Math.min(
                                  Math.max(1, Math.min(3, lead.remainingSlots || 1)),
                                  (prev[lead.id] ?? 1) + 1,
                                ),
                              }))
                            }
                            className="h-8 w-8 rounded-r-full text-base font-bold text-stone-700 hover:bg-stone-100 disabled:cursor-not-allowed disabled:opacity-40"
                            disabled={
                              lead.isSoldOut ||
                              (leadQuantities[lead.id] ?? 1) >=
                                Math.max(1, Math.min(3, lead.remainingSlots || 1))
                            }
                            aria-label="Increase quantity"
                          >
                            +
                          </button>
                        </div>
                        <motion.button
                          type="button"
                          onClick={() => {
                            void handleAddToCart(lead.id, leadQuantities[lead.id] ?? 1)
                          }}
                          whileHover={{ scale: 1.04 }}
                          whileTap={{ scale: 0.97 }}
                          className={`rounded-lg px-3 py-1.5 text-xs font-semibold text-white transition ${
                            lead.isSoldOut
                              ? 'cursor-not-allowed bg-stone-400'
                              : 'bg-green-500 hover:bg-green-600'
                          }`}
                          disabled={lead.isSoldOut || activeCartLeadId === lead.id}
                        >
                          {lead.isSoldOut
                            ? 'Sold Out'
                            : activeCartLeadId === lead.id
                              ? 'Adding...'
                              : 'Add'}
                        </motion.button>
                        {userToken ? (
                          <button
                            type="button"
                            onClick={() => void handleViewDetails(lead.id)}
                            className="rounded-lg border border-[#4B2CF5] bg-white px-3 py-1.5 text-xs font-semibold text-[#4B2CF5] transition hover:bg-[#F3EEFF]"
                          >
                            View Details
                          </button>
                        ) : null}
                      </div>
                    </div>
                    <p className="text-xs text-stone-400">{new Date(lead.createdAt).toLocaleDateString()}</p>
                  </div>
                </motion.article>
              ))}
            </AnimatePresence>
          </div>
        )}
        {cartFeedback ? (
          <p className="mt-4 rounded-xl border border-[#F8B020]/40 bg-[#FFF7E8] px-4 py-2 text-sm font-medium text-stone-700">
            {cartFeedback}
          </p>
        ) : null}

        {hasMoreLeads && !isLeadsLoading ? (
          <div className="mt-10 flex justify-center">
            <motion.button
              type="button"
              onClick={handleLoadMore}
              disabled={isLoadingMore}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.96 }}
              className="rounded-xl bg-[#F8B020] px-8 py-3 text-lg font-bold text-white transition hover:bg-[#E2A11D] disabled:cursor-not-allowed disabled:opacity-70"
            >
              {isLoadingMore ? 'Loading...' : 'Load More Leads'}
            </motion.button>
          </div>
        ) : null}
      </motion.section>

      {userToken && (selectedLeadDetails || isLeadDetailsLoading) ? (
        <div
          className="fixed inset-0 z-40 bg-black/45 p-4"
          onClick={() => setSelectedLeadDetails(null)}
        >
          <div
            className="mx-auto mt-5 w-full max-w-md overflow-hidden rounded-2xl border border-indigo-200 bg-white shadow-2xl"
            onClick={(event) => event.stopPropagation()}
          >
            {isLeadDetailsLoading ? (
              <div className="p-6 text-sm font-semibold text-stone-600">Loading details...</div>
            ) : selectedLeadDetails ? (
              <>
                <div className="bg-gradient-to-r from-indigo-800 to-violet-700 px-4 py-3 text-white">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-sm font-bold">{selectedLeadDetails.title}</p>
                      <p className="mt-0.5 text-[11px] opacity-90">
                        {selectedLeadDetails.city || '-'}
                        {selectedLeadDetails.state ? `, ${selectedLeadDetails.state}` : ''}
                      </p>
                    </div>
                    <span className="rounded-md border border-white/40 bg-white/15 px-2 py-1 text-[10px] font-semibold">
                      {selectedLeadDetails.buyersCount ?? 0}/{selectedLeadDetails.maxBuyers ?? 0} Vendors
                    </span>
                  </div>
                </div>

                <div className="space-y-3 p-4">
                  <div className="rounded-xl border border-indigo-100 bg-indigo-50 px-3 py-2">
                    <p className="text-[11px] font-semibold text-indigo-700">Project Budget</p>
                    <p className="text-xl font-black text-indigo-900">
                      {formatBudgetValue(selectedLeadDetails.budgetRange)}
                    </p>
                    <p className="text-[11px] text-indigo-600">
                      Lead ID:{' '}
                      {selectedLeadDetails.leadDisplayId ||
                        `NL${String(selectedLeadDetails._id || '')
                          .slice(-8)
                          .toUpperCase()}`}
                    </p>
                  </div>

                  <div className="rounded-xl border border-stone-200 bg-white text-[12px] text-stone-700">
                    <div className="flex items-center justify-between border-b border-stone-100 px-3 py-2">
                      <span>Client Type</span>
                      <span className="font-semibold">{selectedLeadDetails.clientType || '-'}</span>
                    </div>
                    <div className="flex items-center justify-between border-b border-stone-100 px-3 py-2">
                      <span>Property Type</span>
                      <span className="font-semibold">{selectedLeadDetails.propertyType || '-'}</span>
                    </div>
                    <div className="flex items-center justify-between border-b border-stone-100 px-3 py-2">
                      <span>Area (Sq. Ft.)</span>
                      <span className="font-semibold">{formatAreaValue(selectedLeadDetails.areaSize)}</span>
                    </div>
                    <div className="flex items-center justify-between border-b border-stone-100 px-3 py-2">
                      <span>Project Timeline</span>
                      <span className="font-semibold">{selectedLeadDetails.timeline || '-'}</span>
                    </div>
                    <div className="flex items-center justify-between px-3 py-2">
                      <span>Budget Range</span>
                      <span className="font-semibold">{formatBudgetValue(selectedLeadDetails.budgetRange)}</span>
                    </div>
                  </div>

                  <div className="rounded-xl border border-stone-200 bg-stone-50 px-3 py-2">
                    <p className="text-[11px] font-semibold text-stone-600">Project Requirements</p>
                    <p className="mt-1 text-xs text-stone-700">
                      {selectedLeadDetails.requirement || selectedLeadDetails.description || '-'}
                    </p>
                  </div>

                  <button
                    type="button"
                    onClick={() => setSelectedLeadDetails(null)}
                    className="w-full rounded-xl bg-indigo-700 py-2.5 text-sm font-bold text-white hover:bg-indigo-800"
                  >
                    Close Details
                  </button>
                </div>
              </>
            ) : null}
          </div>
        </div>
      ) : null}

      <motion.section
        className="mx-auto max-w-7xl px-4 pb-14 sm:px-6"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.2 }}
        variants={fadeUp}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
        <motion.div
          className="rounded-2xl border border-stone-300 bg-[#efefef] p-5 shadow-md sm:p-8"
          whileHover={{ y: -3 }}
          transition={{ duration: 0.2 }}
        >
          <div className="grid items-center gap-8 lg:grid-cols-2">
            <div>
              <h2 className="max-w-md text-4xl font-black leading-tight text-stone-900">
                Why Interior Designers Trust Our Network
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
                alt="Interior designers discussing project"
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

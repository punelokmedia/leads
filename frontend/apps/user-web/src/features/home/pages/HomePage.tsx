import { useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'

const PAGE_LIMIT = 10
const CONFIGURED_API_BASE_URL = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
const API_BASE_URL_CANDIDATES = Array.from(
  new Set(['http://localhost:5000', CONFIGURED_API_BASE_URL].filter(Boolean)),
)
const CATEGORY_CITY_MAP: Record<string, string> = {
  'Bengaluru Leads': 'Bangalore',
  'Mumbai/Thane/Navi Leads': 'Mumbai',
  'Pune Leads': 'Pune',
  'Delhi/NCR': 'Delhi',
  Kolkata: 'Kolkata',
  'Hyderabad/Secunderabad': 'Hyderabad',
  'Chennai Leads': 'Chennai',
  Lucknow: 'Lucknow',
  Ahmedabad: 'Ahmedabad',
  Nagpur: 'Nagpur',
  Jaipur: 'Jaipur',
  Surat: 'Surat',
}

type LeadsApiItem = {
  _id: string
  title: string
  city: string
  state: string
  description?: string
  price: number
  originalPrice?: number | null
  buyersCount: number
  maxBuyers: number
  createdAt: string
  status: 'ACTIVE' | 'SOLD_OUT' | 'EXPIRED' | string
}

type HomeLead = {
  id: string
  title: string
  image: string
  location: string
  sharing: string
  oldPrice: number
  price: number
  createdAt: string
  isSoldOut: boolean
}

type LeadsPagination = {
  page: number
  totalPages: number
}

const mapLeadsForCards = (items: LeadsApiItem[], startIndex: number): HomeLead[] =>
  items.map((lead, index) => ({
    id: lead._id,
    title: lead.title,
    image: `/lead-room-${((startIndex + index) % 3) + 1}.jpg`,
    location: `${lead.city}, ${lead.state}`,
    sharing: `Sharing Leads (${lead.buyersCount}/${lead.maxBuyers})`,
    oldPrice:
      typeof lead.originalPrice === 'number' && lead.originalPrice > lead.price
        ? lead.originalPrice
        : lead.price,
    price: lead.price,
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
  const categoryLinks = [
    'Instagram Reels',
    'Bengaluru Leads',
    'Mumbai/Thane/Navi Leads',
    'Pune Leads',
    'Delhi/NCR',
    'Kolkata',
    'Hyderabad/Secunderabad',
    'Chennai Leads',
    'Lucknow',
    'Ahmedabad',
    'Nagpur',
    'Jaipur',
    'Surat',
  ]
  const firstRowCategories = categoryLinks.slice(0, 6)
  const secondRowCategories = categoryLinks.slice(6)
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [selectedSort, setSelectedSort] = useState<'latest' | 'cheapest' | 'expensive'>('latest')
  const [allLeads, setAllLeads] = useState<HomeLead[]>([])
  const [isLeadsLoading, setIsLeadsLoading] = useState(false)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [leadsError, setLeadsError] = useState('')
  const [pagination, setPagination] = useState<LeadsPagination>({ page: 1, totalPages: 1 })
  const selectedCity = selectedCategory ? CATEGORY_CITY_MAP[selectedCategory] ?? '' : ''
  const hasMoreLeads = pagination.page < pagination.totalPages

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

          const response = await fetch(`${baseUrl}/api/v1/leads?${params.toString()}`, {
            method: 'GET',
            signal: controller.signal,
          })
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
  }, [appliedSearch, selectedCity, selectedSort])

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

          const response = await fetch(`${baseUrl}/api/v1/leads?${params.toString()}`, {
            method: 'GET',
            signal: controller.signal,
          })
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
                  className="relative overflow-hidden rounded-2xl border border-stone-300 bg-[#efefef] shadow-sm"
                >
                  {lead.isSoldOut ? (
                    <div className="pointer-events-none absolute top-4 -right-10 z-10 rotate-[35deg] border-2 border-red-700 bg-red-600/95 px-10 py-1 text-sm font-extrabold tracking-widest text-white shadow-lg">
                      SOLD OUT
                    </div>
                  ) : null}
                  <img
                    src={lead.image}
                    alt={lead.title}
                    className="h-44 w-full rounded-t-2xl object-cover"
                  />
                  <div className="space-y-2.5 p-3">
                    <h3 className="text-[22px] leading-tight font-extrabold text-stone-900">
                      {lead.title}
                    </h3>
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
                      <motion.button
                        type="button"
                        whileHover={{ scale: 1.04 }}
                        whileTap={{ scale: 0.97 }}
                        className={`rounded-lg px-4 py-1.5 text-xs font-semibold text-white transition ${
                          lead.isSoldOut
                            ? 'cursor-not-allowed bg-stone-400'
                            : 'bg-green-500 hover:bg-green-600'
                        }`}
                        disabled={lead.isSoldOut}
                      >
                        {lead.isSoldOut ? 'Sold Out' : 'Add to Cart'}
                      </motion.button>
                    </div>
                    <p className="text-xs text-stone-400">{new Date(lead.createdAt).toLocaleDateString()}</p>
                  </div>
                </motion.article>
              ))}
            </AnimatePresence>
          </div>
        )}

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

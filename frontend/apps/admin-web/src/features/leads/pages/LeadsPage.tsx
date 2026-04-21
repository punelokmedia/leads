import { useCallback, useEffect, useMemo, useState, type DragEvent, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type LeadCategory = string | { _id: string; name?: string }

type Category = {
  _id: string
  name: string
}

type LeadMeta = {
  total: number
  page: number
  limit: number
  totalPages: number
}

type LeadLocation = {
  type?: string
  coordinates?: number[]
}

type LeadBudget = {
  min?: number
  max?: number
}

type LeadUserRef = {
  _id?: string
  firstname?: string
  email?: string
}

type LeadPurchase = {
  _id?: string
  quantity?: number
  purchasedAt?: string
  user?: LeadUserRef
}

type Lead = {
  _id: string
  title: string
  description?: string
  city?: string
  state?: string
  address?: string
  price?: number
  originalPrice?: number
  status?: string
  expiresAt?: string
  category?: LeadCategory
  location?: LeadLocation
  budget?: LeadBudget
  customerName?: string
  phone?: string
  buyersCount?: number
  maxBuyers?: number
  remainingSlots?: number
  isSoldOut?: boolean
  totalSold?: number
  purchases?: LeadPurchase[]
  createdBy?: LeadUserRef
  createdAt?: string
  updatedAt?: string
}

type LeadDetails = Lead

type LeadFormState = {
  title: string
  description: string
  category: string
  city: string
  state: string
  address: string
  price: string
  originalPrice: string
  expiresAt: string
  latitude: string
  longitude: string
}

type UploadStatus = {
  uploadId: string
  status: string
  progress: string
  processed: number
  total: number
  success: number
  failed: number
  message: string
  logs: Array<{ row?: number; message?: string; _id?: string }>
}

const initialLeadForm: LeadFormState = {
  title: '',
  description: '',
  category: '',
  city: '',
  state: '',
  address: '',
  price: '',
  originalPrice: '',
  expiresAt: '',
  latitude: '',
  longitude: '',
}

function getToken() {
  if (typeof window === 'undefined') return ''
  const raw = window.localStorage.getItem(AUTH_STORAGE_KEY)
  if (!raw) return ''
  try {
    const parsed = JSON.parse(raw) as { token?: string }
    return parsed.token ?? ''
  } catch {
    return ''
  }
}

function getCategoryName(category: LeadCategory | undefined) {
  if (!category) return '-'
  if (typeof category === 'string') return category
  return category.name || '-'
}

function getStatusClasses(status?: string) {
  if (status === 'ACTIVE') return 'bg-emerald-50 text-emerald-700 border-emerald-200'
  if (status === 'SOLD_OUT') return 'bg-amber-50 text-amber-700 border-amber-200'
  if (status === 'EXPIRED') return 'bg-rose-50 text-rose-700 border-rose-200'
  return 'bg-slate-100 text-slate-700 border-slate-200'
}

function formatAmount(amount?: number) {
  if (typeof amount !== 'number' || Number.isNaN(amount)) return '-'
  return `₹${amount.toLocaleString('en-IN')}`
}

function formatDateTime(value?: string) {
  if (!value) return '-'
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return '-'
  return parsed.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function toDateTimeLocal(value?: string) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const tzOffset = date.getTimezoneOffset() * 60000
  return new Date(date.getTime() - tzOffset).toISOString().slice(0, 16)
}

function getCategoryId(category: LeadCategory | undefined) {
  if (!category) return ''
  if (typeof category === 'string') return category
  return category._id
}

export function LeadsPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [token, setToken] = useState('')
  const [leads, setLeads] = useState<Lead[]>([])
  const [loadingLeads, setLoadingLeads] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [successMessage, setSuccessMessage] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<
    'all' | 'ACTIVE' | 'SOLD_OUT' | 'EXPIRED'
  >('all')
  const [leadMeta, setLeadMeta] = useState<LeadMeta>({
    total: 0,
    page: 1,
    limit: 10,
    totalPages: 1,
  })
  const [categories, setCategories] = useState<Category[]>([])
  const [loadingCategories, setLoadingCategories] = useState(false)
  const [isCreateDrawerOpen, setIsCreateDrawerOpen] = useState(false)
  const [isUploadDrawerOpen, setIsUploadDrawerOpen] = useState(false)
  const [editingLeadId, setEditingLeadId] = useState('')
  const [submittingLead, setSubmittingLead] = useState(false)
  const [leadForm, setLeadForm] = useState<LeadFormState>(initialLeadForm)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [isDragActive, setIsDragActive] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [uploadStatus, setUploadStatus] = useState<UploadStatus | null>(null)
  const [selectedLeadDetails, setSelectedLeadDetails] = useState<LeadDetails | null>(null)
  const [loadingLeadDetails, setLoadingLeadDetails] = useState(false)
  const hasAuth = Boolean(token)

  const handleApiError = useCallback((message: string) => {
    setSuccessMessage('')
    setErrorMessage(message)
  }, [])

  const clearMessages = useCallback(() => {
    setErrorMessage('')
    setSuccessMessage('')
  }, [])

  const fetchWithAuth = useCallback(
    async (url: string, init?: RequestInit) => {
      const response = await fetch(url, {
        ...init,
        headers: {
          ...(init?.headers ?? {}),
          Authorization: `Bearer ${token}`,
        },
      })
      let payload: Record<string, unknown> = {}
      try {
        payload = (await response.json()) as Record<string, unknown>
      } catch {
        payload = {}
      }

      if (!response.ok || payload.success === false) {
        throw new Error((payload.message as string) || 'Request failed')
      }

      return payload
    },
    [token],
  )

  const loadLeads = useCallback(async () => {
    if (!token) return
    setLoadingLeads(true)
    try {
      const payload = await fetchWithAuth(
        `${API_BASE_URL}/api/v1/admin/dashboard/get-all-leads?page=${leadMeta.page}&limit=${leadMeta.limit}`,
      )
      setLeads((payload.data as Lead[]) ?? [])
      const meta = (payload.meta as Partial<LeadMeta>) ?? {}
      setLeadMeta((previous) => ({
        total: typeof meta.total === 'number' ? meta.total : previous.total,
        page: typeof meta.page === 'number' ? meta.page : previous.page,
        limit: typeof meta.limit === 'number' ? meta.limit : previous.limit,
        totalPages:
          typeof meta.totalPages === 'number' && meta.totalPages > 0
            ? meta.totalPages
            : previous.totalPages,
      }))
    } catch (error) {
      handleApiError(error instanceof Error ? error.message : 'Failed to fetch leads')
    } finally {
      setLoadingLeads(false)
    }
  }, [fetchWithAuth, handleApiError, leadMeta.limit, leadMeta.page, token])

  const loadCategories = useCallback(async () => {
    if (!token) return
    setLoadingCategories(true)
    try {
      const payload = await fetchWithAuth(`${API_BASE_URL}/api/v1/categories/get-all-categories`)
      setCategories((payload.data as Category[]) ?? [])
    } catch (error) {
      handleApiError(error instanceof Error ? error.message : 'Failed to fetch categories')
    } finally {
      setLoadingCategories(false)
    }
  }, [fetchWithAuth, handleApiError, token])

  useEffect(() => {
    setToken(getToken())
  }, [])

  useEffect(() => {
    if (!token) return
    void loadLeads()
  }, [loadLeads, token])

  useEffect(() => {
    if (!token) return
    void loadCategories()
  }, [loadCategories, token])

  const filteredLeads = useMemo(() => {
    const query = searchQuery.trim().toLowerCase()
    return leads.filter((lead) => {
      const matchesStatus = statusFilter === 'all' || lead.status === statusFilter
      const haystack = `${lead.title ?? ''} ${lead.description ?? ''} ${lead.city ?? ''} ${
        lead.state ?? ''
      } ${getCategoryName(lead.category)}`.toLowerCase()
      const matchesSearch = !query || haystack.includes(query)
      return matchesStatus && matchesSearch
    })
  }, [leads, searchQuery, statusFilter])

  const leadSummary = useMemo(() => {
    const active = leads.filter((lead) => lead.status === 'ACTIVE').length
    const sold = leads.filter((lead) => lead.status === 'SOLD_OUT').length
    const expired = leads.filter((lead) => lead.status === 'EXPIRED').length
    return {
      total: leadMeta.total || leads.length,
      active,
      sold,
      expired,
    }
  }, [leadMeta.total, leads])

  const sortedCategories = useMemo(
    () => [...categories].sort((a, b) => a.name.localeCompare(b.name)),
    [categories],
  )

  function openCreateDrawer() {
    clearMessages()
    setIsUploadDrawerOpen(false)
    setEditingLeadId('')
    setLeadForm(initialLeadForm)
    setIsCreateDrawerOpen(true)
    const nextParams = new URLSearchParams(searchParams)
    nextParams.set('create', '1')
    nextParams.delete('upload')
    setSearchParams(nextParams, { replace: true })
  }

  function openEditDrawer(lead: Lead) {
    clearMessages()
    const coordinates = lead.location?.coordinates ?? []
    setEditingLeadId(lead._id)
    setLeadForm({
      title: lead.title ?? '',
      description: lead.description ?? '',
      category: getCategoryId(lead.category),
      city: lead.city ?? '',
      state: lead.state ?? '',
      address: lead.address ?? '',
      price: typeof lead.price === 'number' ? String(lead.price) : '',
      originalPrice: typeof lead.originalPrice === 'number' ? String(lead.originalPrice) : '',
      expiresAt: toDateTimeLocal(lead.expiresAt),
      latitude: coordinates[1] ? String(coordinates[1]) : '',
      longitude: coordinates[0] ? String(coordinates[0]) : '',
    })
    setIsCreateDrawerOpen(true)
  }

  function closeCreateDrawer() {
    setIsCreateDrawerOpen(false)
    if (searchParams.has('create')) {
      const nextParams = new URLSearchParams(searchParams)
      nextParams.delete('create')
      setSearchParams(nextParams, { replace: true })
    }
  }

  function openUploadDrawer() {
    clearMessages()
    setIsCreateDrawerOpen(false)
    setSelectedFile(null)
    setIsUploadDrawerOpen(true)
    const nextParams = new URLSearchParams(searchParams)
    nextParams.set('upload', '1')
    nextParams.delete('create')
    setSearchParams(nextParams, { replace: true })
  }

  function closeUploadDrawer() {
    setIsUploadDrawerOpen(false)
    if (searchParams.has('upload')) {
      const nextParams = new URLSearchParams(searchParams)
      nextParams.delete('upload')
      setSearchParams(nextParams, { replace: true })
    }
  }

  async function handleCreateLeadSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const latitude = Number(leadForm.latitude)
    const longitude = Number(leadForm.longitude)
    const price = Number(leadForm.price)
    const originalPrice = leadForm.originalPrice ? Number(leadForm.originalPrice) : undefined
    const expiresAtIso = leadForm.expiresAt ? new Date(leadForm.expiresAt).toISOString() : ''

    if (
      !leadForm.title ||
      !leadForm.description ||
      !leadForm.category ||
      !leadForm.city ||
      !leadForm.state ||
      !leadForm.price ||
      !leadForm.expiresAt
    ) {
      handleApiError('Please fill all required lead fields')
      return
    }

    if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
      handleApiError('Latitude and longitude are required')
      return
    }

    clearMessages()
    setSubmittingLead(true)
    try {
      if (editingLeadId) {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/leads/update-lead/${editingLeadId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: leadForm.title.trim(),
            description: leadForm.description.trim(),
            category: leadForm.category,
            city: leadForm.city.trim(),
            state: leadForm.state.trim(),
            address: leadForm.address.trim(),
            price,
            originalPrice,
            expiresAt: expiresAtIso,
            location: {
              type: 'Point',
              coordinates: [longitude, latitude],
            },
          }),
        })
      } else {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/leads/create-lead`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: leadForm.title.trim(),
            description: leadForm.description.trim(),
            category: leadForm.category,
            city: leadForm.city.trim(),
            state: leadForm.state.trim(),
            address: leadForm.address.trim(),
            price,
            originalPrice,
            expiresAt: expiresAtIso,
            coordinates: [longitude, latitude],
          }),
        })
      }

      setSuccessMessage(editingLeadId ? 'Lead updated successfully' : 'Lead created successfully')
      setEditingLeadId('')
      setLeadForm(initialLeadForm)
      closeCreateDrawer()
      await loadLeads()
    } catch (error) {
      handleApiError(
        error instanceof Error
          ? error.message
          : editingLeadId
            ? 'Failed to update lead'
            : 'Failed to create lead',
      )
    } finally {
      setSubmittingLead(false)
    }
  }

  async function handleDeleteLead(leadId: string) {
    if (!window.confirm('Delete this lead?')) return
    clearMessages()
    try {
      await fetchWithAuth(`${API_BASE_URL}/api/v1/leads/delete-lead`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ leadId }),
      })
      setSuccessMessage('Lead deleted successfully')
      await loadLeads()
    } catch (error) {
      handleApiError(error instanceof Error ? error.message : 'Failed to delete lead')
    }
  }

  async function handleViewLeadDetails(leadId: string) {
    clearMessages()
    setLoadingLeadDetails(true)
    try {
      const payload = await fetchWithAuth(
        `${API_BASE_URL}/api/v1/admin/dashboard/get-leads/${leadId}`,
      )
      setSelectedLeadDetails((payload.data as LeadDetails) ?? null)
    } catch (error) {
      handleApiError(
        error instanceof Error ? error.message : 'Failed to fetch lead details',
      )
    } finally {
      setLoadingLeadDetails(false)
    }
  }

  function isValidExcelFile(file: File) {
    const fileName = file.name.toLowerCase()
    return fileName.endsWith('.xlsx')
  }

  function parseUploadStatus(
    payload: Record<string, unknown>,
    fallbackUploadId: string,
    fallbackTotal = 0,
  ): UploadStatus {
    const successRaw = payload.success
    const parsedSuccess =
      typeof successRaw === 'number'
        ? successRaw
        : typeof payload.successCount === 'number'
          ? Number(payload.successCount)
          : 0

    const logs = Array.isArray(payload.logs)
      ? (payload.logs as Array<{ row?: number; message?: string; _id?: string }>)
      : []

    return {
      uploadId: String(payload.uploadId ?? fallbackUploadId),
      status: String(payload.status ?? 'processing'),
      progress: String(payload.progress ?? '0%'),
      processed: Number(payload.processed ?? 0),
      total: Number(payload.total ?? fallbackTotal),
      success: parsedSuccess,
      failed: Number(payload.failed ?? 0),
      message: String(payload.message ?? ''),
      logs,
    }
  }

  async function startUpload(file: File) {
    if (!isValidExcelFile(file)) {
      handleApiError('Only .xlsx files are allowed')
      return
    }

    clearMessages()
    setUploading(true)
    try {
      const formData = new FormData()
      formData.append('file', file)

      const response = await fetch(`${API_BASE_URL}/api/v1/leads/upload-leads`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData,
      })

      const payload = (await response.json()) as Record<string, unknown>
      if (!response.ok || payload.success === false) {
        throw new Error((payload.message as string) || 'Upload failed')
      }

      const uploadId = String(payload.uploadId ?? '')
      setUploadStatus({
        uploadId,
        status: 'processing',
        progress: '0%',
        processed: 0,
        total: Number(payload.totalRows ?? 0),
        success: 0,
        failed: 0,
        message: String(payload.message ?? 'Upload started'),
        logs: [],
      })
      setSuccessMessage('Upload started. Please wait for processing to complete.')
      setSelectedFile(null)
    } catch (error) {
      setUploading(false)
      handleApiError(error instanceof Error ? error.message : 'Failed to upload leads')
    }
  }

  async function handleUploadLeads(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!selectedFile) {
      handleApiError('Please choose an Excel file (.xlsx)')
      return
    }
    await startUpload(selectedFile)
  }

  function handleDragOver(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    setIsDragActive(true)
  }

  function handleDragLeave(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    setIsDragActive(false)
  }

  function handleDrop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    setIsDragActive(false)
    const droppedFile = event.dataTransfer.files?.[0]
    if (!droppedFile) return
    if (!isValidExcelFile(droppedFile)) {
      handleApiError('Only .xlsx files are allowed')
      return
    }
    clearMessages()
    setSelectedFile(droppedFile)
  }

  const uploadPercent = useMemo(() => {
    const raw = uploadStatus?.progress ?? '0%'
    const parsed = Number.parseFloat(raw)
    if (Number.isNaN(parsed)) return 0
    return Math.max(0, Math.min(100, parsed))
  }, [uploadStatus])

  useEffect(() => {
    if (searchParams.get('create') === '1') {
      setEditingLeadId('')
      setLeadForm(initialLeadForm)
      setIsCreateDrawerOpen(true)
    }
    if (searchParams.get('upload') === '1') {
      setIsUploadDrawerOpen(true)
    }
  }, [searchParams])

  useEffect(() => {
    if (!uploadStatus?.uploadId || uploadStatus.status === 'completed') {
      return
    }

    const timer = window.setInterval(async () => {
      try {
        const response = await fetch(
          `${API_BASE_URL}/api/v1/leads/upload-status/${uploadStatus.uploadId}`,
        )
        const payload = (await response.json()) as Record<string, unknown>
        if (!response.ok || payload.success === false) return
        const next = parseUploadStatus(payload, uploadStatus.uploadId, uploadStatus.total)
        setUploadStatus(next)

        if (next.status === 'completed') {
          setUploading(false)
          if (next.failed > 0) {
            setErrorMessage(next.message || `Upload completed with ${next.failed} failed rows.`)
          } else {
            setSuccessMessage(next.message || 'Upload completed successfully')
          }
          void loadLeads()
        }
      } catch {
        // silent polling retry
      }
    }, 2500)

    return () => window.clearInterval(timer)
  }, [loadLeads, uploadStatus])

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
              Leads Workspace
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Search, monitor, and manage your leads from one clean screen.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={openCreateDrawer}
              className="rounded-lg bg-violet-600 px-3 py-2 text-xs font-medium text-white hover:bg-violet-500"
            >
              + Create Lead
            </button>
            <button
              type="button"
              onClick={openUploadDrawer}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100"
            >
              Bulk Upload
            </button>
            <Link
              to="/categories"
              className="rounded-lg border border-violet-300 bg-violet-50 px-3 py-2 text-xs font-medium text-violet-700 hover:bg-violet-100"
            >
              Manage Categories
            </Link>
          </div>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ['Total leads', String(leadSummary.total), 'text-slate-900', 'TL'],
          ['Active', String(leadSummary.active), 'text-emerald-700', 'AC'],
          ['Sold out', String(leadSummary.sold), 'text-amber-700', 'SO'],
          ['Expired', String(leadSummary.expired), 'text-rose-700', 'EX'],
        ].map(([label, value, valueClass, short]) => (
          <div
            key={label}
            className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs uppercase tracking-wide text-slate-500">{label}</p>
              <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-slate-100 text-[10px] font-semibold text-slate-600">
                {short}
              </span>
            </div>
            <p className={`mt-1 text-2xl font-semibold ${valueClass}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-5 md:grid-cols-2">
        <section className="rounded-2xl border border-slate-200 bg-gradient-to-br from-white to-violet-50/30 p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-base font-semibold text-slate-900">Lead Forms</h2>
              <p className="mt-1 text-xs leading-5 text-slate-600">
                Quickly create from side drawer, or open full lead page for upload and edit tools.
              </p>
            </div>
            <span className="rounded-full bg-violet-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-violet-700">
              Lead tools
            </span>
          </div>
          <div className="mt-4 flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={openCreateDrawer}
              className="rounded-xl bg-violet-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-500"
            >
              Open side create form
            </button>
            <button
              type="button"
              onClick={openUploadDrawer}
              className="rounded-xl border border-violet-200 bg-violet-50 px-3.5 py-2 text-xs font-semibold text-violet-700 transition hover:bg-violet-100"
            >
              Open bulk upload
            </button>
            <Link
              to="/leads/create"
              className="rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
            >
              Open full lead page
            </Link>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              create-lead
            </span>
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              update-lead
            </span>
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              upload-leads
            </span>
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-gradient-to-br from-white to-indigo-50/30 p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-base font-semibold text-slate-900">Category Forms</h2>
              <p className="mt-1 text-xs leading-5 text-slate-600">
                Manage category create, update and delete flow from dedicated category page.
              </p>
            </div>
            <span className="rounded-full bg-indigo-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-indigo-700">
              Category
            </span>
          </div>
          <div className="mt-4 flex flex-wrap items-center gap-2">
            <Link
              to="/categories"
              className="rounded-xl border border-indigo-200 bg-indigo-50 px-3.5 py-2 text-xs font-semibold text-indigo-700 transition hover:bg-indigo-100"
            >
              Open Categories
            </Link>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              add-category
            </span>
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              update-category
            </span>
            <span className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-[11px] font-medium text-slate-600">
              delete-category
            </span>
          </div>
        </section>
      </div>

      {!hasAuth ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
          Admin token not found. Please login again to use protected APIs.
        </div>
      ) : null}

      {errorMessage ? (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {errorMessage}
        </div>
      ) : null}
      {successMessage ? (
        <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
          {successMessage}
        </div>
      ) : null}

      <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-4 py-3">
          <h2 className="text-sm font-semibold text-slate-800">
            Leads ({filteredLeads.length})
          </h2>
          <div className="flex flex-wrap items-center gap-2">
            <input
              type="text"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              placeholder="Search title, city, category..."
              className="w-52 rounded-lg border border-slate-300 px-3 py-1.5 text-xs outline-none focus:border-violet-500"
            />
            <select
              value={statusFilter}
              onChange={(event) =>
                setStatusFilter(event.target.value as 'all' | 'ACTIVE' | 'SOLD_OUT' | 'EXPIRED')
              }
              className="rounded-lg border border-slate-300 px-2.5 py-1.5 text-xs outline-none focus:border-violet-500"
            >
              <option value="all">All status</option>
              <option value="ACTIVE">Active</option>
              <option value="SOLD_OUT">Sold out</option>
              <option value="EXPIRED">Expired</option>
            </select>
            <button
              type="button"
              disabled={!hasAuth || loadingLeads}
              onClick={() => void loadLeads()}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700 disabled:opacity-60"
            >
              Refresh
            </button>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Location</th>
                <th className="px-4 py-3">Price</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {loadingLeads ? (
                <tr>
                  <td className="px-4 py-6 text-slate-500" colSpan={6}>
                    Loading leads...
                  </td>
                </tr>
              ) : filteredLeads.length === 0 ? (
                <tr>
                  <td className="px-4 py-8" colSpan={6}>
                    <div className="mx-auto max-w-md rounded-xl border border-slate-200 bg-slate-50 px-4 py-4 text-center">
                      <p className="text-sm font-medium text-slate-700">
                        No leads found for selected filters.
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        Try changing search/status filter or create a new lead.
                      </p>
                      <div className="mt-3 flex justify-center gap-2">
                        <button
                          type="button"
                          onClick={openCreateDrawer}
                          className="rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-medium text-white"
                        >
                          Create Lead
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setSearchQuery('')
                            setStatusFilter('all')
                          }}
                          className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
                        >
                          Reset filters
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredLeads.map((lead) => (
                  <tr key={lead._id} className="odd:bg-white even:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-800">{lead.title}</p>
                      <p className="text-xs text-slate-500">{lead.description || '-'}</p>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{getCategoryName(lead.category)}</td>
                    <td className="px-4 py-3 text-slate-600">
                      {lead.city || '-'}, {lead.state || '-'}
                    </td>
                    <td className="px-4 py-3 text-slate-700">
                      {formatAmount(lead.price)}
                      <p className="mt-0.5 text-[11px] text-slate-500">
                        Sold {lead.buyersCount ?? 0}/{lead.maxBuyers ?? 0}
                      </p>
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full border px-2.5 py-1 text-xs ${getStatusClasses(lead.status)}`}
                      >
                        {lead.status || '-'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="inline-flex gap-1">
                        <button
                          type="button"
                          onClick={() => void handleViewLeadDetails(lead._id)}
                          className="rounded-md border border-slate-300 px-2 py-1 text-xs text-slate-700"
                        >
                          View details
                        </button>
                        <button
                          type="button"
                          onClick={() => openEditDrawer(lead)}
                          className="rounded-md border border-violet-300 px-2 py-1 text-xs text-violet-700"
                        >
                          Edit lead
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleDeleteLead(lead._id)}
                          className="rounded-md border border-rose-300 px-2 py-1 text-xs text-rose-700"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <div className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-200 px-4 py-3 text-xs text-slate-600">
          <p>
            Showing {filteredLeads.length} of {leads.length} loaded leads (Total {leadMeta.total})
          </p>
          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={loadingLeads || leadMeta.page <= 1}
              onClick={() =>
                setLeadMeta((previous) => ({ ...previous, page: Math.max(1, previous.page - 1) }))
              }
              className="rounded-md border border-slate-300 px-2.5 py-1 text-xs text-slate-700 disabled:opacity-50"
            >
              Prev
            </button>
            <span>
              Page {leadMeta.page} / {leadMeta.totalPages}
            </span>
            <button
              type="button"
              disabled={loadingLeads || leadMeta.page >= leadMeta.totalPages}
              onClick={() =>
                setLeadMeta((previous) => ({
                  ...previous,
                  page: Math.min(previous.totalPages, previous.page + 1),
                }))
              }
              className="rounded-md border border-slate-300 px-2.5 py-1 text-xs text-slate-700 disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </section>

      {selectedLeadDetails ? (
        <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-semibold text-slate-900">
              Lead details
            </h2>
            <button
              type="button"
              onClick={() => setSelectedLeadDetails(null)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
            >
              Close
            </button>
          </div>
          {loadingLeadDetails ? (
            <p className="mt-3 text-sm text-slate-500">Loading details...</p>
          ) : (
            <div className="mt-4 space-y-4">
              <div className="grid gap-3 md:grid-cols-2">
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Title</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.title || '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Category</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {getCategoryName(selectedLeadDetails.category)}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Customer</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.customerName || '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Phone</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.phone || '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Location</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.city || '-'}, {selectedLeadDetails.state || '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Price</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {formatAmount(selectedLeadDetails.price)}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Budget</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {formatAmount(selectedLeadDetails.budget?.min)} to{' '}
                  {formatAmount(selectedLeadDetails.budget?.max)}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Slots</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.buyersCount ?? 0}/{selectedLeadDetails.maxBuyers ?? 0} sold
                  ({selectedLeadDetails.remainingSlots ?? 0} remaining)
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Address</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.address || '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Coordinates</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.location?.coordinates?.length === 2
                    ? `${selectedLeadDetails.location.coordinates[0]}, ${selectedLeadDetails.location.coordinates[1]}`
                    : '-'}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Expires at</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {formatDateTime(selectedLeadDetails.expiresAt)}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Created by</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {selectedLeadDetails.createdBy?.firstname || '-'} (
                  {selectedLeadDetails.createdBy?.email || '-'})
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Updated at</p>
                <p className="mt-1 text-sm font-medium text-slate-800">
                  {formatDateTime(selectedLeadDetails.updatedAt)}
                </p>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 md:col-span-2">
                <p className="text-[11px] uppercase tracking-wide text-slate-500">Description</p>
                <p className="mt-1 text-sm text-slate-800">
                  {selectedLeadDetails.description || '-'}
                </p>
              </div>
            </div>
              <div className="rounded-lg border border-slate-200">
                <div className="border-b border-slate-200 bg-slate-50 px-3 py-2">
                  <p className="text-xs font-semibold text-slate-700">
                    Purchases ({selectedLeadDetails.purchases?.length ?? 0})
                  </p>
                </div>
                <div className="divide-y divide-slate-100">
                  {selectedLeadDetails.purchases?.length ? (
                    selectedLeadDetails.purchases.map((purchase) => (
                      <div
                        key={purchase._id}
                        className="flex flex-wrap items-center justify-between gap-2 px-3 py-2 text-xs"
                      >
                        <p className="font-medium text-slate-700">
                          {purchase.user?.firstname || 'Unknown'} ({purchase.user?.email || '-'})
                        </p>
                        <p className="text-slate-600">
                          Qty {purchase.quantity ?? 0} • {formatDateTime(purchase.purchasedAt)}
                        </p>
                      </div>
                    ))
                  ) : (
                    <p className="px-3 py-3 text-xs text-slate-500">
                      No purchase records available.
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </section>
      ) : null}

      <div
        className={`fixed inset-0 z-40 transition ${isCreateDrawerOpen ? 'pointer-events-auto' : 'pointer-events-none'}`}
      >
        <div
          onClick={closeCreateDrawer}
          className={`absolute inset-0 bg-slate-950/30 transition-opacity ${isCreateDrawerOpen ? 'opacity-100' : 'opacity-0'}`}
        />
        <aside
          className={`absolute right-0 top-0 h-full w-full max-w-xl overflow-y-auto bg-white shadow-2xl transition-transform duration-300 ${isCreateDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
        >
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
            <div>
              <h2 className="text-base font-semibold text-slate-900">
                {editingLeadId ? 'Edit lead' : 'Create lead'}
              </h2>
              <p className="text-xs text-slate-500">
                {editingLeadId
                  ? 'Update lead details from this side form'
                  : 'Quick side form with instant save'}
              </p>
            </div>
            <button
              type="button"
              onClick={closeCreateDrawer}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
            >
              Close
            </button>
          </div>

          <form className="space-y-4 p-4 md:p-5" onSubmit={handleCreateLeadSubmit}>
            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                Basic info
              </p>
              <div className="mt-3 space-y-3">
                <label className="block text-xs font-medium text-slate-600">
                  Lead title <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={leadForm.title}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, title: event.target.value }))
                    }
                    placeholder="Modern 2BHK Interior"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="block text-xs font-medium text-slate-600">
                  Category <span className="text-rose-500">*</span>
                  <select
                    value={leadForm.category}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, category: event.target.value }))
                    }
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                    disabled={loadingCategories}
                  >
                    <option value="">
                      {loadingCategories ? 'Loading categories...' : 'Select category'}
                    </option>
                    {sortedCategories.map((category) => (
                      <option key={category._id} value={category._id}>
                        {category.name}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="block text-xs font-medium text-slate-600">
                  Description <span className="text-rose-500">*</span>
                  <textarea
                    value={leadForm.description}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, description: event.target.value }))
                    }
                    rows={4}
                    placeholder="Lead details..."
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
              </div>
            </div>

            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                Pricing and location
              </p>
              <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
                <label className="text-xs font-medium text-slate-600">
                  City <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={leadForm.city}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, city: event.target.value }))
                    }
                    placeholder="Pune"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="text-xs font-medium text-slate-600">
                  State <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={leadForm.state}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, state: event.target.value }))
                    }
                    placeholder="Maharashtra"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="text-xs font-medium text-slate-600">
                  Price <span className="text-rose-500">*</span>
                  <input
                    type="number"
                    min="1"
                    value={leadForm.price}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, price: event.target.value }))
                    }
                    placeholder="500"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="text-xs font-medium text-slate-600">
                  Original price
                  <input
                    type="number"
                    min="1"
                    value={leadForm.originalPrice}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, originalPrice: event.target.value }))
                    }
                    placeholder="700"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="sm:col-span-2 text-xs font-medium text-slate-600">
                  Expiry date and time <span className="text-rose-500">*</span>
                  <input
                    type="datetime-local"
                    value={leadForm.expiresAt}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, expiresAt: event.target.value }))
                    }
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="text-xs font-medium text-slate-600">
                  Latitude <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={leadForm.latitude}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, latitude: event.target.value }))
                    }
                    placeholder="18.559"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="text-xs font-medium text-slate-600">
                  Longitude <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={leadForm.longitude}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, longitude: event.target.value }))
                    }
                    placeholder="73.786"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="sm:col-span-2 text-xs font-medium text-slate-600">
                  Address
                  <input
                    type="text"
                    value={leadForm.address}
                    onChange={(event) =>
                      setLeadForm((previous) => ({ ...previous, address: event.target.value }))
                    }
                    placeholder="Baner, Pune"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
              </div>
            </div>

            <div className="flex items-center gap-2 pt-1">
              <button
                type="submit"
                disabled={!hasAuth || submittingLead}
                className="rounded-lg bg-violet-600 px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-500 disabled:opacity-60"
              >
                {submittingLead ? 'Saving...' : editingLeadId ? 'Update lead' : 'Create lead'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setEditingLeadId('')
                  setLeadForm(initialLeadForm)
                  closeCreateDrawer()
                }}
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
              >
                Cancel
              </button>
            </div>
          </form>
        </aside>
      </div>

      <div
        className={`fixed inset-0 z-50 transition ${isUploadDrawerOpen ? 'pointer-events-auto' : 'pointer-events-none'}`}
      >
        <div
          onClick={closeUploadDrawer}
          className={`absolute inset-0 bg-slate-950/30 transition-opacity ${isUploadDrawerOpen ? 'opacity-100' : 'opacity-0'}`}
        />
        <aside
          className={`absolute right-0 top-0 h-full w-full max-w-lg overflow-y-auto bg-white shadow-2xl transition-transform duration-300 ${isUploadDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
        >
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
            <div>
              <h2 className="text-base font-semibold text-slate-900">Bulk leads upload</h2>
              <p className="text-xs text-slate-500">
                Upload `.xlsx` file and track progress from `upload-status`.
              </p>
            </div>
            <button
              type="button"
              onClick={closeUploadDrawer}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
            >
              Close
            </button>
          </div>

          <form className="space-y-3 p-4" onSubmit={handleUploadLeads}>
            <label
              htmlFor="bulk-upload-file"
              className={[
                'block cursor-pointer rounded-xl border border-dashed px-4 py-4 transition',
                isDragActive
                  ? 'border-violet-500 bg-violet-100'
                  : 'border-violet-300 bg-violet-50/60 hover:bg-violet-100/60',
              ].join(' ')}
            >
              <input
                id="bulk-upload-file"
                type="file"
                accept=".xlsx"
                onChange={(event) => {
                  const file = event.target.files?.[0] ?? null
                  if (!file) return
                  if (!isValidExcelFile(file)) {
                    handleApiError('Only .xlsx files are allowed')
                    return
                  }
                  clearMessages()
                  setSelectedFile(file)
                }}
                className="hidden"
              />
              <div
                onDragOver={handleDragOver}
                onDragLeave={handleDragLeave}
                onDrop={handleDrop}
                className="rounded-lg"
              >
                <p className="text-xs font-semibold text-violet-700">
                  Choose Excel file or drag and drop
                </p>
                <p className="mt-1 text-[11px] text-slate-600">
                  Endpoint: `POST /leads/upload-leads`
                </p>
              </div>
              <p className="mt-2 truncate text-xs text-slate-700">
                {selectedFile
                  ? `${selectedFile.name} • ${(selectedFile.size / 1024).toFixed(1)} KB`
                  : 'No file selected'}
              </p>
            </label>

            <div className="flex items-center gap-2">
              <button
                type="submit"
                disabled={!hasAuth || uploading || !selectedFile}
                className="rounded-lg bg-violet-600 px-4 py-2 text-xs font-semibold text-white transition hover:bg-violet-500 disabled:opacity-60"
              >
                {uploading ? 'Uploading...' : 'Upload leads'}
              </button>
              {selectedFile ? (
                <button
                  type="button"
                  onClick={() => setSelectedFile(null)}
                  className="rounded-lg border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700"
                >
                  Remove file
                </button>
              ) : null}
            </div>
          </form>

          {uploadStatus ? (
            <div className="px-4 pb-5">
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-3 text-xs text-slate-600">
                <div className="mb-2 flex items-center justify-between">
                  <p className="font-medium text-slate-700">Status: {uploadStatus.status}</p>
                  <p className="text-violet-700">{uploadStatus.progress}</p>
                </div>
                <div className="h-2 overflow-hidden rounded-full bg-slate-200">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-violet-600 to-indigo-500 transition-all duration-300"
                    style={{ width: `${uploadPercent}%` }}
                  />
                </div>
                <p className="mt-2">
                  Processed: {uploadStatus.processed}/{uploadStatus.total} | Success:{' '}
                  {uploadStatus.success} | Failed: {uploadStatus.failed}
                </p>
                <p className="mt-1 text-slate-500">{uploadStatus.message}</p>
              </div>

              {uploadStatus.logs.length ? (
                <div className="mt-3 rounded-lg border border-rose-200 bg-rose-50 px-3 py-3">
                  <p className="text-xs font-semibold text-rose-700">Failed rows</p>
                  <div className="mt-2 space-y-1.5">
                    {uploadStatus.logs.map((log) => (
                      <p key={log._id ?? `${log.row}-${log.message}`} className="text-xs text-rose-700">
                        Row {log.row ?? '-'}: {log.message ?? 'Unknown error'}
                      </p>
                    ))}
                  </div>
                </div>
              ) : null}
            </div>
          ) : null}
        </aside>
      </div>
    </div>
  )
}

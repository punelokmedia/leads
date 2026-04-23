import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type DragEvent,
  type FormEvent,
} from 'react'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type Category = {
  _id: string
  name: string
}

type LeadCategory = string | { _id: string; name?: string }

type Lead = {
  _id: string
  title: string
  description?: string
  city?: string
  state?: string
  address?: string
  price?: number
  originalPrice?: number
  expiresAt?: string
  category?: LeadCategory
  location?: { coordinates?: number[] }
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
}

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

export function CreateLeadPage() {
  const [token, setToken] = useState('')
  const [categories, setCategories] = useState<Category[]>([])
  const [leads, setLeads] = useState<Lead[]>([])
  const [submittingLead, setSubmittingLead] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [loading, setLoading] = useState(false)
  const [editingLeadId, setEditingLeadId] = useState('')
  const [leadForm, setLeadForm] = useState<LeadFormState>(initialLeadForm)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [isDragActive, setIsDragActive] = useState(false)
  const [uploadStatus, setUploadStatus] = useState<UploadStatus | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const [successMessage, setSuccessMessage] = useState('')

  const hasAuth = Boolean(token)

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

      const payload = (await response.json()) as Record<string, unknown>
      if (!response.ok || payload.success === false) {
        throw new Error((payload.message as string) || 'Request failed')
      }
      return payload
    },
    [token],
  )

  const loadData = useCallback(async () => {
    if (!token) return
    setLoading(true)
    try {
      const [categoriesPayload, leadsPayload] = await Promise.all([
        fetchWithAuth(`${API_BASE_URL}/api/v1/categories/get-all-categories`),
        fetchWithAuth(
          `${API_BASE_URL}/api/v1/admin/dashboard/get-all-leads?limit=50&sort=latest`,
        ),
      ])
      setCategories((categoriesPayload.data as Category[]) ?? [])
      setLeads((leadsPayload.data as Lead[]) ?? [])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to load data')
    } finally {
      setLoading(false)
    }
  }, [fetchWithAuth, token])

  useEffect(() => {
    setToken(getToken())
  }, [])

  useEffect(() => {
    if (!token) return
    void loadData()
  }, [loadData, token])

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
        const nextStatus: UploadStatus = {
          uploadId: uploadStatus.uploadId,
          status: String(payload.status ?? 'processing'),
          progress: String(payload.progress ?? '0%'),
          processed: Number(payload.processed ?? 0),
          total: Number(payload.total ?? 0),
          success: Number(payload.success ?? 0),
          failed: Number(payload.failed ?? 0),
          message: String(payload.message ?? ''),
        }
        setUploadStatus(nextStatus)
        if (nextStatus.status === 'completed') {
          setUploading(false)
          setSuccessMessage(nextStatus.message || 'Upload completed')
          void loadData()
        }
      } catch {
        // best effort polling
      }
    }, 2500)

    return () => window.clearInterval(timer)
  }, [loadData, uploadStatus])

  const sortedCategories = useMemo(
    () => [...categories].sort((a, b) => a.name.localeCompare(b.name)),
    [categories],
  )

  const uploadPercent = useMemo(() => {
    const raw = uploadStatus?.progress ?? '0%'
    const parsed = Number.parseFloat(raw)
    if (Number.isNaN(parsed)) return 0
    return Math.max(0, Math.min(100, parsed))
  }, [uploadStatus])

  function isValidExcelFile(file: File) {
    const fileName = file.name.toLowerCase()
    return fileName.endsWith('.xlsx')
  }

  async function handleLeadSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const latitude = Number(leadForm.latitude)
    const longitude = Number(leadForm.longitude)
    const price = Number(leadForm.price)
    const originalPrice = leadForm.originalPrice
      ? Number(leadForm.originalPrice)
      : undefined
    const expiresAtIso = leadForm.expiresAt
      ? new Date(leadForm.expiresAt).toISOString()
      : ''

    if (
      !leadForm.title ||
      !leadForm.description ||
      !leadForm.category ||
      !leadForm.city ||
      !leadForm.state ||
      !leadForm.price ||
      !leadForm.expiresAt
    ) {
      setErrorMessage('Please fill all required lead fields')
      return
    }
    if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
      setErrorMessage('Latitude and longitude are required')
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
        setSuccessMessage('Lead updated successfully')
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
        setSuccessMessage('Lead created successfully')
      }
      setLeadForm(initialLeadForm)
      setEditingLeadId('')
      await loadData()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to save lead')
    } finally {
      setSubmittingLead(false)
    }
  }

  function startEditLead(lead: Lead) {
    const coordinates = lead.location?.coordinates ?? [0, 0]
    clearMessages()
    setEditingLeadId(lead._id)
    setLeadForm({
      title: lead.title ?? '',
      description: lead.description ?? '',
      category: getCategoryId(lead.category),
      city: lead.city ?? '',
      state: lead.state ?? '',
      address: lead.address ?? '',
      price: lead.price ? String(lead.price) : '',
      originalPrice: lead.originalPrice ? String(lead.originalPrice) : '',
      expiresAt: toDateTimeLocal(lead.expiresAt),
      latitude: coordinates[1] ? String(coordinates[1]) : '',
      longitude: coordinates[0] ? String(coordinates[0]) : '',
    })
  }

  async function startUpload(file: File) {
    if (!isValidExcelFile(file)) {
      setErrorMessage('Only .xlsx files are allowed')
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
      })
      setSuccessMessage('Excel upload started.')
      setSelectedFile(null)
    } catch (error) {
      setUploading(false)
      setErrorMessage(error instanceof Error ? error.message : 'Failed to upload leads')
    }
  }

  async function handleUploadLeads(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!selectedFile) {
      setErrorMessage('Please choose an Excel file (.xlsx)')
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
      setErrorMessage('Only .xlsx files are allowed')
      return
    }
    clearMessages()
    setSelectedFile(droppedFile)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
          Create Lead
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Dedicated page for lead create/update and bulk upload forms.
        </p>
      </div>

      {!hasAuth ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
          Admin token not found. Please login again.
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

      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-base font-semibold text-slate-900">
          {editingLeadId ? 'Update lead' : 'Create new lead'}
        </h2>
        <form className="mt-4 grid gap-4 md:grid-cols-2" onSubmit={handleLeadSubmit}>
          <label className="text-xs font-medium text-slate-600">
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
          <label className="text-xs font-medium text-slate-600">
            Category <span className="text-rose-500">*</span>
            <select
              value={leadForm.category}
              onChange={(event) =>
                setLeadForm((previous) => ({ ...previous, category: event.target.value }))
              }
              className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
            >
              <option value="">Select category</option>
              {sortedCategories.map((category) => (
                <option key={category._id} value={category._id}>
                  {category.name}
                </option>
              ))}
            </select>
          </label>
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
                setLeadForm((previous) => ({
                  ...previous,
                  originalPrice: event.target.value,
                }))
              }
              placeholder="700"
              className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
            />
          </label>
          <label className="text-xs font-medium text-slate-600">
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
          <label className="text-xs font-medium text-slate-600 md:col-span-2">
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
          <label className="text-xs font-medium text-slate-600 md:col-span-2">
            Description <span className="text-rose-500">*</span>
            <textarea
              value={leadForm.description}
              onChange={(event) =>
                setLeadForm((previous) => ({ ...previous, description: event.target.value }))
              }
              rows={3}
              placeholder="Full home interior design..."
              className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
            />
          </label>
          <div className="flex items-center gap-2 md:col-span-2">
            <button
              type="submit"
              disabled={!hasAuth || submittingLead}
              className="rounded-lg bg-violet-600 px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-500 disabled:opacity-60"
            >
              {submittingLead
                ? 'Saving...'
                : editingLeadId
                  ? 'Update lead'
                  : 'Create lead'}
            </button>
            {editingLeadId ? (
              <button
                type="button"
                onClick={() => {
                  setEditingLeadId('')
                  setLeadForm(initialLeadForm)
                }}
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
              >
                Cancel edit
              </button>
            ) : null}
          </div>
        </form>
      </section>

      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-base font-semibold text-slate-900">Bulk upload leads</h2>
        <p className="mt-1 text-xs text-slate-500">
          Upload `.xlsx` file to create leads in bulk.
        </p>
        <form className="mt-4 space-y-3" onSubmit={handleUploadLeads}>
          <div className="grid gap-3 md:grid-cols-[1fr_auto] md:items-center">
            <label
              htmlFor="leads-excel-file"
              className={[
                'cursor-pointer rounded-xl border border-dashed px-4 py-3 transition',
                isDragActive
                  ? 'border-violet-500 bg-violet-100'
                  : 'border-violet-300 bg-violet-50/60 hover:bg-violet-100/60',
              ].join(' ')}
            >
              <input
                id="leads-excel-file"
                type="file"
                accept=".xlsx"
                onChange={(event) => {
                  const file = event.target.files?.[0] ?? null
                  if (!file) return
                  if (!isValidExcelFile(file)) {
                    setErrorMessage('Only .xlsx files are allowed')
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
              </div>
              <p className="mt-1 truncate text-xs text-slate-600">
                {selectedFile
                  ? `${selectedFile.name} • ${(selectedFile.size / 1024).toFixed(1)} KB`
                  : 'No file selected'}
              </p>
            </label>

            <button
              type="submit"
              disabled={!hasAuth || uploading || !selectedFile}
              className="rounded-lg bg-violet-600 px-4 py-2 text-xs font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {uploading ? 'Uploading...' : 'Upload leads'}
            </button>
          </div>

          {selectedFile ? (
            <button
              type="button"
              onClick={() => setSelectedFile(null)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700"
            >
              Remove selected file
            </button>
          ) : null}
        </form>
        {uploadStatus ? (
          <div className="mt-3 rounded-lg border border-slate-200 bg-slate-50 px-3 py-3 text-xs text-slate-600">
            <div className="mb-2 flex items-center justify-between">
              <p className="font-medium text-slate-700">
                Upload status: {uploadStatus.status}
              </p>
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
          </div>
        ) : null}
      </section>

      <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3">
          <h2 className="text-sm font-semibold text-slate-800">Recent leads for edit</h2>
          <button
            type="button"
            onClick={() => void loadData()}
            disabled={!hasAuth || loading}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700 disabled:opacity-60"
          >
            Refresh
          </button>
        </div>
        <div className="p-4">
          {loading ? (
            <p className="text-sm text-slate-500">Loading leads...</p>
          ) : leads.length === 0 ? (
            <p className="text-sm text-slate-500">No leads found.</p>
          ) : (
            <div className="grid gap-2">
              {leads.slice(0, 8).map((lead) => (
                <div
                  key={lead._id}
                  className="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50 px-3 py-2"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-slate-800">{lead.title}</p>
                    <p className="text-xs text-slate-500">
                      {lead.city || '-'}, {lead.state || '-'}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => startEditLead(lead)}
                    className="rounded-md border border-slate-300 px-2 py-1 text-xs text-slate-700"
                  >
                    Edit
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  )
}

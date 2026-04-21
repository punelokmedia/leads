import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { useSearchParams } from 'react-router-dom'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type Category = {
  _id: string
  name: string
  icon?: string
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

export function CategoriesPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [token, setToken] = useState('')
  const [categories, setCategories] = useState<Category[]>([])
  const [loadingCategories, setLoadingCategories] = useState(false)
  const [submittingCategory, setSubmittingCategory] = useState(false)
  const [isCategoryDrawerOpen, setIsCategoryDrawerOpen] = useState(false)
  const [editingCategoryId, setEditingCategoryId] = useState('')
  const [categoryName, setCategoryName] = useState('')
  const [categoryIcon, setCategoryIcon] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
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

  const loadCategories = useCallback(async () => {
    if (!token) return
    setLoadingCategories(true)
    try {
      const payload = await fetchWithAuth(
        `${API_BASE_URL}/api/v1/categories/get-all-categories`,
      )
      setCategories((payload.data as Category[]) ?? [])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to load categories')
    } finally {
      setLoadingCategories(false)
    }
  }, [fetchWithAuth, token])

  useEffect(() => {
    setToken(getToken())
  }, [])

  useEffect(() => {
    if (!token) return
    void loadCategories()
  }, [loadCategories, token])

  const sortedCategories = useMemo(
    () => [...categories].sort((a, b) => a.name.localeCompare(b.name)),
    [categories],
  )

  const filteredCategories = useMemo(() => {
    const query = searchQuery.trim().toLowerCase()
    if (!query) return sortedCategories
    return sortedCategories.filter((category) =>
      `${category.name} ${category.icon ?? ''}`.toLowerCase().includes(query),
    )
  }, [searchQuery, sortedCategories])

  function openAddCategoryDrawer() {
    clearMessages()
    setEditingCategoryId('')
    setCategoryName('')
    setCategoryIcon('')
    setIsCategoryDrawerOpen(true)
    const nextParams = new URLSearchParams(searchParams)
    nextParams.set('create', '1')
    setSearchParams(nextParams, { replace: true })
  }

  function closeCategoryDrawer() {
    setIsCategoryDrawerOpen(false)
    if (searchParams.has('create')) {
      const nextParams = new URLSearchParams(searchParams)
      nextParams.delete('create')
      setSearchParams(nextParams, { replace: true })
    }
  }

  async function handleCategorySubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!categoryName.trim()) {
      setErrorMessage('Category name is required')
      return
    }

    clearMessages()
    setSubmittingCategory(true)
    try {
      if (editingCategoryId) {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/categories/update-category`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            categoryId: editingCategoryId,
            name: categoryName.trim(),
            icon: categoryIcon.trim() || undefined,
          }),
        })
        setSuccessMessage('Category updated successfully')
      } else {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/categories/add-category`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: categoryName.trim(),
            icon: categoryIcon.trim() || undefined,
          }),
        })
        setSuccessMessage('Category created successfully')
      }
      setEditingCategoryId('')
      setCategoryName('')
      setCategoryIcon('')
      closeCategoryDrawer()
      await loadCategories()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to save category')
    } finally {
      setSubmittingCategory(false)
    }
  }

  function handleEditCategory(category: Category) {
    clearMessages()
    setIsCategoryDrawerOpen(true)
    setEditingCategoryId(category._id)
    setCategoryName(category.name)
    setCategoryIcon(category.icon ?? '')
  }

  async function handleDeleteCategory(categoryId: string) {
    if (!window.confirm('Delete this category?')) return
    clearMessages()
    try {
      await fetchWithAuth(`${API_BASE_URL}/api/v1/categories/delete-category`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ categoryId }),
      })
      setSuccessMessage('Category deleted successfully')
      await loadCategories()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to delete category')
    }
  }

  useEffect(() => {
    if (searchParams.get('create') === '1') {
      setIsCategoryDrawerOpen(true)
    }
  }, [searchParams])

  return (
    <div className="space-y-6">
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-gradient-to-br from-white via-violet-50/40 to-indigo-50/30 shadow-sm">
        <div className="relative px-5 py-5 md:px-6 md:py-6">
          <div className="pointer-events-none absolute right-0 top-0 h-36 w-36 rounded-full bg-violet-200/40 blur-3xl" />
          <div className="pointer-events-none absolute -bottom-12 -left-12 h-28 w-28 rounded-full bg-sky-200/40 blur-3xl" />
          <div className="relative flex flex-wrap items-center justify-between gap-4">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.15em] text-violet-600">
                Categories Workspace
              </p>
              <h1 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
                Category Management
              </h1>
              <p className="mt-1 text-sm text-slate-600">
                Keep category names organized and maintain clean lead classification.
              </p>
            </div>
            <div className="rounded-2xl border border-violet-100 bg-white/90 px-4 py-3 text-right shadow-sm">
              <p className="text-[11px] uppercase tracking-wide text-slate-500">
                Total categories
              </p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">{categories.length}</p>
            </div>
          </div>
        </div>
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

      <div>
        <section className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-4 py-3 md:px-5">
            <h2 className="text-sm font-semibold text-slate-800">
              Categories ({filteredCategories.length})
            </h2>
            <div className="flex flex-wrap items-center gap-2">
              <input
                type="text"
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                placeholder="Search category..."
                className="w-44 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
              />
              <button
                type="button"
                onClick={() => void loadCategories()}
                disabled={!hasAuth || loadingCategories}
                className="rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-100 disabled:opacity-60"
              >
                Refresh
              </button>
              <button
                type="button"
                onClick={openAddCategoryDrawer}
                className="rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-violet-500"
              >
                + Add category
              </button>
            </div>
          </div>
          <div className="p-4 md:p-5">
            {loadingCategories ? (
              <div className="grid gap-2">
                {Array.from({ length: 3 }).map((_, index) => (
                  <div
                    key={index}
                    className="h-16 animate-pulse rounded-xl border border-slate-200 bg-slate-100"
                  />
                ))}
              </div>
            ) : filteredCategories.length === 0 ? (
              <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-center">
                <p className="text-sm font-medium text-slate-700">
                  No categories found.
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Add a new category or adjust your search filter.
                </p>
                <button
                  type="button"
                  onClick={openAddCategoryDrawer}
                  className="mt-3 rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-semibold text-white"
                >
                  Add category
                </button>
              </div>
            ) : (
              <div className="grid gap-3">
                {filteredCategories.map((category, index) => (
                  <div
                    key={category._id}
                    className="rounded-xl border border-slate-200 bg-gradient-to-r from-white to-slate-50 px-3 py-3 shadow-sm transition hover:border-violet-200 hover:shadow"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex min-w-0 items-center gap-3">
                        <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-violet-100 text-xs font-semibold text-violet-700">
                          {category.name.slice(0, 2).toUpperCase()}
                        </span>
                        <div className="min-w-0">
                          <p className="truncate text-sm font-semibold text-slate-800">
                            {category.name}
                          </p>
                          <p className="truncate text-xs text-slate-500">
                            {category.icon || 'No icon URL'}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <span className="hidden rounded-md bg-slate-100 px-2 py-1 text-[10px] font-medium text-slate-500 md:inline-flex">
                          #{index + 1}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleEditCategory(category)}
                          className="rounded-md border border-slate-300 bg-white px-2.5 py-1 text-xs font-medium text-slate-700 transition hover:bg-slate-100"
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleDeleteCategory(category._id)}
                          className="rounded-md border border-rose-300 bg-white px-2.5 py-1 text-xs font-medium text-rose-700 transition hover:bg-rose-50"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>

      <div
        className={`fixed inset-0 z-40 transition ${isCategoryDrawerOpen ? 'pointer-events-auto' : 'pointer-events-none'}`}
      >
        <div
          onClick={closeCategoryDrawer}
          className={`absolute inset-0 bg-slate-950/30 transition-opacity ${isCategoryDrawerOpen ? 'opacity-100' : 'opacity-0'}`}
        />
        <aside
          className={`absolute right-0 top-0 h-full w-full max-w-lg overflow-y-auto bg-white shadow-2xl transition-transform duration-300 ${isCategoryDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
        >
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
            <div>
              <h2 className="text-base font-semibold text-slate-900">
                {editingCategoryId ? 'Update category' : 'Add category'}
              </h2>
              <p className="text-xs text-slate-500">
                Use this panel to create or update a category quickly.
              </p>
            </div>
            <button
              type="button"
              onClick={closeCategoryDrawer}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
            >
              Close
            </button>
          </div>

          <form className="space-y-4 p-4" onSubmit={handleCategorySubmit}>
            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                Category details
              </p>
              <div className="mt-3 space-y-3">
                <label className="block text-xs font-medium text-slate-600">
                  Category name <span className="text-rose-500">*</span>
                  <input
                    type="text"
                    value={categoryName}
                    onChange={(event) => setCategoryName(event.target.value)}
                    placeholder="e.g. carpenter"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
                <label className="block text-xs font-medium text-slate-600">
                  Icon URL (optional)
                  <input
                    type="text"
                    value={categoryIcon}
                    onChange={(event) => setCategoryIcon(event.target.value)}
                    placeholder="https://..."
                    className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  />
                </label>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="submit"
                disabled={!hasAuth || submittingCategory}
                className="rounded-lg bg-violet-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-500 disabled:opacity-60"
              >
                {submittingCategory
                  ? 'Saving...'
                  : editingCategoryId
                    ? 'Update category'
                    : 'Add category'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setEditingCategoryId('')
                  setCategoryName('')
                  setCategoryIcon('')
                  closeCategoryDrawer()
                }}
                className="rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
              >
                Cancel
              </button>
            </div>
          </form>
        </aside>
      </div>
    </div>
  )
}

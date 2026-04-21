import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type PromotedAdmin = {
  id?: string
  email?: string
  role?: string
  isBlocked?: boolean
}

type MakeAdminResponse = {
  success: boolean
  message: string
  user: PromotedAdmin
}

type DashboardOverview = {
  totalUsers?: number
  totalAdmins?: number
}

type ManagedUser = {
  _id: string
  firstname?: string
  lastname?: string
  email?: string
  role?: string
  isBlocked?: boolean
  phoneNumber?: string
  createdAt?: string
}

type ListMeta = {
  total: number
  page: number
  limit: number
  totalPages: number
}

const PAGE_SIZE = 5

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

export function AddAdminPage() {
  const [userId, setUserId] = useState('')
  const [email, setEmail] = useState('')
  const [firstname, setFirstname] = useState('')
  const [lastname, setLastname] = useState('')
  const [overview, setOverview] = useState({ totalUsers: 0, totalAdmins: 0 })
  const [loadingOverview, setLoadingOverview] = useState(true)
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [successMessage, setSuccessMessage] = useState('')
  const [promotedUser, setPromotedUser] = useState<PromotedAdmin | null>(null)
  const [apiPreview, setApiPreview] = useState<MakeAdminResponse | null>(null)
  const [allUsers, setAllUsers] = useState<ManagedUser[]>([])
  const [allAdmins, setAllAdmins] = useState<ManagedUser[]>([])
  const [loadingLists, setLoadingLists] = useState(true)
  const [listSearch, setListSearch] = useState('')
  const [usersPage, setUsersPage] = useState(1)
  const [adminsPage, setAdminsPage] = useState(1)
  const [usersMeta, setUsersMeta] = useState<ListMeta>({
    total: 0,
    page: 1,
    limit: PAGE_SIZE,
    totalPages: 1,
  })
  const [adminsMeta, setAdminsMeta] = useState<ListMeta>({
    total: 0,
    page: 1,
    limit: PAGE_SIZE,
    totalPages: 1,
  })
  const [isFormDrawerOpen, setIsFormDrawerOpen] = useState(false)
  const isEmailFlow = Boolean(email.trim())

  const loadOverview = useCallback(async () => {
    const token = getToken()
    if (!token) {
      setLoadingOverview(false)
      return
    }

    try {
      setLoadingOverview(true)
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/dashboard/overview`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })
      const payload = (await response.json()) as {
        success?: boolean
        data?: DashboardOverview
      }

      if (!response.ok || payload.success === false) {
        return
      }

      setOverview({
        totalUsers: Number(payload.data?.totalUsers ?? 0),
        totalAdmins: Number(payload.data?.totalAdmins ?? 0),
      })
    } finally {
      setLoadingOverview(false)
    }
  }, [])

  const loadUsersAndAdmins = useCallback(async () => {
    const token = getToken()
    if (!token) {
      setLoadingLists(false)
      return
    }

    try {
      setLoadingLists(true)
      const searchQuery = listSearch.trim()
      const [usersRes, adminsRes] = await Promise.all([
        fetch(
          `${API_BASE_URL}/api/v1/admin/users?page=${usersPage}&limit=${PAGE_SIZE}${
            searchQuery ? `&search=${encodeURIComponent(searchQuery)}` : ''
          }`,
          {
          headers: { Authorization: `Bearer ${token}` },
          },
        ),
        fetch(
          `${API_BASE_URL}/api/v1/admin/admins?page=${adminsPage}&limit=${PAGE_SIZE}${
            searchQuery ? `&search=${encodeURIComponent(searchQuery)}` : ''
          }`,
          {
          headers: { Authorization: `Bearer ${token}` },
          },
        ),
      ])

      const usersPayload = (await usersRes.json()) as {
        success?: boolean
        data?: ManagedUser[]
        meta?: Partial<ListMeta>
      }
      const adminsPayload = (await adminsRes.json()) as {
        success?: boolean
        data?: ManagedUser[]
        meta?: Partial<ListMeta>
      }

      if (usersRes.ok && usersPayload.success) {
        setAllUsers(usersPayload.data ?? [])
        setUsersMeta((prev) => ({
          total: Number(usersPayload.meta?.total ?? prev.total ?? 0),
          page: Number(usersPayload.meta?.page ?? usersPage),
          limit: Number(usersPayload.meta?.limit ?? PAGE_SIZE),
          totalPages: Math.max(1, Number(usersPayload.meta?.totalPages ?? prev.totalPages ?? 1)),
        }))
      }
      if (adminsRes.ok && adminsPayload.success) {
        setAllAdmins(adminsPayload.data ?? [])
        setAdminsMeta((prev) => ({
          total: Number(adminsPayload.meta?.total ?? prev.total ?? 0),
          page: Number(adminsPayload.meta?.page ?? adminsPage),
          limit: Number(adminsPayload.meta?.limit ?? PAGE_SIZE),
          totalPages: Math.max(
            1,
            Number(adminsPayload.meta?.totalPages ?? prev.totalPages ?? 1),
          ),
        }))
      }
    } finally {
      setLoadingLists(false)
    }
  }, [adminsPage, listSearch, usersPage])

  useEffect(() => {
    void loadOverview()
  }, [loadOverview])

  useEffect(() => {
    void loadUsersAndAdmins()
  }, [loadUsersAndAdmins])

  const stats = useMemo(
    () => [
      { label: 'Total Users', value: overview.totalUsers, short: 'US' },
      { label: 'Total Admins', value: overview.totalAdmins, short: 'AD' },
    ],
    [overview.totalAdmins, overview.totalUsers],
  )

  async function runAdminAction(
    endpoint: string,
    body: Record<string, unknown>,
    fallbackError: string,
  ) {
    const token = getToken()
    if (!token) {
      throw new Error('Admin token not found. Please login again.')
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    })

    const payload = (await response.json()) as {
      success?: boolean
      message?: string
      user?: PromotedAdmin
    }

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || fallbackError)
    }

    return payload
  }

  function getActionIdentifiers(target?: ManagedUser) {
    const targetEmail = target?.email?.trim().toLowerCase() ?? ''
    const targetId = target?._id?.trim() ?? ''
    const trimmedEmail = email.trim().toLowerCase()
    const trimmedUserId = userId.trim()

    const resolvedEmail = targetEmail || trimmedEmail
    const resolvedUserId = targetId || (!resolvedEmail ? trimmedUserId : '')

    return { resolvedEmail, resolvedUserId }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const trimmedEmail = email.trim().toLowerCase()
    const trimmedUserId = userId.trim()
    const trimmedFirstname = firstname.trim()
    const trimmedLastname = lastname.trim()

    if (!trimmedUserId && !trimmedEmail) {
      setErrorMessage('User ID ya Email me se koi ek required hai')
      setSuccessMessage('')
      return
    }

    const token = getToken()
    if (!token) {
      setErrorMessage('Admin token not found. Please login again.')
      setSuccessMessage('')
      return
    }

    try {
      setLoading(true)
      setErrorMessage('')
      setSuccessMessage('')
      setPromotedUser(null)
      setApiPreview(null)

      const response = await fetch(`${API_BASE_URL}/api/v1/admin/make-admin`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...(trimmedEmail
            ? {
                email: trimmedEmail,
                ...(trimmedFirstname ? { firstname: trimmedFirstname } : {}),
                ...(trimmedLastname ? { lastname: trimmedLastname } : {}),
              }
            : {}),
          ...(!trimmedEmail && trimmedUserId ? { userId: trimmedUserId } : {}),
        }),
      })

      const payload = (await response.json()) as {
        success?: boolean
        message?: string
        user?: PromotedAdmin
      }

      if (!response.ok || payload.success === false) {
        throw new Error(payload.message || 'Failed to promote user')
      }

      setSuccessMessage(payload.message || 'User promoted to admin successfully')
      const promoted = payload.user ?? null
      setPromotedUser(promoted)
      if (promoted) {
        setApiPreview({
          success: true,
          message: payload.message || 'User promoted to admin successfully',
          user: {
            id: promoted.id ?? '',
            email: promoted.email ?? '',
            role: promoted.role ?? '',
          },
        })
      }
      setUserId('')
      setEmail('')
      setFirstname('')
      setLastname('')
      setOverview((previous) => ({
        ...previous,
        totalAdmins: previous.totalAdmins + 1,
      }))
      await Promise.all([loadOverview(), loadUsersAndAdmins()])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to promote user')
    } finally {
      setLoading(false)
    }
  }

  async function handleRemoveAdmin(target?: ManagedUser) {
    const { resolvedEmail, resolvedUserId } = getActionIdentifiers(target)

    if (!resolvedUserId && !resolvedEmail) {
      setErrorMessage('User ID ya Email me se koi ek required hai')
      return
    }

    try {
      setLoading(true)
      setErrorMessage('')
      setSuccessMessage('')
      const payload = await runAdminAction(
        '/api/v1/admin/remove-admin',
        {
          ...(resolvedEmail ? { email: resolvedEmail } : {}),
          ...(!resolvedEmail && resolvedUserId ? { userId: resolvedUserId } : {}),
        },
        'Failed to remove admin role',
      )
      setSuccessMessage(payload.message || 'Admin role removed successfully')
      setOverview((previous) => ({
        ...previous,
        totalAdmins: Math.max(0, previous.totalAdmins - 1),
      }))
      await Promise.all([loadOverview(), loadUsersAndAdmins()])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to remove admin role')
    } finally {
      setLoading(false)
    }
  }

  async function handleBlockToggle(blockValue: boolean, target?: ManagedUser) {
    const { resolvedEmail, resolvedUserId } = getActionIdentifiers(target)

    if (!resolvedUserId && !resolvedEmail) {
      setErrorMessage('User ID ya Email me se koi ek required hai')
      return
    }

    try {
      setLoading(true)
      setErrorMessage('')
      setSuccessMessage('')
      const payload = await runAdminAction(
        '/api/v1/admin/users/block',
        {
          ...(resolvedEmail ? { email: resolvedEmail } : {}),
          ...(!resolvedEmail && resolvedUserId ? { userId: resolvedUserId } : {}),
          isBlocked: blockValue,
        },
        blockValue ? 'Failed to block user' : 'Failed to unblock user',
      )
      setSuccessMessage(
        payload.message || (blockValue ? 'User blocked successfully' : 'User unblocked successfully'),
      )
      await loadUsersAndAdmins()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to update block status')
    } finally {
      setLoading(false)
    }
  }

  async function handleDeleteUser(target?: ManagedUser) {
    const { resolvedEmail, resolvedUserId } = getActionIdentifiers(target)

    if (!resolvedUserId && !resolvedEmail) {
      setErrorMessage('User ID ya Email me se koi ek required hai')
      return
    }

    if (!window.confirm('Are you sure you want to delete this user?')) return

    try {
      setLoading(true)
      setErrorMessage('')
      setSuccessMessage('')
      const payload = await runAdminAction(
        '/api/v1/admin/users/delete',
        {
          ...(resolvedEmail ? { email: resolvedEmail } : {}),
          ...(!resolvedEmail && resolvedUserId ? { userId: resolvedUserId } : {}),
        },
        'Failed to delete user',
      )
      setSuccessMessage(payload.message || 'User deleted successfully')
      setOverview((previous) => ({
        ...previous,
        totalUsers: Math.max(0, previous.totalUsers - 1),
        totalAdmins:
          payload.user?.role === 'ADMIN'
            ? Math.max(0, previous.totalAdmins - 1)
            : previous.totalAdmins,
      }))
      await Promise.all([loadOverview(), loadUsersAndAdmins()])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to delete user')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
              Add New Admin
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Existing user ko `userId` se promote karo ya new admin `email` se create karo.
            </p>
          </div>
          <div className="rounded-xl border border-violet-200 bg-violet-50 px-3 py-2">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-violet-700">
              Admin panel
            </p>
            <p className="mt-0.5 text-xs text-violet-600">Role management</p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        {stats.map((item) => (
          <div key={item.label} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <p className="text-xs uppercase tracking-wide text-slate-500">{item.label}</p>
              <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-slate-100 text-[10px] font-semibold text-slate-600">
                {item.short}
              </span>
            </div>
            <p className="mt-1 text-2xl font-semibold text-slate-900">
              {loadingOverview ? '...' : item.value.toLocaleString('en-IN')}
            </p>
          </div>
        ))}
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={() => setIsFormDrawerOpen(true)}
          className="rounded-lg bg-violet-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-violet-500"
        >
          Open Admin Form
        </button>
      </div>

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

      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Users & Admins</h2>
            <p className="text-xs text-slate-500">
              All users/admins with details. Yahin se direct block/delete/remove-admin actions karo.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={listSearch}
              onChange={(event) => {
                setListSearch(event.target.value)
                setUsersPage(1)
                setAdminsPage(1)
              }}
              placeholder="Search name or email..."
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500"
            />
            <button
              type="button"
              onClick={() => void loadUsersAndAdmins()}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
            >
              Refresh
            </button>
          </div>
        </div>

        <div className="mt-4 grid gap-4 lg:grid-cols-2">
          <div className="rounded-xl border border-slate-200">
            <div className="border-b border-slate-200 bg-slate-50 px-3 py-2">
              <p className="text-sm font-semibold text-slate-700">
                All Users ({usersMeta.total})
              </p>
            </div>
            <div className="max-h-[420px] space-y-2 overflow-y-auto p-2">
              {loadingLists ? (
                <div className="rounded-lg border border-slate-200 bg-white px-3 py-6 text-center text-xs text-slate-500">
                  Loading users...
                </div>
              ) : allUsers.length === 0 ? (
                <div className="rounded-lg border border-slate-200 bg-white px-3 py-6 text-center text-xs text-slate-500">
                  No users found
                </div>
              ) : (
                allUsers.map((item) => (
                  <div key={item._id} className="rounded-lg border border-slate-200 bg-white p-3">
                    <div className="flex flex-wrap items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-slate-800">
                          {`${(item.firstname || '').trim()} ${(item.lastname || '').trim()}`.trim() || 'No name'}
                        </p>
                        <p className="truncate text-xs text-slate-500">{item.email || '-'}</p>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-medium text-slate-700">
                          {item.role || '-'}
                        </span>
                        {item.isBlocked ? (
                          <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-medium text-rose-700">
                            Blocked
                          </span>
                        ) : (
                          <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[11px] font-medium text-emerald-700">
                            Active
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      <button
                        type="button"
                        onClick={() => void handleBlockToggle(!item.isBlocked, item)}
                        className="rounded border border-slate-300 px-2 py-1 text-[11px] font-medium text-slate-700"
                      >
                        {item.isBlocked ? 'Unblock' : 'Block'}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDeleteUser(item)}
                        className="rounded border border-rose-300 px-2 py-1 text-[11px] font-medium text-rose-700"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
            <div className="flex items-center justify-between border-t border-slate-200 px-3 py-2 text-xs text-slate-600">
              <p>
                Page {usersMeta.page} / {usersMeta.totalPages} (Total {usersMeta.total})
              </p>
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  disabled={loadingLists || usersMeta.page <= 1}
                  onClick={() => setUsersPage((prev) => Math.max(1, prev - 1))}
                  className="rounded border border-slate-300 px-2 py-1 text-[11px] text-slate-700 disabled:opacity-50"
                >
                  Prev
                </button>
                <button
                  type="button"
                  disabled={loadingLists || usersMeta.page >= usersMeta.totalPages}
                  onClick={() =>
                    setUsersPage((prev) => Math.min(usersMeta.totalPages, prev + 1))
                  }
                  className="rounded border border-slate-300 px-2 py-1 text-[11px] text-slate-700 disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </div>
          </div>

          <div className="rounded-xl border border-slate-200">
            <div className="border-b border-slate-200 bg-slate-50 px-3 py-2">
              <p className="text-sm font-semibold text-slate-700">All Admins ({adminsMeta.total})</p>
            </div>
            <div className="max-h-[420px] space-y-2 overflow-y-auto p-2">
              {loadingLists ? (
                <div className="rounded-lg border border-slate-200 bg-white px-3 py-6 text-center text-xs text-slate-500">
                  Loading admins...
                </div>
              ) : allAdmins.length === 0 ? (
                <div className="rounded-lg border border-slate-200 bg-white px-3 py-6 text-center text-xs text-slate-500">
                  No admins found
                </div>
              ) : (
                allAdmins.map((item) => (
                  <div key={item._id} className="rounded-lg border border-slate-200 bg-white p-3">
                    <div className="flex flex-wrap items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-slate-800">
                          {`${(item.firstname || '').trim()} ${(item.lastname || '').trim()}`.trim() || 'No name'}
                        </p>
                        <p className="truncate text-xs text-slate-500">{item.email || '-'}</p>
                      </div>
                      <div>
                        {item.isBlocked ? (
                          <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-medium text-rose-700">
                            Blocked
                          </span>
                        ) : (
                          <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[11px] font-medium text-emerald-700">
                            Active
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      <button
                        type="button"
                        onClick={() => void handleBlockToggle(!item.isBlocked, item)}
                        className="rounded border border-slate-300 px-2 py-1 text-[11px] font-medium text-slate-700"
                      >
                        {item.isBlocked ? 'Unblock' : 'Block'}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleRemoveAdmin(item)}
                        className="rounded border border-amber-300 px-2 py-1 text-[11px] font-medium text-amber-700"
                      >
                        Remove Admin
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDeleteUser(item)}
                        className="rounded border border-rose-300 px-2 py-1 text-[11px] font-medium text-rose-700"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
            <div className="flex items-center justify-between border-t border-slate-200 px-3 py-2 text-xs text-slate-600">
              <p>
                Page {adminsMeta.page} / {adminsMeta.totalPages} (Total {adminsMeta.total})
              </p>
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  disabled={loadingLists || adminsMeta.page <= 1}
                  onClick={() => setAdminsPage((prev) => Math.max(1, prev - 1))}
                  className="rounded border border-slate-300 px-2 py-1 text-[11px] text-slate-700 disabled:opacity-50"
                >
                  Prev
                </button>
                <button
                  type="button"
                  disabled={loadingLists || adminsMeta.page >= adminsMeta.totalPages}
                  onClick={() =>
                    setAdminsPage((prev) => Math.min(adminsMeta.totalPages, prev + 1))
                  }
                  className="rounded border border-slate-300 px-2 py-1 text-[11px] text-slate-700 disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div
        className={`fixed inset-0 z-50 transition ${isFormDrawerOpen ? 'pointer-events-auto' : 'pointer-events-none'}`}
      >
        <div
          onClick={() => setIsFormDrawerOpen(false)}
          className={`absolute inset-0 bg-slate-950/40 transition-opacity ${isFormDrawerOpen ? 'opacity-100' : 'opacity-0'}`}
        />
        <aside
          className={`absolute right-0 top-0 h-full w-full max-w-2xl overflow-y-auto bg-white shadow-2xl transition-transform duration-300 ${isFormDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
        >
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
            <div>
              <h3 className="text-base font-semibold text-slate-900">Admin Form</h3>
              <p className="text-xs text-slate-500">Create admin or promote existing user.</p>
            </div>
            <button
              type="button"
              onClick={() => setIsFormDrawerOpen(false)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700"
            >
              Close
            </button>
          </div>

          <div className="p-4 md:p-5">
            <div className="mb-4 flex flex-wrap items-center gap-2">
              <span
                className={`rounded-full px-3 py-1 text-xs font-medium ${
                  isEmailFlow ? 'bg-violet-100 text-violet-700' : 'bg-slate-100 text-slate-600'
                }`}
              >
                Email Flow
              </span>
              <span
                className={`rounded-full px-3 py-1 text-xs font-medium ${
                  !isEmailFlow ? 'bg-violet-100 text-violet-700' : 'bg-slate-100 text-slate-600'
                }`}
              >
                User ID Flow
              </span>
            </div>

            <form className="space-y-4" onSubmit={handleSubmit}>
              <label className="block text-sm font-medium text-slate-700">
                User ID (optional)
                <input
                  type="text"
                  value={userId}
                  onChange={(event) => setUserId(event.target.value)}
                  disabled={isEmailFlow}
                  placeholder="69df88e081d21c7ba9aec69a"
                  className="mt-1.5 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                />
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Email (optional)
                <input
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder="swapnil2002@gmail.com"
                  className="mt-1.5 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500"
                />
              </label>
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="block text-sm font-medium text-slate-700">
                  First name (new admin create)
                  <input
                    type="text"
                    value={firstname}
                    onChange={(event) => setFirstname(event.target.value)}
                    disabled={!isEmailFlow}
                    placeholder="Swapnil"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                  />
                </label>
                <label className="block text-sm font-medium text-slate-700">
                  Last name (new admin create)
                  <input
                    type="text"
                    value={lastname}
                    onChange={(event) => setLastname(event.target.value)}
                    disabled={!isEmailFlow}
                    placeholder="Admin"
                    className="mt-1.5 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-violet-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                  />
                </label>
              </div>
              <div className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-600">
                Tip: Email bharoge to email flow use hoga (new create/promote), userId ignore ho jayega.
                User ID flow tab use hoga jab email empty ho.
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <button
                  type="submit"
                  disabled={loading}
                  className="rounded-lg bg-violet-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-violet-500 disabled:opacity-60"
                >
                  {loading ? 'Processing...' : 'Make Admin'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setUserId('')
                    setEmail('')
                    setFirstname('')
                    setLastname('')
                    setErrorMessage('')
                    setSuccessMessage('')
                    setPromotedUser(null)
                    setApiPreview(null)
                  }}
                  className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100"
                >
                  Reset
                </button>
              </div>
            </form>

            {promotedUser ? (
              <div className="mt-5 rounded-xl border border-emerald-200 bg-emerald-50 p-4">
                <p className="text-xs uppercase tracking-wide text-slate-500">Promoted user</p>
                <div className="mt-2 grid gap-2 text-sm text-slate-700 sm:grid-cols-3">
                  <p>ID: {promotedUser.id || '-'}</p>
                  <p>Email: {promotedUser.email || '-'}</p>
                  <p>Role: {promotedUser.role || '-'}</p>
                </div>
              </div>
            ) : null}

            {apiPreview ? (
              <div className="mt-4 rounded-xl border border-slate-200 bg-slate-950 p-4">
                <p className="text-xs uppercase tracking-wide text-slate-400">
                  API response preview
                </p>
                <pre className="mt-2 overflow-x-auto text-xs leading-5 text-slate-100">
                  {JSON.stringify(apiPreview, null, 2)}
                </pre>
              </div>
            ) : null}
          </div>
        </aside>
      </div>
    </div>
  )
}

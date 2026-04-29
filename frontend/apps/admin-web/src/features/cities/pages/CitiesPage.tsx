import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const AUTH_STORAGE_KEY = 'admin_auth_session'

type City = {
  _id: string
  name: string
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

export function CitiesPage() {
  const [token, setToken] = useState('')
  const [cities, setCities] = useState<City[]>([])
  const [loadingCities, setLoadingCities] = useState(false)
  const [submittingCity, setSubmittingCity] = useState(false)
  const [cityName, setCityName] = useState('')
  const [editingCityId, setEditingCityId] = useState('')
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

  const loadCities = useCallback(async () => {
    setLoadingCities(true)
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/cities/get-all-cities`)
      const payload = (await response.json()) as { success?: boolean; data?: City[]; message?: string }
      if (!response.ok || payload.success === false) {
        throw new Error(payload.message || 'Failed to load cities')
      }
      setCities(payload.data ?? [])
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to load cities')
    } finally {
      setLoadingCities(false)
    }
  }, [])

  useEffect(() => {
    setToken(getToken())
  }, [])

  useEffect(() => {
    if (!token) return
    void loadCities()
  }, [loadCities, token])

  const sortedCities = useMemo(
    () => [...cities].sort((a, b) => a.name.localeCompare(b.name)),
    [cities],
  )

  async function handleCitySubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!cityName.trim()) {
      setErrorMessage('City name is required')
      return
    }

    clearMessages()
    setSubmittingCity(true)
    try {
      if (editingCityId) {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/cities/update-city`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ cityId: editingCityId, name: cityName.trim() }),
        })
        setSuccessMessage('City updated successfully')
      } else {
        await fetchWithAuth(`${API_BASE_URL}/api/v1/cities/add-city`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: cityName.trim() }),
        })
        setSuccessMessage('City added successfully')
      }
      setCityName('')
      setEditingCityId('')
      await loadCities()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to save city')
    } finally {
      setSubmittingCity(false)
    }
  }

  function handleEditCity(city: City) {
    clearMessages()
    setEditingCityId(city._id)
    setCityName(city.name)
  }

  async function handleDeleteCity(cityId: string) {
    if (!window.confirm('Delete this city?')) return
    clearMessages()
    try {
      await fetchWithAuth(`${API_BASE_URL}/api/v1/cities/delete-city`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cityId }),
      })
      setSuccessMessage('City deleted successfully')
      await loadCities()
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Failed to delete city')
    }
  }

  return (
    <div className="space-y-5">
      <div className="overflow-hidden rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-violet-50/40 to-indigo-50/20 shadow-sm">
        <div className="relative px-5 py-4 md:px-6 md:py-5">
          <div className="pointer-events-none absolute right-0 top-0 h-36 w-36 rounded-full bg-violet-200/40 blur-3xl" />
          <div className="relative flex flex-wrap items-end justify-between gap-4">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.15em] text-violet-600">
                Cities Workspace
              </p>
              <h1 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
                City Management
              </h1>
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

      <section className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-4 py-3 md:px-5">
          <h2 className="text-sm font-semibold text-slate-800">Cities ({sortedCities.length})</h2>
          <button
            type="button"
            onClick={() => void loadCities()}
            disabled={loadingCities}
            className="rounded-xl border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 disabled:opacity-60"
          >
            Refresh
          </button>
        </div>
        <div className="space-y-3 p-4 md:p-5">
          <form onSubmit={handleCitySubmit} className="flex flex-wrap items-center gap-2">
            <input
              type="text"
              value={cityName}
              onChange={(event) => setCityName(event.target.value)}
              placeholder="Add city name..."
              className="w-64 rounded-xl border border-slate-300 bg-white px-3 py-2 text-xs outline-none transition focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
            />
            <button
              type="submit"
              disabled={!hasAuth || submittingCity}
              className="rounded-xl bg-violet-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-500 disabled:opacity-60"
            >
              {submittingCity ? 'Saving...' : editingCityId ? 'Update city' : '+ Add city'}
            </button>
            {editingCityId ? (
              <button
                type="button"
                onClick={() => {
                  setEditingCityId('')
                  setCityName('')
                }}
                className="rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
              >
                Cancel
              </button>
            ) : null}
          </form>

          {loadingCities ? (
            <p className="text-xs text-slate-500">Loading cities...</p>
          ) : sortedCities.length === 0 ? (
            <p className="text-xs text-slate-500">No cities yet.</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {sortedCities.map((city) => (
                <div
                  key={city._id}
                  className="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700"
                >
                  <span className="capitalize">{city.name}</span>
                  <button
                    type="button"
                    onClick={() => handleEditCity(city)}
                    className="rounded-md px-1 text-violet-600 hover:bg-violet-50"
                  >
                    edit
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleDeleteCity(city._id)}
                    className="rounded-md px-1 text-rose-600 hover:bg-rose-50"
                  >
                    x
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

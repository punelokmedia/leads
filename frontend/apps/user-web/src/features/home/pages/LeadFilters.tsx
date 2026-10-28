import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import { apiFetch } from '@/features/auth/session'
import { useUserToken } from '@/features/auth/useUserToken'
import './lead-filters.css'
import { RowsSkeleton } from '@/components/loading/Skeleton'



export function LeadFilters() {
  const [params, setParams] = useSearchParams()
  const token = useUserToken()
  const [projects, setProjects] = useState<string[]>([])
  const [properties, setProperties] = useState<string[]>([])
  const [optionsLoading, setOptionsLoading] = useState(true)
  const [optionsError, setOptionsError] = useState('')
  const categoryKey = params.get('category') || ''
  const searchKey = params.get('search') || ''
  const [city, setCity] = useState(params.get('city') || '')
  const [radius, setRadius] = useState(params.get('nearby') === 'true' ? params.get('radiusKm') || '50' : '')
  const [cities, setCities] = useState<string[]>([])
  const [minimum, setMinimum] = useState(params.get('priceMin') || '0')
  const [maximum, setMaximum] = useState(params.get('priceMax') || '5000')
  const [budgetEnabled, setBudgetEnabled] = useState(params.has('priceMin') || params.has('priceMax'))
  const [project, setProject] = useState(params.get('projectTypes')?.split(',') || [])
  const [property, setProperty] = useState(params.get('propertyTypes')?.split(',') || [])
  const [period, setPeriod] = useState(params.has('postedFrom') || params.has('postedTo') ? 'custom' : 'any')
  const [from, setFrom] = useState(params.get('postedFrom') || '')
  const [to, setTo] = useState(params.get('postedTo') || '')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  useEffect(() => {
    let cancelled = false
    void apiFetch(`${API_BASE_URL}/api/v1/cities/get-all-cities`, { signal: AbortSignal.timeout(12000) }).then(async response => {
      const payload = await response.json()
      if (!cancelled && response.ok && payload.success && Array.isArray(payload.data)) setCities(payload.data.map((item: { name: string }) => item.name))
    }).catch(() => { /* The city text input remains available. */ })
    return () => { cancelled = true }
  }, [])
  useEffect(() => {
    let cancelled = false
    setOptionsLoading(true); setOptionsError('')
    const query = new URLSearchParams()
    if (categoryKey) query.set('category', categoryKey)
    if (searchKey) query.set('search', searchKey)
    void apiFetch(`${API_BASE_URL}/api/v1/leads/filter-options?${query}`, { signal: AbortSignal.timeout(12000) }).then(async response => {
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load filters.')
      if (!cancelled) { setProjects(payload.data.projectTypes); setProperties(payload.data.propertyTypes) }
    }).catch(() => { if (!cancelled) setOptionsError('Unable to load category options. Refresh to retry.') })
      .finally(() => { if (!cancelled) setOptionsLoading(false) })
    return () => { cancelled = true }
  }, [categoryKey, searchKey])
  const toggle = (values: string[], value: string) => values.includes(value) ? values.filter(item => item !== value) : [...values, value]
  const clear = () => {
    setCity(''); setRadius(''); setMinimum('0'); setMaximum('5000'); setBudgetEnabled(false)
    setProject([]); setProperty([]); setPeriod('any'); setFrom(''); setTo(''); setError('')
    const next = new URLSearchParams(params)
    for (const key of ['city', 'nearby', 'radiusKm', 'budgetMin', 'budgetMax', 'priceMin', 'priceMax', 'projectTypes', 'propertyTypes', 'postedFrom', 'postedTo']) next.delete(key)
    setParams(next)
  }
  async function apply(event: FormEvent) {
    event.preventDefault(); setError('')
    if (budgetEnabled && (Number(minimum) < 0 || Number(maximum) > 5000 || Number(maximum) < Number(minimum))) { setError('Enter a lead price range between ₹0 and ₹5,000.'); return }
    if (period === 'custom' && (!from || !to || from > to)) { setError('Select a valid start and end date.'); return }
    const next = new URLSearchParams(params)
    for (const key of ['city', 'nearby', 'radiusKm', 'budgetMin', 'budgetMax', 'priceMin', 'priceMax', 'projectTypes', 'propertyTypes', 'postedFrom', 'postedTo']) next.delete(key)
    if (city.trim()) next.set('city', city.trim())
    if (budgetEnabled) { next.set('priceMin', minimum); next.set('priceMax', maximum) }
    if (project.length) next.set('projectTypes', project.join(','))
    if (property.length) next.set('propertyTypes', property.join(','))
    if (period === 'custom') { next.set('postedFrom', from); next.set('postedTo', to) }
    else if (period !== 'any') {
      const day = new Date(Date.now() - Number(period) * 86400000)
      next.set('postedFrom', new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit' }).format(day))
    }
    if (radius) {
      if (!token) { setError('Sign in to search near your current location.'); return }
      if (!navigator.geolocation) { setError('Your browser does not support location. Choose a city instead.'); return }
      setBusy(true)
      try {
        const position = await new Promise<GeolocationPosition>((resolve, reject) => navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 15000, maximumAge: 60000 }))
        const response = await apiFetch(`${API_BASE_URL}/api/v1/auth/mobile/permissions`, { method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ location: 'granted', latitude: position.coords.latitude, longitude: position.coords.longitude }) })
        const payload = await response.json()
        if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to save location.')
        next.set('nearby', 'true'); next.set('radiusKm', radius)
      } catch (failure) { setError(failure instanceof Error ? failure.message : 'Location access is required for a radius search.'); setBusy(false); return }
      setBusy(false)
    }
    next.set('browse', '1'); setParams(next)
  }
  return <aside className="lead-filter-sidebar"><form onSubmit={event => void apply(event)}><header><h2><span aria-hidden="true">▽</span> Filters</h2><button type="button" disabled={busy} onClick={clear}>Clear All</button></header><fieldset disabled={busy}>
    <label className="lead-filter-label" htmlFor="lead-city">Location</label><input id="lead-city" list="lead-cities" placeholder="All locations" value={city} onChange={event => setCity(event.target.value)} /><datalist id="lead-cities">{cities.map(name => <option value={name} key={name}/>)}</datalist>
    <label className="lead-filter-label" htmlFor="lead-radius">Radius</label><select id="lead-radius" value={radius} onChange={event => setRadius(event.target.value)}><option value="">Any distance</option>{[5,10,25,50,100,200].map(value => <option key={value} value={value}>Within {value} km</option>)}</select>{radius && <p className="lead-filter-hint">From your current location. Location permission required.</p>}
    <div className="lead-filter-group"><h3>Lead Price</h3><p className="lead-filter-hint">Amount paid to purchase a lead. Customer project budgets are shown on each card.</p><label className="lead-filter-option"><input type="checkbox" checked={budgetEnabled} onChange={event => setBudgetEnabled(event.target.checked)} />Set lead price range</label><div className="lead-budget-values"><label><span>Minimum ₹</span><input type="number" max="5000" min="0" step="1" value={minimum} disabled={!budgetEnabled} onChange={event => setMinimum(event.target.value)} /></label><label><span>Maximum ₹</span><input type="number" max="5000" min={minimum} step="1" value={maximum} disabled={!budgetEnabled} onChange={event => setMaximum(event.target.value)} /></label></div><input aria-label="Maximum lead price" type="range" min="0" max="5000" step="1" value={maximum} disabled={!budgetEnabled} onChange={event => setMaximum(event.target.value)} /></div>
    <div className="lead-filter-group"><h3>Project Type</h3>{optionsLoading ? <RowsSkeleton count={2} /> : optionsError ? <p role="alert" className="lead-filter-error">{optionsError}</p> : !projects.length && <p className="lead-filter-hint">No project types listed for these leads.</p>}{projects.map(value => <label className="lead-filter-option" key={value}><input type="checkbox" checked={project.includes(value)} onChange={() => setProject(toggle(project, value))} />{value}</label>)}</div>
    <div className="lead-filter-group"><h3>Property Type</h3>{!optionsLoading && !properties.length && <p className="lead-filter-hint">No property types listed for these leads.</p>}{properties.map(value => <label className="lead-filter-option" key={value}><input type="checkbox" checked={property.includes(value)} onChange={() => setProperty(toggle(property, value))} />{value}</label>)}</div>
    <div className="lead-filter-group"><h3>Posted Date</h3>{[['any','Any time'],['7','Last 7 days'],['30','Last 30 days'],['custom','Custom range']].map(([value,label]) => <label className="lead-filter-option" key={value}><input type="radio" name="posted-date" value={value} checked={period===value} onChange={() => setPeriod(value)} />{label}</label>)}{period === 'custom' && <div className="lead-custom-dates"><label>From<input type="date" value={from} onChange={event => setFrom(event.target.value)} /></label><label>To<input type="date" min={from} value={to} onChange={event => setTo(event.target.value)} /></label></div>}</div>
    {error && <p className="lead-filter-error" role="alert">{error} {!token && radius && <Link to="/login">Sign in</Link>}</p>}<button className="lead-filter-apply" type="submit">{busy ? 'Getting location…' : 'Apply Filters'}</button>
  </fieldset></form></aside>
}

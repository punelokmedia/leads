import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react'
import { API_BASE_URL } from '@/config/api'
import { SendNotificationForm } from './SendNotificationForm'

const labels: Record<string, string> = {
  NEW_LEAD: 'New lead', PAYMENT_SUCCESS: 'Payment successful', WALLET_CREDIT: 'Wallet credited',
  REFUND_COMPLETED: 'Refund completed', MEMBERSHIP_ACTIVATED: 'Membership activated',
  SUPPORT_REPLY: 'Support reply', ANNOUNCEMENT: 'Announcement',
}
type Receipt = { channel: 'mobile' | 'web'; receivedAt: string }
type Notification = {
  _id: string; user: string; type: string; title: string; message: string; createdAt: string;
  readAt: string | null; targetId?: string; eventKey: string; receipts: Receipt[];
}
type Detail = Notification & {
  recipient: { firstname: string; lastname: string; email: string; isBlocked: boolean } | null;
  preferences: { newLeads: boolean; announcements: boolean; push: boolean };
  devices: { _id: string; platform: string; permission: string; updatedAt: string }[];
}
type Summary = {
  saved: number; read: number; unread: number; received: number; awaitingClient: number;
  mobileReceived: number; webReceived: number;
  byType: { type: string; saved: number; read: number }[];
  push: { configured: boolean; status: string };
}
type Filters = { userId: string; type: string; read: string; from: string; to: string }
const emptyFilters: Filters = { userId: '', type: '', read: '', from: '', to: '' }
const inputClass = 'mt-1 w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-100'
const buttonClass = 'rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50'
const date = (value?: string | null) => value ? new Date(value).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', dateStyle: 'medium', timeStyle: 'short' }) : '—'
async function request<T>(path: string, signal: AbortSignal): Promise<{ data: T; nextCursor?: string | null }> {
  let token = ''
  try { token = JSON.parse(localStorage.getItem('admin_auth_session') || '{}').token || '' } catch { /* handled below */ }
  if (!token) throw new Error('Admin session missing. Please sign in again.')
  const response = await fetch(`${API_BASE_URL}/api/v1/notifications/admin${path}`, { headers: { Authorization: `Bearer ${token}` }, signal })
  let payload: { success?: boolean; message?: string; data?: T; nextCursor?: string | null }
  try { payload = await response.json() } catch { throw new Error('Notification service returned an invalid response. Please retry.') }
  if (!response.ok || !payload.success || payload.data === undefined) throw new Error(payload.message || 'Could not load notifications.')
  return { data: payload.data, nextCursor: payload.nextCursor }
}
function Badge({ children, positive = false }: { children: ReactNode; positive?: boolean }) {
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${positive ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'}`}>{children}</span>
}

export function NotificationsPage() {
  const [draft, setDraft] = useState<Filters>(emptyFilters)
  const [query, setQuery] = useState('')
  const [cursors, setCursors] = useState<string[]>([''])
  const [next, setNext] = useState<string | null>(null)
  const [summary, setSummary] = useState<Summary | null>(null)
  const [rows, setRows] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [validation, setValidation] = useState('')
  const [refresh, setRefresh] = useState(0)
  const [updatedAt, setUpdatedAt] = useState('')
  const [selected, setSelected] = useState('')
  const [detail, setDetail] = useState<Detail | null>(null)
  const [detailError, setDetailError] = useState('')
  const detailPanel = useRef<HTMLElement>(null)
  const cursor = cursors.at(-1) || ''

  useEffect(() => {
    if (selected) detailPanel.current?.scrollIntoView({ block: 'start' })
  }, [selected])

  useEffect(() => {
    const controller = new AbortController()
    async function load() {
      setLoading(true); setError(''); setSummary(null); setRows([]); setNext(null)
      try {
        const params = new URLSearchParams(query)
        params.set('limit', '30')
        if (cursor) params.set('before', cursor)
        const [stats, history] = await Promise.all([
          request<Summary>(`/summary?${query}`, controller.signal),
          request<Notification[]>(`/notifications?${params}`, controller.signal),
        ])
        if (controller.signal.aborted) return
        setSummary(stats.data); setRows(history.data); setNext(history.nextCursor || null)
        setUpdatedAt(new Date().toISOString())
      } catch (err) {
        if (!controller.signal.aborted) setError(err instanceof Error ? err.message : 'Could not load notifications.')
      } finally { if (!controller.signal.aborted) setLoading(false) }
    }
    void load()
    return () => controller.abort()
  }, [query, cursor, refresh])

  useEffect(() => {
    if (!selected) return
    const controller = new AbortController()
    async function load() {
      setDetail(null); setDetailError('')
      try {
        const result = await request<Detail>(`/notifications/${selected}`, controller.signal)
        if (!controller.signal.aborted) setDetail(result.data)
      } catch (err) {
        if (!controller.signal.aborted) setDetailError(err instanceof Error ? err.message : 'Could not load recipient details.')
      }
    }
    void load()
    return () => controller.abort()
  }, [selected, refresh])

  function apply(event: FormEvent) {
    event.preventDefault()
    const userId = draft.userId.trim()
    if (userId && !/^[a-f\d]{24}$/i.test(userId)) { setValidation('Enter a valid 24-character user ID.'); return }
    if ((draft.from && !Number.isFinite(Date.parse(draft.from))) || (draft.to && !Number.isFinite(Date.parse(draft.to)))) { setValidation('Choose valid dates.'); return }
    if (draft.from && draft.to && new Date(draft.from) > new Date(draft.to)) { setValidation('The start time must be before the end time.'); return }
    const params = new URLSearchParams()
    if (userId) params.set('userId', userId)
    if (draft.type) params.set('type', draft.type)
    if (draft.read) params.set('read', draft.read)
    if (draft.from) params.set('from', new Date(draft.from).toISOString())
    if (draft.to) params.set('to', new Date(draft.to).toISOString())
    setValidation(''); setQuery(params.toString()); setCursors(['']); setSelected(''); setRefresh(v => v + 1)
  }
  function reset() { setDraft(emptyFilters); setQuery(''); setValidation(''); setCursors(['']); setSelected(''); setRefresh(v => v + 1) }
  const cards = summary ? [
    ['Saved in inbox', summary.saved], ['Received by client', summary.received], ['Awaiting confirmation', summary.awaitingClient],
    ['Read', summary.read], ['Unread', summary.unread], ['Mobile received', summary.mobileReceived], ['Web received', summary.webReceived],
  ] : []

  return <div className="space-y-6">
    <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div><p className="text-xs font-semibold uppercase tracking-widest text-violet-600">System activity</p><h1 className="mt-1 text-3xl font-semibold tracking-tight text-slate-900">Notifications</h1><p className="mt-2 text-sm text-slate-500">Check who received each notification across the app and web portal.</p></div>
        <div className="text-right"><button className={buttonClass} disabled={loading} onClick={() => setRefresh(v => v + 1)}>{loading ? 'Refreshing…' : 'Refresh'}</button>{updatedAt && <p className="mt-2 text-xs text-slate-500">Last updated {date(updatedAt)} IST</p>}</div>
      </div>
      <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
        <strong>Receipt tracking:</strong> Saved means the inbox record exists. Received means the app or portal confirmed receipt. Confirmation starts when those clients are connected. {summary?.push.configured ? 'Push delivery is tracked separately.' : 'Phone and browser push delivery is not connected yet.'}
      </div>
    </section>

    <SendNotificationForm onSent={() => { setCursors(['']); setRefresh(v => v + 1) }} />

    <form onSubmit={apply} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <label className="text-xs font-medium text-slate-600">Recipient user ID<input value={draft.userId} onChange={e => setDraft(v => ({ ...v, userId: e.target.value }))} placeholder="All recipients" className={inputClass} /></label>
        <label className="text-xs font-medium text-slate-600">Notification type<select value={draft.type} onChange={e => setDraft(v => ({ ...v, type: e.target.value }))} className={inputClass}><option value="">All types</option>{Object.entries(labels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
        <label className="text-xs font-medium text-slate-600">Read status<select value={draft.read} onChange={e => setDraft(v => ({ ...v, read: e.target.value }))} className={inputClass}><option value="">All statuses</option><option value="true">Read</option><option value="false">Unread</option></select></label>
        <label className="text-xs font-medium text-slate-600">Created from (your local time)<input type="datetime-local" value={draft.from} onChange={e => setDraft(v => ({ ...v, from: e.target.value }))} className={inputClass} /></label>
        <label className="text-xs font-medium text-slate-600">Created until (your local time)<input type="datetime-local" value={draft.to} onChange={e => setDraft(v => ({ ...v, to: e.target.value }))} className={inputClass} /></label>
      </div>
      <div className="mt-4 flex gap-2"><button type="submit" className="rounded-xl bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-700">Apply filters</button><button type="button" className={buttonClass} onClick={reset}>Reset</button></div>
      {validation && <p role="alert" className="mt-3 text-sm text-rose-600">{validation}</p>}
    </form>

    {error && <div role="alert" className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700">{error} <button className="ml-2 underline" onClick={() => setRefresh(v => v + 1)}>Retry</button></div>}
    {loading && <p role="status" className="text-sm text-slate-500">Loading notification activity…</p>}
    {summary && <>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">{cards.map(([label, value]) => <div key={label} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"><p className="text-xs font-medium text-slate-500">{label}</p><p className="mt-2 text-3xl font-semibold tracking-tight text-slate-900">{Number(value).toLocaleString('en-IN')}</p></div>)}</div>
      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="font-semibold text-slate-900">Counts by notification type</h2><p className="mt-1 text-xs text-slate-500">Counts reflect the applied filters across all pages. A notification received on both systems counts once in the overall received total.</p><div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">{summary.byType.map(row => <div key={row.type} className="rounded-xl bg-slate-50 p-3"><p className="text-sm font-medium text-slate-700">{labels[row.type] || row.type}</p><p className="mt-1 text-xs text-slate-500">{row.saved.toLocaleString('en-IN')} saved · {row.read.toLocaleString('en-IN')} read</p></div>)}</div></section>
    </>}

    {!loading && !error && <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-100 p-5"><h2 className="font-semibold text-slate-900">Notification history</h2><p className="mt-1 text-xs text-slate-500">Newest first · Up to 30 records per page · Times shown in IST</p></div>
      {!rows.length ? <div className="p-12 text-center"><p className="font-medium text-slate-700">No notifications match these filters</p><p className="mt-1 text-sm text-slate-500">New records appear after lead, payment, wallet, support, or announcement events.</p></div> : <div className="overflow-x-auto"><table className="w-full text-left text-sm"><thead className="bg-slate-50 text-xs text-slate-500"><tr>{['Notification', 'Recipient', 'Received on', 'Read status', 'Created', ''].map((heading, i) => <th key={i} scope="col" className="px-5 py-3">{heading || <span className="sr-only">Details</span>}</th>)}</tr></thead><tbody className="divide-y divide-slate-100">{rows.map(row => <tr key={row._id} className={selected === row._id ? 'bg-violet-50/60' : 'hover:bg-slate-50'}><td className="min-w-56 px-5 py-4"><p className="font-medium text-slate-900">{row.title}</p><p className="mt-1 text-xs text-slate-500">{labels[row.type] || row.type}</p></td><td className="px-5 py-4"><span className="font-mono text-xs text-slate-600">{row.user}</span></td><td className="px-5 py-4"><div className="flex gap-1">{row.receipts.length ? row.receipts.map(receipt => <Badge key={receipt.channel} positive>{receipt.channel === 'mobile' ? 'Mobile' : 'Web'}</Badge>) : <Badge>Awaiting confirmation</Badge>}</div></td><td className="px-5 py-4"><Badge positive={Boolean(row.readAt)}>{row.readAt ? 'Read' : 'Unread'}</Badge></td><td className="whitespace-nowrap px-5 py-4 text-xs text-slate-500">{date(row.createdAt)}</td><td className="px-5 py-4"><button aria-label={`Inspect ${row.title} for user ${row.user}`} className="font-medium text-violet-600 hover:underline" onClick={() => { setSelected(row._id); setDetail(null); setDetailError('') }}>Inspect</button></td></tr>)}</tbody></table></div>}
      <div className="flex items-center justify-between border-t border-slate-100 px-5 py-4"><span className="text-xs text-slate-500">Page {cursors.length}</span><div className="flex gap-2"><button className={buttonClass} disabled={cursors.length === 1} onClick={() => { setCursors(v => v.slice(0, -1)); setSelected('') }}>Previous</button><button className={buttonClass} disabled={!next} onClick={() => { if (next) setCursors(v => [...v, next]); setSelected('') }}>Next</button></div></div>
    </section>}

    {selected && <section ref={detailPanel} aria-label="Notification recipient details" aria-live="polite" className="scroll-mt-24 rounded-2xl border border-violet-200 bg-white p-5 shadow-sm">
      <div className="flex items-center justify-between"><h2 className="font-semibold text-slate-900">Recipient and delivery details</h2><button className={buttonClass} onClick={() => setSelected('')}>Close</button></div>
      {detailError ? <p role="alert" className="mt-4 text-sm text-rose-600">{detailError} <button className="underline" onClick={() => setRefresh(v => v + 1)}>Retry</button></p> : !detail ? <p className="mt-4 text-sm text-slate-500">Loading recipient…</p> : <div className="mt-5 grid gap-6 md:grid-cols-2">
        <div className="space-y-3"><h3 className="font-medium">{detail.title}</h3><p className="whitespace-pre-wrap break-words text-sm text-slate-600">{detail.message}</p><dl className="space-y-2 break-words text-sm"><dt className="text-slate-500">Recipient</dt><dd>{detail.recipient ? `${detail.recipient.firstname} ${detail.recipient.lastname} · ${detail.recipient.email}` : 'Account no longer available'}</dd><dt className="text-slate-500">User ID</dt><dd className="font-mono text-xs">{detail.user}</dd><dt className="text-slate-500">Notification / event</dt><dd className="font-mono text-xs">{detail._id}<br />{detail.eventKey}</dd>{detail.targetId && <><dt className="text-slate-500">Related record</dt><dd className="font-mono text-xs">{detail.targetId}</dd></>}<dt className="text-slate-500">Read at</dt><dd>{date(detail.readAt)} IST</dd></dl></div>
        <div className="space-y-4"><div className="rounded-xl bg-slate-50 p-4"><h3 className="text-sm font-medium">Inbox and receipt status</h3><p className="mt-2 text-sm text-slate-600">Saved to the recipient’s inbox at {date(detail.createdAt)} IST.</p>{(['mobile', 'web'] as const).map(channel => { const receipt = detail.receipts.find(r => r.channel === channel); return <p key={channel} className="mt-2 text-sm"><span className="font-medium">{channel === 'mobile' ? 'Mobile app' : 'Web portal'}:</span> {receipt ? `Confirmed ${date(receipt.receivedAt)} IST` : 'Awaiting client confirmation'}</p> })}<p className="mt-3 text-xs text-amber-700">Push delivery is not configured.</p></div>
          <div><h3 className="text-sm font-medium">Current preferences</h3><p className="mt-1 text-sm text-slate-600">Lead alerts: {detail.preferences.newLeads ? 'On' : 'Off'} · Announcements: {detail.preferences.announcements ? 'On' : 'Off'} · Push preference: {detail.preferences.push ? 'On' : 'Off'}</p>{detail.recipient?.isBlocked && <p className="mt-2 text-sm text-rose-600">This account is currently blocked.</p>}</div>
          <div><h3 className="text-sm font-medium">Registered devices ({detail.devices.length})</h3>{detail.devices.length ? detail.devices.map(device => <p key={device._id} className="mt-1 text-sm text-slate-600">{device.platform} · Permission reported as {device.permission} · Updated {date(device.updatedAt)} IST</p>) : <p className="mt-1 text-sm text-slate-500">No registered push devices.</p>}</div>
        </div>
      </div>}
    </section>}
  </div>
}

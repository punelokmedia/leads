import { useCallback, useEffect, useRef, useState } from 'react'
import { API_BASE_URL } from '@/config/api'
type Ticket = { _id: string; ticketId: string; issue: string; description: string; status: string; humanRequestedAt?: string; humanReplyAt?: string; user: { firstname?: string; lastname?: string }; statusHistory: { status: string; at: string }[] }
type Message = { _id: string; text: string; authorName: string }
const statuses = ['PENDING', 'ACTION_TAKEN', 'COMPLETED']
const label = (value: string) => value.toLowerCase().replaceAll('_', ' ')
async function request(path: string, body?: object) {
  const token = JSON.parse(localStorage.getItem('admin_auth_session') || '{}').token
  const response = await fetch(`${API_BASE_URL}/api/v1/support/admin/tickets${path}`, { method: body ? 'POST' : 'GET', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(15000), cache: 'no-store' })
  const payload = await response.json()
  if (!response.ok || !payload.success) throw new Error(payload.message || 'Ticket request failed')
  return payload
}
export function TicketsPanel() {
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [selected, setSelected] = useState<Ticket | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [filter, setFilter] = useState('')
  const [page, setPage] = useState(1)
  const [pages, setPages] = useState(0)
  const [error, setError] = useState('')
  const [text, setText] = useState('')
  const [busy, setBusy] = useState(false)
  const pending = useRef({ text: '', ticket: '', id: '' })
  const refresh = useCallback(async () => {
    try { const payload = await request(`?page=${page}&status=${filter}`); setTickets(payload.data); setPages(payload.pagination.totalPages) }
    catch (e) { setError(e instanceof Error ? e.message : 'Could not load tickets') }
  }, [page, filter])
  useEffect(() => { void refresh(); const timer = setInterval(() => { if (!document.hidden) void refresh() }, 15000); return () => clearInterval(timer) }, [refresh])
  const selectedId = selected?._id
  useEffect(() => {
    if (!selectedId) return
    let active = true
    const load = async () => {
      try {
        const [ticket, rows] = await Promise.all([request(`/${selectedId}`), request(`/${selectedId}/messages`)])
        if (active) { setSelected(ticket.data); setMessages(rows.data); if (rows.data.length) await request(`/${selectedId}/read`, { through: rows.data.at(-1)._id }) }
      } catch (e) { if (active) setError(e instanceof Error ? e.message : 'Could not load conversation') }
    }
    void load(); const timer = setInterval(() => { if (!document.hidden) void load() }, 15000)
    return () => { active = false; clearInterval(timer) }
  }, [selectedId])
  async function status(value: string) {
    if (!selected || busy) return
    setBusy(true); setError('')
    try { const payload = await request(`/${selected._id}/status`, { status: value, expectedStatus: selected.status }); setSelected(payload.data); await refresh() }
    catch (e) { setError(e instanceof Error ? e.message : 'Status update failed') }
    finally { setBusy(false) }
  }
  async function send() {
    if (!selected || busy || !text.trim()) return
    const value = text.trim()
    if (pending.current.text !== value || pending.current.ticket !== selected._id) pending.current = { text: value, ticket: selected._id, id: crypto.randomUUID() }
    setBusy(true); setError('')
    try { const payload = await request(`/${selected._id}/messages`, { text: value, clientId: pending.current.id }); setMessages(old => old.some(m => m._id === payload.data._id) ? old : [...old, payload.data]); setText(''); pending.current = { text: '', ticket: '', id: '' } }
    catch (e) { setError(e instanceof Error ? e.message : 'Reply failed; retry safely') }
    finally { setBusy(false) }
  }
  return <section className="space-y-4 rounded border p-4">
    <h2 className="text-xl font-bold">Support tickets</h2>
    <label>Status <select value={filter} onChange={e => { setFilter(e.target.value); setPage(1) }}><option value="">All statuses</option>{statuses.map(s => <option key={s} value={s}>{label(s)}</option>)}</select></label>
    <button onClick={() => void refresh()}>Refresh tickets</button>
    {error && <p role="alert" className="text-red-600">{error}</p>}
    <div className="grid gap-4 md:grid-cols-2"><div>{tickets.length === 0 && <p>No tickets found.</p>}{tickets.map(t => <button key={t._id} disabled={busy} onClick={() => { setSelected(t); setMessages([]); setText(''); setError('') }} className="mb-2 block w-full rounded border p-3 text-left"><strong>{t.ticketId}</strong><p>{t.user?.firstname} {t.user?.lastname}</p><p>{label(t.issue)} - {label(t.status)}</p><p>{t.humanReplyAt ? 'Human support replied' : t.humanRequestedAt ? 'Human support requested' : 'Automated guidance'}</p></button>)}<button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Previous</button> Page {page} <button disabled={page >= pages} onClick={() => setPage(p => p + 1)}>Next</button></div>
    {selected && <div className="space-y-3"><h3 className="font-bold">{selected.ticketId}</h3><p className="whitespace-pre-wrap">{selected.description}</p><p>{selected.humanRequestedAt ? 'Customer requested a human representative.' : 'Customer started with automated guidance.'}</p><label>Ticket status <select disabled={busy} value={selected.status} onChange={e => void status(e.target.value)}>{statuses.map(s => <option key={s} value={s}>{label(s)}</option>)}</select></label><details><summary>Status history</summary>{selected.statusHistory.map((h, i) => <p key={i}>{label(h.status)} - {new Date(h.at).toLocaleString()}</p>)}</details><div className="max-h-80 overflow-auto">{messages.map(m => <p key={m._id} className="whitespace-pre-wrap rounded border p-2"><strong>{m.authorName}: </strong>{m.text}</p>)}</div><textarea aria-label="Ticket reply" value={text} disabled={busy} maxLength={2000} onChange={e => setText(e.target.value)} className="w-full rounded border p-2"/><button disabled={busy || !text.trim()} onClick={() => void send()}>Send reply</button></div>}</div>
  </section>
}

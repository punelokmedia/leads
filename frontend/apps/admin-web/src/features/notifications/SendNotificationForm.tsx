import { useEffect, useRef, useState, type FormEvent } from 'react'
import { API_BASE_URL } from '@/config/api'

type Recipient = { _id: string; firstname: string; lastname: string; email: string }
const input = 'mt-1 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none'
async function api<T>(path: string, options: RequestInit = {}): Promise<{ data: T; nextCursor?: string | null }> {
  let token = ''
  try { token = JSON.parse(localStorage.getItem('admin_auth_session') || '{}').token || '' } catch { /* checked below */ }
  if (!token) throw new Error('Please sign in as an admin again.')
  const response = await fetch(`${API_BASE_URL}/api/v1/notifications/admin${path}`, { ...options, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } })
  const result = await response.json()
  if (!response.ok || !result.success) throw new Error(result.message || 'Notification request failed.')
  return result
}

export function SendNotificationForm({ onSent }: { onSent: () => void }) {
  const [search, setSearch] = useState('')
  const [cursor, setCursor] = useState('')
  const [next, setNext] = useState<string | null>(null)
  const [users, setUsers] = useState<Recipient[]>([])
  const [selected, setSelected] = useState<Recipient[]>([])
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(true)
  const [searchError, setSearchError] = useState('')
  const [sendError, setSendError] = useState('')
  const [success, setSuccess] = useState('')
  const [sending, setSending] = useState(false)
  const [reload, setReload] = useState(0)
  const pending = useRef({ signature: '', clientId: '' })
  const busy = useRef(false)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true); setSearchError(''); setUsers([]); setNext(null)
    const timer = setTimeout(() => {
      const params = new URLSearchParams({ q: search })
      if (cursor) params.set('before', cursor)
      void api<Recipient[]>(`/recipients?${params}`, { signal: controller.signal }).then(result => {
        if (!controller.signal.aborted) { setUsers(result.data); setNext(result.nextCursor || null) }
      }).catch(error => {
        if (!controller.signal.aborted) setSearchError(error instanceof Error ? error.message : 'Could not load recipients.')
      }).finally(() => { if (!controller.signal.aborted) setLoading(false) })
    }, 250)
    return () => { clearTimeout(timer); controller.abort() }
  }, [search, cursor, reload])

  async function send(event: FormEvent) {
    event.preventDefault()
    if (busy.current) return
    if (!selected.length || !title.trim() || !message.trim()) { setSendError('Choose at least one recipient and enter a title and message.'); return }
    const body = { userIds: selected.map(user => user._id).sort(), title: title.trim(), message: message.trim() }
    const signature = JSON.stringify(body)
    if (pending.current.signature !== signature) pending.current = { signature, clientId: crypto.randomUUID() }
    busy.current = true; setSending(true); setSendError(''); setSuccess('')
    try {
      const result = await api<{ recipients: number }>('/send', { method: 'POST', body: JSON.stringify({ ...body, clientId: pending.current.clientId }) })
      setSuccess(`Saved to ${result.data.recipients} recipient inbox${result.data.recipients === 1 ? '' : 'es'}. ${selected.length - result.data.recipients} skipped because the account is unavailable or announcements are disabled.`)
      setTitle(''); setMessage(''); setSelected([]); pending.current = { signature: '', clientId: '' }; onSent()
    } catch (error) { setSendError(`${error instanceof Error ? error.message : 'Send could not be confirmed.'} Retry the same message to finish without duplicates.`) }
    finally { busy.current = false; setSending(false) }
  }

  return <section className="rounded-2xl border border-violet-200 bg-white p-5 shadow-sm">
    <h2 className="text-lg font-semibold text-slate-900">Send notification</h2>
    <p className="mt-1 text-sm text-slate-500">Send an announcement to selected users. Users who disabled announcements will be skipped. This saves an inbox notification; push alerts are not connected yet.</p>
    <form onSubmit={send} className="mt-5 grid gap-6 lg:grid-cols-2">
      <div><label className="text-sm font-medium">Find recipients<input maxLength={100} value={search} disabled={sending} onChange={e => { setSearch(e.target.value); setCursor('') }} placeholder="Search by name, email or user ID" className={input} /></label>
        <p className="mt-2 text-xs text-slate-500">{selected.length} of 100 recipients selected</p>
        {selected.length > 0 && <div className="mt-2 flex flex-wrap gap-2">{selected.map(user => <button type="button" disabled={sending} key={user._id} onClick={() => setSelected(old => old.filter(item => item._id !== user._id))} aria-label={`Remove ${user.email}`} className="rounded-full bg-violet-50 px-3 py-1 text-xs text-violet-700">{user.firstname} · {user.email} ×</button>)}</div>}
        <div className="mt-3 max-h-64 overflow-y-auto rounded-xl border border-slate-200">
          {loading ? <p role="status" className="p-4 text-sm text-slate-500">Loading recipients…</p> : searchError ? <p role="alert" className="p-4 text-sm text-rose-600">{searchError} <button type="button" className="underline" onClick={() => setReload(v => v + 1)}>Retry</button></p> : !users.length ? <p className="p-4 text-sm text-slate-500">No eligible users found.</p> : users.map(user => {
            const checked = selected.some(item => item._id === user._id)
            return <label key={user._id} className="flex cursor-pointer items-start gap-3 border-b border-slate-100 p-3 last:border-0 hover:bg-slate-50"><input type="checkbox" className="mt-1 accent-violet-600" checked={checked} disabled={sending || (!checked && selected.length >= 100)} onChange={() => setSelected(old => checked ? old.filter(item => item._id !== user._id) : [...old, user])} /><span className="min-w-0"><span className="block text-sm font-medium">{user.firstname} {user.lastname}</span><span className="block break-all text-xs text-slate-500">{user.email}</span></span></label>
          })}
        </div>
        <div className="mt-2 flex gap-3 text-xs text-violet-700"><button type="button" disabled={!cursor || loading || sending} className="disabled:opacity-40" onClick={() => setCursor('')}>First page</button><button type="button" disabled={!next || loading || sending} className="disabled:opacity-40" onClick={() => { if (next) setCursor(next) }}>More users</button></div>
      </div>
      <div className="space-y-4"><label className="block text-sm font-medium">Title<input required maxLength={150} value={title} disabled={sending} onChange={e => setTitle(e.target.value)} placeholder="e.g. New service update" className={input} /></label><label className="block text-sm font-medium">Message<textarea required rows={5} maxLength={1000} value={message} disabled={sending} onChange={e => setMessage(e.target.value)} placeholder="Write the notification users will see" className={input} /><span className="mt-1 block text-right text-xs font-normal text-slate-500">{message.length}/1000</span></label>
        <button type="submit" disabled={sending || !selected.length || !title.trim() || !message.trim()} className="rounded-xl bg-violet-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-violet-700 disabled:cursor-not-allowed disabled:opacity-50">{sending ? 'Sending…' : `Send to ${selected.length} user${selected.length === 1 ? '' : 's'}`}</button>
        {sendError && <p role="alert" className="text-sm text-rose-600">{sendError}</p>}{success && <p role="status" className="rounded-xl bg-emerald-50 p-3 text-sm text-emerald-800">{success}</p>}
      </div>
    </form>
  </section>
}

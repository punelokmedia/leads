import { API_BASE_URL } from '@/config/api'
import { TicketsPanel } from './TicketsPanel'
import { useCallback, useEffect, useRef, useState } from 'react'

type Message = { _id: string; text: string; sender: string; createdAt: string; authorName?: string; readAt?: string }
type Thread = { _id: string; text: string; sender: string; updatedAt: string; customerName?: string; unreadCount?: number }
const base = `${API_BASE_URL}/api/v1/support/admin`
async function request<T>(path: string, body?: object): Promise<T> {
  const token = JSON.parse(localStorage.getItem('admin_auth_session') ?? '{}').token
  const response = await fetch(`${base}${path}`, {
    signal: AbortSignal.timeout(15000),
    cache: 'no-store',
    method: body ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  })
  const payload = await response.json()
  if (!response.ok || !payload.success) throw new Error(payload.message ?? 'Support request failed')
  return payload.data
}

export function SupportPage() {
  const [threads, setThreads] = useState<Thread[]>([])
  const [selected, setSelected] = useState('')
  const [messages, setMessages] = useState<Message[]>([])
  const [text, setText] = useState('')
  const [error, setError] = useState('')
  const [sending, setSending] = useState(false)
  const [page, setPage] = useState(1)
  const [hasOlder, setHasOlder] = useState(false)
  const [loadingOlder, setLoadingOlder] = useState(false)
  const activeConversation = useRef('')
  const pending = useRef({ text: '', user: '', id: '' })
  const refresh = useCallback(async () => {
    try { setThreads(await request<Thread[]>(`/threads?page=${page}`)); setError('') }
    catch { setError('Could not load support inbox. Please retry.') }
  }, [page])
  useEffect(() => {
    void refresh()
    const timer = setInterval(() => { if (document.visibilityState !== 'hidden') void refresh() }, 10000)
    return () => clearInterval(timer)
  }, [refresh])
  useEffect(() => {
    if (!selected) return
    let active = true
    let fetching = false
    let initialized = false
    const load = async () => {
      if (fetching || document.visibilityState === 'hidden') return
      fetching = true
      try {
        const rows = await request<Message[]>(`/messages/${selected}`)
        if (active) {
          setMessages(old => [...new Map([...old, ...rows].map(m => [m._id, m])).values()].sort((a, b) => a._id.localeCompare(b._id)))
          if (!initialized) { setHasOlder(rows.length === 100); initialized = true }
          if (rows.length) await request(`/read/${selected}`, { through: rows.at(-1)!._id })
          if (active) setError('')
        }
      } catch { if (active) setError('Could not load messages. Please retry.') }
      finally { fetching = false }
    }
    void load()
    const timer = setInterval(() => { void load() }, 15000)
    return () => { active = false; clearInterval(timer) }
  }, [selected])
  async function older() {
    if (!messages.length || loadingOlder) return
    const conversation = selected
    setLoadingOlder(true)
    try {
      const rows = await request<Message[]>(`/messages/${conversation}?before=${messages[0]._id}`)
      if (activeConversation.current !== conversation) return
      setMessages(old => [...new Map([...rows, ...old].map(m => [m._id, m])).values()].sort((a, b) => a._id.localeCompare(b._id)))
      setHasOlder(rows.length === 100)
    } catch { setError('Could not load older messages. Please retry.') }
    finally { setLoadingOlder(false) }
  }
  async function send() {
    const value = text.trim()
    if (!value || sending || !selected) return
    if (pending.current.text !== value || pending.current.user !== selected) pending.current = { text: value, user: selected, id: crypto.randomUUID() }
    setSending(true)
    try {
      const row = await request<Message>(`/messages/${selected}`, { text: value, clientId: pending.current.id })
      setMessages(old => old.some(m => m._id === row._id) ? old : [...old, row])
      setText(''); pending.current = { text: '', user: '', id: '' }; setError('')
      await refresh()
    } catch { setError('Reply not confirmed. Retry to send the same reply safely.') }
    finally { setSending(false) }
  }
  return <section className="space-y-4 p-6">
    <h1 className="text-2xl font-bold">Support inbox</h1>
    <TicketsPanel />
    <button onClick={() => void refresh()}>Refresh inbox</button>
    {error && <p role="alert" className="text-red-600">{error}</p>}
    <div className="grid gap-6 md:grid-cols-2">
      <div className="space-y-3">
        {!threads.length && <p>No support conversations on this page.</p>}
        {threads.map(t => <button disabled={sending} className="block w-full rounded border p-3 text-left" key={t._id} onClick={() => { activeConversation.current = t._id; setSelected(t._id); setMessages([]); setText(''); setHasOlder(false) }}>
          <strong>{t.customerName || 'Customer'}</strong> {!!t.unreadCount && <span className="rounded bg-violet-100 px-2 text-violet-800">{t.unreadCount} unread</span>}<p>{t.text}</p><small>{t.sender === 'user' ? 'Customer message' : 'Support replied'} · {new Date(t.updatedAt).toLocaleString()}</small>
        </button>)}
        <button disabled={page === 1} onClick={() => setPage(p => p - 1)}>Previous</button> <span>Page {page}</span> <button disabled={threads.length < 50} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>
      {selected && <div className="space-y-3">
        <h2 className="font-bold">Conversation</h2>
        <p className="text-sm">Replies refresh automatically while this page is open.</p>{hasOlder && <button disabled={loadingOlder} onClick={() => void older()}>{loadingOlder ? 'Loading...' : 'Load earlier messages'}</button>}
        <div className="max-h-96 space-y-2 overflow-y-auto">{messages.map(m => <div className="rounded border p-3" key={m._id}><strong>{m.authorName || (m.sender === 'user' ? 'Customer' : 'Support representative')}: </strong>{m.text}<p className="text-xs">{new Date(m.createdAt).toLocaleString()}{m.sender === 'support' ? (m.readAt ? ' - Read by customer' : ' - Sent') : ''}</p></div>)}</div>
        <textarea aria-label="Support reply" className="w-full rounded border p-3" value={text} disabled={sending} maxLength={2000} onChange={e => setText(e.target.value)} />
        <button disabled={sending || !text.trim()} onClick={() => void send()}>{sending ? 'Sending…' : 'Send reply'}</button>
      </div>}
    </div>
  </section>
}

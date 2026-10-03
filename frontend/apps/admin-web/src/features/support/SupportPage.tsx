import { API_BASE_URL } from '@/config/api'
import { useCallback, useEffect, useRef, useState } from 'react'

type Message = { _id: string; text: string; sender: string; createdAt: string }
type Thread = { _id: string; text: string; sender: string; updatedAt: string }
const base = `${API_BASE_URL}/api/v1/support/admin`
async function request<T>(path: string, body?: object): Promise<T> {
  const token = JSON.parse(localStorage.getItem('admin_auth_session') ?? '{}').token
  const response = await fetch(`${base}${path}`, {
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
  const pending = useRef({ text: '', user: '', id: '' })
  const refresh = useCallback(async () => {
    try { setThreads(await request<Thread[]>(`/threads?page=${page}`)); setError('') }
    catch { setError('Could not load support inbox. Please retry.') }
  }, [page])
  useEffect(() => { void refresh() }, [refresh])
  useEffect(() => {
    if (!selected) return
    let active = true
    const load = async () => {
      try {
        const rows = await request<Message[]>(`/messages/${selected}`)
        if (active) setMessages(rows)
      } catch { if (active) setError('Could not load messages. Please retry.') }
    }
    void load()
    const timer = setInterval(() => { void load() }, 15000)
    return () => { active = false; clearInterval(timer) }
  }, [selected])
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
    <button onClick={() => void refresh()}>Refresh inbox</button>
    {error && <p role="alert" className="text-red-600">{error}</p>}
    <div className="grid gap-6 md:grid-cols-2">
      <div className="space-y-3">
        {!threads.length && <p>No support conversations on this page.</p>}
        {threads.map(t => <button disabled={sending} className="block w-full rounded border p-3 text-left" key={t._id} onClick={() => { setSelected(t._id); setMessages([]); setText('') }}>
          <strong>User {t._id}</strong><p>{t.text}</p><small>{t.sender === 'user' ? 'Customer message' : 'Support replied'} · {new Date(t.updatedAt).toLocaleString()}</small>
        </button>)}
        <button disabled={page === 1} onClick={() => setPage(p => p - 1)}>Previous</button> <span>Page {page}</span> <button disabled={threads.length < 50} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>
      {selected && <div className="space-y-3">
        <h2 className="font-bold">Conversation</h2>
        <p className="text-sm">Latest 100 messages</p>
        <div className="max-h-96 space-y-2 overflow-y-auto">{messages.map(m => <div className="rounded border p-3" key={m._id}><strong>{m.sender === 'user' ? 'Customer' : 'Support'}: </strong>{m.text}<p className="text-xs">{new Date(m.createdAt).toLocaleString()}</p></div>)}</div>
        <textarea aria-label="Support reply" className="w-full rounded border p-3" value={text} disabled={sending} maxLength={2000} onChange={e => setText(e.target.value)} />
        <button disabled={sending || !text.trim()} onClick={() => void send()}>{sending ? 'Sending…' : 'Send reply'}</button>
      </div>}
    </div>
  </section>
}

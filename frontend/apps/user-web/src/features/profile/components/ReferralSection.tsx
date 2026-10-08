import { useState } from 'react'

const code = 'NEXTDEMO50'
const link = `https://example.com/r/${code}`
const message = `Join NextLeads using my referral code ${code}: ${link} (preview link)`

export function ReferralSection({ initiallyOpen = false }: { initiallyOpen?: boolean }) {
  const [open, setOpen] = useState(initiallyOpen)
  const [notice, setNotice] = useState('')
  const copy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text)
      setNotice('Copied to clipboard.')
    } catch {
      setNotice('Unable to copy. Select and copy the link below.')
    }
  }
  const share = async () => {
    if (!navigator.share) return copy(message)
    try {
      await navigator.share({ title: 'NextLeads referral preview', text: message })
      setNotice('Share menu opened.')
    } catch (error) {
      if (!(error instanceof DOMException && error.name === 'AbortError')) {
        setNotice('Sharing unavailable. Use Copy link instead.')
      }
    }
  }
  return (
    <section className="rounded-2xl border border-violet-200 bg-white p-4 text-stone-800">
      <button type="button" aria-expanded={open} aria-controls="referral-details" onClick={() => setOpen(!open)} className="flex w-full items-center justify-between gap-3 text-left">
        <span><span className="block text-lg font-bold text-violet-800">Refer & Earn</span><span className="text-sm text-stone-600">Invite friends. Earn credit for leads.</span></span>
        <span aria-hidden="true" className="text-2xl text-violet-700">{open ? '−' : '+'}</span>
      </button>
      {open && <div id="referral-details" className="mt-4 space-y-4">
        <p className="rounded-lg bg-amber-50 p-3 text-xs text-amber-900">Frontend preview · Sample code, link and rewards. Invites are not tracked and no wallet credit is issued.</p>
        <div className="rounded-xl bg-violet-50 p-4"><h3 className="text-xl font-bold text-violet-900">Grow together. Earn ₹50.</h3><p className="mt-2 text-sm">Sample offer: earn ₹50 in wallet credit when a friend completes their first paid lead purchase.</p></div>
        <div className="grid grid-cols-3 gap-2 text-center">{[['Invited', '3'], ['Qualified', '2'], ['Rewards', '₹100']].map(([label, value]) => <div key={label} className="rounded-xl border border-stone-200 p-2"><p className="text-lg font-bold">{value}</p><p className="text-xs text-stone-600">{label}</p></div>)}</div>
        <div><p className="text-xs font-semibold text-stone-600">Sample referral code</p><div className="mt-1 flex items-center justify-between gap-2 rounded-xl border border-dashed border-violet-300 p-3"><strong className="tracking-widest">{code}</strong><button type="button" onClick={() => void copy(code)} className="text-sm font-semibold text-violet-700">Copy code</button></div></div>
        <label className="block text-xs font-semibold text-stone-600">Sample referral link<input aria-label="Sample referral link" readOnly value={link} className="mt-1 w-full rounded-lg border border-stone-200 bg-stone-50 p-3 text-sm font-normal" onFocus={event => event.target.select()} /></label>
        <div className="flex flex-wrap gap-2"><button type="button" onClick={() => void copy(link)} className="rounded-xl bg-violet-700 px-4 py-2 text-sm font-semibold text-white">Copy link</button><a href={`https://wa.me/?text=${encodeURIComponent(message)}`} target="_blank" rel="noopener noreferrer" className="rounded-xl bg-green-700 px-4 py-2 text-sm font-semibold text-white">WhatsApp</a><button type="button" onClick={() => void share()} className="rounded-xl border border-stone-300 px-4 py-2 text-sm font-semibold">More options</button></div>
        <p role="status" className="text-sm text-violet-700">{notice}</p>
        <div><h3 className="font-bold">How it works</h3><ol className="mt-2 list-inside list-decimal space-y-2 text-sm text-stone-600"><li>Share your referral link with a friend.</li><li>Your friend joins and buys their first lead.</li><li>Your reward is added to your wallet for lead purchases.</li></ol></div>
        <div><h3 className="font-bold">Sample referral activity</h3>{[['Friend A', 'First purchase completed', '+₹50'], ['Friend B', 'First purchase completed', '+₹50'], ['Friend C', 'Awaiting first purchase', 'Pending']].map(([name, detail, reward]) => <div key={name} className="mt-2 flex items-center justify-between gap-2 border-t border-stone-100 pt-3 text-sm"><div><p className="font-semibold">{name}</p><p className="text-xs text-stone-600">{detail}</p></div><span className="font-semibold text-violet-700">{reward}</span></div>)}</div>
        <p className="text-xs text-stone-500">Sample rules: one reward per new account, no self-referrals. Referral credit is for lead purchases and cannot be withdrawn. Final rewards and rules will be confirmed at launch.</p>
      </div>}
    </section>
  )
}

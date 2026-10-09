import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ReferralCard } from '@/components/layout/ReferralCard'

export function ReferralSection({ initiallyOpen = false }: { initiallyOpen?: boolean }) {
  const [open, setOpen] = useState(initiallyOpen)
  const token = localStorage.getItem('user_token')
  return <section className="rounded-2xl border border-violet-200 bg-white p-4 text-stone-800">
    <button type="button" aria-expanded={open} aria-controls="referral-details" onClick={() => setOpen(!open)} className="flex w-full items-center justify-between gap-3 text-left">
      <span className="text-lg font-bold text-violet-800">Invite friends</span>
      <span aria-hidden="true">{open ? '?' : '+'}</span>
    </button>
    {open && <div id="referral-details">
      {token ? <ReferralCard token={token} /> : <p className="mt-4"><Link to="/auth/mobile" className="font-semibold text-violet-700">Sign in to get your referral code</Link></p>}
    </div>}
  </section>
}

import { useEffect, useState } from 'react'
import { API_BASE_URL } from '@/config/api'

type ReferralSummary = { referralCode: string; referralLink: string; appDownloadLink?: string | null; invited: number; qualified: number; pending: number }

export function ReferralCard({ token }: { token: string }) {
  const [data, setData] = useState<ReferralSummary | null>(null)
  const [error, setError] = useState('')
  const [copied, setCopied] = useState(false)
  const [reload, setReload] = useState(0)
  useEffect(() => {
    const controller = new AbortController()
    setData(null)
    setError('')
    setCopied(false)
    void (async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/api/v1/referrals/me`, {
          headers: { Authorization: `Bearer ${token}` }, signal: controller.signal,
        })
        const body = await response.json()
        if (!response.ok || body.success !== true) throw new Error(body.message || 'Unable to load referrals.')
        if (!controller.signal.aborted) setData(body.data)
      } catch (cause) {
        if (!controller.signal.aborted) setError(cause instanceof Error ? cause.message : 'Unable to load referrals.')
      }
    })()
    return () => controller.abort()
  }, [token, reload])
  return <section className="my-4 rounded-xl border border-stone-200 p-4">
    <h3 className="font-semibold">Invite friends</h3>
    {error ? <div role="alert">{error} <button type="button" onClick={() => setReload(value => value + 1)}>Retry</button></div>
      : !data ? <p>Loading referrals…</p> : <>
        <p className="mt-2 text-sm">Share your code. Your friend can enter it during profile setup.</p>
        <p className="my-2 break-all font-mono select-all">{data.referralCode}</p>
        <button type="button" className="text-sm font-semibold text-purple-700" onClick={async () => {
          try { await navigator.clipboard.writeText(data.referralCode); setCopied(true) }
          catch { setError('Unable to copy. Select the code to copy it.') }
        }}>{copied ? 'Copied' : 'Copy code'}</button>
        <p className="my-2 break-all text-sm"><a href={data.referralLink}>{data.referralLink}</a></p>
        <button type="button" className="text-sm font-semibold text-purple-700" onClick={async () => {
          try { await navigator.clipboard.writeText(data.referralLink); setCopied(true) }
          catch { setError('Unable to copy. Select the link to copy it.') }
        }}>Copy invitation link</button>
        {data.appDownloadLink && <p className="mt-2"><a href={data.appDownloadLink} target="_blank" rel="noopener noreferrer">Download app</a></p>}
        {!data.appDownloadLink && <p className="mt-2 text-sm text-stone-500">Download app — coming soon (preview)</p>}
        <p className="mt-2 text-sm">Invited: {data.invited} · Qualified: {data.qualified} · Pending: {data.pending}</p>
      </>}
  </section>
}

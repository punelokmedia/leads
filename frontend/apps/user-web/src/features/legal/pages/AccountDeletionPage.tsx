import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'

export function AccountDeletionPage() {
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (pending) return
    const form = event.currentTarget
    const data = new FormData(form)
    const phoneNumber = String(data.get('phoneNumber') || '').trim()
    if (!/^\+?[\d\s()-]+$/.test(phoneNumber) || !/^\+?\d{7,15}$/.test(phoneNumber.replace(/[\s()-]/g, ''))) {
      setError('Enter a valid phone number (7–15 digits).')
      return
    }
    setPending(true)
    setError('')
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/account-deletion-requests`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: data.get('email'), phoneNumber: data.get('phoneNumber'), reason: data.get('reason') }),
        signal: AbortSignal.timeout(20000),
      })
      const result = await response.json()
      if (!response.ok || !result.success) throw new Error(result.message || 'Unable to submit your request.')
      setSuccess(`${result.message} Reference: ${result.requestId}`)
      form.reset()
    } catch (failure) {
      setError(failure instanceof Error && failure.name !== 'TimeoutError' ? failure.message : 'Unable to submit your request. Please try again.')
    } finally {
      setPending(false)
    }
  }
  const fieldClass = 'mt-2 w-full rounded-lg border border-stone-300 px-3 py-3 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]'
  return (
    <main className="bg-[#efefef] px-4 py-14 sm:px-6">
      <section className="mx-auto max-w-2xl rounded-2xl border border-stone-300 bg-white p-6 shadow-sm sm:p-10">
        <h1 className="text-3xl font-black text-stone-900">Request account deletion</h1>
        <p className="mt-4 text-stone-600">To request deletion of your NextLeads account and associated personal information, enter the email and phone number associated with your account. You do not need to sign in.</p>
        <p className="mt-3 text-sm text-stone-600">We will verify account ownership before processing your request. Submitting this form does not immediately delete your account. Some records may be retained for legal, accounting, security or dispute resolution purposes, as described in our <Link to="/privacy-policy" className="font-semibold underline">Privacy Policy</Link>.</p>
        {success ? <p role="status" className="mt-6 rounded-lg bg-green-50 p-4 text-green-800">{success}</p> : (
          <form onSubmit={submit} className="mt-6 space-y-5">
            <fieldset disabled={pending} className="space-y-5 disabled:opacity-70">
              <label className="block text-sm font-semibold text-stone-700">Email address
                <input name="email" type="email" autoComplete="email" required maxLength={254} className={fieldClass} />
              </label>
              <label className="block text-sm font-semibold text-stone-700">Phone number
                <input name="phoneNumber" type="tel" autoComplete="tel" required maxLength={30} placeholder="Include your country code" className={fieldClass} />
              </label>
              <label className="block text-sm font-semibold text-stone-700">Why are you leaving? (optional)
                <textarea name="reason" rows={5} maxLength={2000} placeholder="Tell us your reason for leaving NextLeads" className={fieldClass} />
              </label>
              <button type="submit" className="rounded-xl bg-[#F8B020] px-5 py-3 font-semibold text-stone-900 hover:bg-[#E2A11D]">{pending ? 'Submitting…' : 'Submit deletion request'}</button>
            </fieldset>
            {error && <p role="alert" className="text-sm text-red-700">{error}</p>}
          </form>
        )}
      </section>
    </main>
  )
}

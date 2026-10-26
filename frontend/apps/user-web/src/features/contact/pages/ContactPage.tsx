import { useRef, useState, type FormEvent } from 'react'
import { API_BASE_URL } from '@/config/api'
import { apiFetch } from '@/features/auth/session'
import { Link } from 'react-router-dom'

const contactCards = [
  { title: 'Call us', value: '+91 9067777034', note: 'Mon-Sat, 10:00 AM - 7:00 PM' },
  { title: 'Email us', value: 'info@trynextleads.com', note: 'We reply within 2-4 hours' },
  { title: 'Office', value: 'Clevor Hills Plaza 1019, Pune', note: 'India' },
]

const faqs = [
  {
    question: 'How quickly will I receive leads?',
    answer: 'Most active plans start receiving qualified leads within the same day.',
  },
  {
    question: 'Can I choose my target city and budget?',
    answer: 'Yes. You can configure city preference, project type, and budget bands.',
  },
  {
    question: 'Do you verify every enquiry?',
    answer: 'Yes. Our operations team verifies lead intent before publishing.',
  },
]

export function ContactPage() {
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const inFlight = useRef(false)
  const requestId = useRef<string | null>(null)
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (inFlight.current) return
    const form = event.currentTarget
    const values = new FormData(form)
    requestId.current ??= crypto.randomUUID()
    const body = Object.fromEntries(['name','phone','email','city','message'].map(key => [key, String(values.get(key) || '').trim()]))
    inFlight.current = true; setPending(true); setError(''); setSuccess('')
    try {
      const response = await apiFetch(`${API_BASE_URL}/api/v1/contact`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ...body, requestId: requestId.current }), signal: AbortSignal.timeout(20000) })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to send your enquiry.')
      setSuccess(`Your enquiry has been received. Reference: ${payload.data.reference}. Our team will contact you.`)
      form.reset(); requestId.current = null
    } catch (failure) { setError(failure instanceof Error && failure.name !== 'TimeoutError' ? failure.message : 'Unable to confirm submission. Retry with the same details or call +91 9067777034.') }
    finally { inFlight.current = false; setPending(false) }
  }
  return (
    <div className="bg-[#f8fafc]">
      <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#0066ff] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Contact Us
        </p>
        <h1 className="mt-3 max-w-4xl text-4xl font-black leading-tight text-stone-900 sm:text-6xl">
          Let&apos;s grow your business together.
        </h1>
        <p className="mt-4 max-w-3xl text-base text-stone-600">
          Share your city and requirement. Our team will help you choose the
          right lead plan and onboard you quickly.
        </p>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-8 sm:px-6">
        <div className="grid gap-4 md:grid-cols-3">
          {contactCards.map((item) => (
            <article
              key={item.title}
              className="rounded-2xl border border-stone-300 bg-white p-5 shadow-sm"
            >
              <p className="text-sm font-semibold text-stone-500">{item.title}</p>
              <p className="mt-1 text-lg font-bold text-stone-900">{item.value}</p>
              <p className="mt-1 text-xs text-stone-500">{item.note}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
          <form
            className="rounded-3xl border border-stone-300 bg-white p-6 shadow-sm sm:p-8"
            onSubmit={event => void submit(event)}
          >
            <h2 className="text-2xl font-black text-stone-900">Send us a message</h2>
            <p className="mt-1 text-sm text-stone-600">
              We usually respond on the same business day.
            </p>

            <div className="mt-6 grid gap-4 sm:grid-cols-2">
              <label className="block text-sm font-medium text-stone-700">
                Full name
                <input
                  type="text"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                  name="name" required maxLength={100} disabled={pending} placeholder="Jane Doe"
                />
              </label>
              <label className="block text-sm font-medium text-stone-700">
                Phone
                <input
                  type="tel"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                  name="phone" required maxLength={20} disabled={pending} placeholder="+91 98765 43210"
                />
              </label>
            </div>

            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              <label className="block text-sm font-medium text-stone-700">
                Email
                <input
                  type="email"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                  name="email" required maxLength={254} disabled={pending} placeholder="you@company.com"
                />
              </label>
              <label className="block text-sm font-medium text-stone-700">
                City
                <input
                  type="text"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                  name="city" required maxLength={100} disabled={pending} placeholder="Bengaluru"
                />
              </label>
            </div>

            <label className="mt-4 block text-sm font-medium text-stone-700">
              Message
              <textarea
                rows={5}
                className="mt-1.5 w-full resize-y rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                name="message" required maxLength={5000} disabled={pending} placeholder="Tell us about your lead requirement..."
              />
            </label>

            <button
              type="submit" disabled={pending} aria-busy={pending}
              className="mt-5 rounded-xl bg-[#0066ff] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#0050cb]"
            >
              {pending ? 'Sending…' : 'Submit enquiry'}
            </button>
            {error && <p role="alert" className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</p>}
            {success && <p role="status" className="mt-4 rounded-lg bg-emerald-50 p-3 text-sm text-emerald-700">{success}</p>}
          </form>

          <aside className="rounded-3xl border border-stone-300 bg-white p-6 shadow-sm sm:p-8">
            <h2 className="text-2xl font-black text-stone-900">Frequently asked</h2>
            <div className="mt-5 space-y-4">
              {faqs.map((faq) => (
                <article key={faq.question}>
                  <h3 className="text-sm font-semibold text-stone-900">{faq.question}</h3>
                  <p className="mt-1 text-sm text-stone-600">{faq.answer}</p>
                </article>
              ))}
            </div>

            <div className="mt-7 rounded-2xl bg-stone-100 p-4">
              <p className="text-sm font-semibold text-stone-900">Prefer WhatsApp?</p>
              <p className="mt-1 text-xs text-stone-600">
                Connect instantly for quick onboarding.
              </p>
              <a
                href="https://wa.me/919067777034?text=Hi%2C%20I%20want%20to%20know%20more%20about%20interior%20design%20leads."
                target="_blank"
                rel="noreferrer"
                className="mt-3 inline-flex rounded-xl bg-[#25D366] px-4 py-2 text-xs font-semibold text-white transition hover:bg-[#1eb95b]"
              >
                Chat on WhatsApp
              </a>
            </div>
          </aside>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-14 sm:px-6">
        <div className="rounded-3xl border border-stone-300 bg-stone-900 p-7 text-white shadow-sm sm:p-10">
          <h2 className="text-3xl font-black">Want to explore leads first?</h2>
          <p className="mt-2 max-w-2xl text-sm text-stone-200 sm:text-base">
            Browse available categories, compare lead quality, then reach out when
            you are ready to scale.
          </p>
          <Link
            to="/"
            className="mt-5 inline-flex rounded-xl bg-[#0066ff] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#0050cb]"
          >
            Go to Home
          </Link>
        </div>
      </section>
    </div>
  )
}

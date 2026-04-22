import { Link } from 'react-router-dom'

const contactCards = [
  { title: 'Call us', value: '+91 62058 78945', note: 'Mon-Sat, 10:00 AM - 7:00 PM' },
  { title: 'Email us', value: 'support@interiorwala.com', note: 'We reply within 2-4 hours' },
  { title: 'Office', value: 'Bengaluru, Karnataka', note: 'India' },
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
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Contact Us
        </p>
        <h1 className="mt-3 max-w-4xl text-4xl font-black leading-tight text-stone-900 sm:text-6xl">
          Let&apos;s grow your interior business together.
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
            onSubmit={(e) => {
              e.preventDefault()
            }}
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
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                  placeholder="Jane Doe"
                />
              </label>
              <label className="block text-sm font-medium text-stone-700">
                Phone
                <input
                  type="tel"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                  placeholder="+91 98765 43210"
                />
              </label>
            </div>

            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              <label className="block text-sm font-medium text-stone-700">
                Email
                <input
                  type="email"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                  placeholder="you@company.com"
                />
              </label>
              <label className="block text-sm font-medium text-stone-700">
                City
                <input
                  type="text"
                  className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                  placeholder="Bengaluru"
                />
              </label>
            </div>

            <label className="mt-4 block text-sm font-medium text-stone-700">
              Message
              <textarea
                rows={5}
                className="mt-1.5 w-full resize-y rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                placeholder="Tell us about your lead requirement..."
              />
            </label>

            <button
              type="submit"
              className="mt-5 rounded-xl bg-[#F8B020] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#E2A11D]"
            >
              Submit enquiry
            </button>
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
                href="https://wa.me/916205878945?text=Hi%2C%20I%20want%20to%20know%20more%20about%20interior%20design%20leads."
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
            className="mt-5 inline-flex rounded-xl bg-[#F8B020] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#E2A11D]"
          >
            Go to Home
          </Link>
        </div>
      </section>
    </div>
  )
}

import { Link } from 'react-router-dom'

const stats = [
  { label: 'Verified leads delivered', value: '25,000+' },
  { label: 'Cities covered', value: '30+' },
  { label: 'Design partners', value: '1,200+' },
  { label: 'Avg. response time', value: '< 15 min' },
]

const values = [
  {
    title: 'Human-verified quality',
    description:
      'Every enquiry is manually checked before it reaches your dashboard so you focus only on high-intent projects.',
  },
  {
    title: 'Transparent lead matching',
    description:
      'We match leads by budget, location, and project stage to reduce wasted follow-ups and improve conversions.',
  },
  {
    title: 'Growth-focused support',
    description:
      'From onboarding to optimization, our team helps you improve closure rate and customer experience.',
  },
]

const processSteps = [
  'Tell us your preferred city, project type, and budget band.',
  'Get curated leads that match your ideal customer profile.',
  'Track conversions, refill credits, and scale confidently.',
]

export function PricingPage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          About Interiorwala
        </p>
        <h1 className="mt-3 max-w-4xl text-4xl font-black leading-tight text-stone-900 sm:text-6xl">
          Built to help interior designers grow with reliable, ready-to-convert
          leads.
        </h1>
        <p className="mt-5 max-w-3xl text-base leading-relaxed text-stone-600">
          Interiorwala is a lead platform focused on quality over volume. We
          verify enquiries, qualify intent, and connect design professionals with
          serious buyers.
        </p>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-10 sm:px-6">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
            <article
              key={stat.label}
              className="rounded-2xl border border-stone-300 bg-white p-5 shadow-sm"
            >
              <p className="text-3xl font-black text-stone-900">{stat.value}</p>
              <p className="mt-1 text-sm text-stone-600">{stat.label}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <h2 className="text-3xl font-black text-stone-900">Why teams choose us</h2>
        <div className="mt-6 grid gap-5 lg:grid-cols-3">
          {values.map((value) => (
            <article
              key={value.title}
              className="rounded-2xl border border-stone-300 bg-white p-6 shadow-sm"
            >
              <h3 className="text-xl font-bold text-stone-900">{value.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-stone-600">
                {value.description}
              </p>
            </article>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="rounded-3xl border border-stone-300 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-3xl font-black text-stone-900">How it works</h2>
          <ol className="mt-6 space-y-4">
            {processSteps.map((step, index) => (
              <li key={step} className="flex items-start gap-3">
                <span className="mt-0.5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#F8B020] text-xs font-bold text-white">
                  {index + 1}
                </span>
                <p className="text-sm text-stone-700">{step}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-14 sm:px-6">
        <div className="rounded-3xl border border-stone-300 bg-stone-900 p-7 text-white shadow-sm sm:p-10">
          <h2 className="text-3xl font-black">Ready to scale your design business?</h2>
          <p className="mt-3 max-w-2xl text-sm text-stone-200 sm:text-base">
            Talk to our team and get a lead plan designed for your city,
            category, and growth goals.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link
              to="/contact"
              className="rounded-xl bg-[#F8B020] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#E2A11D]"
            >
              Talk to Sales
            </Link>
            <Link
              to="/"
              className="rounded-xl border border-stone-400 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-stone-800"
            >
              Explore Leads
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}

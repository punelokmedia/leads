type Tier = {
  name: string
  price: string
  desc: string
  features: string[]
  highlighted?: boolean
}

const tiers: Tier[] = [
  {
    name: 'Starter',
    price: '$29',
    desc: 'For small teams testing demand.',
    features: ['Up to 500 leads / mo', 'Email support', 'CSV export'],
  },
  {
    name: 'Growth',
    price: '$99',
    desc: 'For teams scaling acquisition.',
    features: ['Up to 5k leads / mo', 'API access', 'Priority support'],
    highlighted: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    desc: 'Volume, SLA, and compliance.',
    features: ['Unlimited leads', 'Dedicated CSM', 'Custom contracts'],
  },
]

export function PricingPage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <div className="text-center">
        <h1 className="text-3xl font-semibold tracking-tight text-stone-900 sm:text-4xl">
          Simple pricing
        </h1>
        <p className="mx-auto mt-3 max-w-lg text-stone-600">
          Placeholder tiers — replace with your billing integration.
        </p>
      </div>
      <div className="mt-12 grid gap-6 lg:grid-cols-3">
        {tiers.map((tier) => (
          <div
            key={tier.name}
            className={[
              'flex flex-col rounded-2xl border p-8',
              tier.highlighted
                ? 'border-emerald-500 bg-emerald-50/50 shadow-md ring-1 ring-emerald-500/20'
                : 'border-stone-200 bg-white',
            ].join(' ')}
          >
            <h2 className="text-lg font-semibold text-stone-900">{tier.name}</h2>
            <p className="mt-1 text-sm text-stone-600">{tier.desc}</p>
            <p className="mt-6 text-3xl font-semibold tabular-nums text-stone-900">
              {tier.price}
              {tier.price.startsWith('$') && (
                <span className="text-base font-normal text-stone-500">/mo</span>
              )}
            </p>
            <ul className="mt-6 flex-1 space-y-2 text-sm text-stone-600">
              {tier.features.map((f) => (
                <li key={f} className="flex gap-2">
                  <span className="text-emerald-600">✓</span>
                  {f}
                </li>
              ))}
            </ul>
            <button
              type="button"
              className={[
                'mt-8 w-full rounded-xl py-2.5 text-sm font-semibold',
                tier.highlighted
                  ? 'bg-emerald-600 text-white hover:bg-emerald-500'
                  : 'border border-stone-300 bg-white text-stone-900 hover:bg-stone-50',
              ].join(' ')}
            >
              Get started
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}

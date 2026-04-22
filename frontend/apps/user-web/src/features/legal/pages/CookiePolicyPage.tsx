const cookieTypes = [
  {
    type: 'Essential cookies',
    details: 'Required for core navigation, account sessions, and secure platform access.',
  },
  {
    type: 'Performance cookies',
    details: 'Help us understand how users interact so we can improve speed and usability.',
  },
  {
    type: 'Preference cookies',
    details: 'Store selected settings such as location preference and interface choices.',
  },
  {
    type: 'Analytics tools',
    details: 'Used in aggregate form to measure engagement and improve campaign outcomes.',
  },
]

export function CookiePolicyPage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-5xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Legal
        </p>
        <h1 className="mt-3 text-4xl font-black text-stone-900 sm:text-5xl">
          Cookie Policy
        </h1>
        <p className="mt-3 text-sm text-stone-600">
          This page explains what cookies we use and how they help operate Interiorwala.
        </p>
      </section>

      <section className="mx-auto max-w-5xl px-4 pb-14 sm:px-6">
        <div className="grid gap-4 sm:grid-cols-2">
          {cookieTypes.map((cookie) => (
            <article
              key={cookie.type}
              className="rounded-2xl border border-stone-300 bg-white p-6 shadow-sm"
            >
              <h2 className="text-lg font-bold text-stone-900">{cookie.type}</h2>
              <p className="mt-2 text-sm leading-relaxed text-stone-600">
                {cookie.details}
              </p>
            </article>
          ))}
        </div>
      </section>
    </div>
  )
}

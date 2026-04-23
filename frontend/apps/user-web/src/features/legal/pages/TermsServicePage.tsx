const terms = [
  {
    title: 'Account responsibilities',
    text: 'You are responsible for maintaining accurate account information and protecting your login credentials.',
  },
  {
    title: 'Permitted use',
    text: 'Services must be used only for lawful business purposes and in compliance with all applicable regulations.',
  },
  {
    title: 'Payments and credits',
    text: 'Lead credits and plan charges are governed by your selected package and applicable billing terms.',
  },
  {
    title: 'Platform availability',
    text: 'We continuously improve reliability, but temporary maintenance windows or outages may occur.',
  },
  {
    title: 'Termination',
    text: 'We may suspend accounts involved in misuse, fraud, abuse, or policy violations to protect ecosystem quality.',
  },
]

export function TermsServicePage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-5xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Legal
        </p>
        <h1 className="mt-3 text-4xl font-black text-stone-900 sm:text-5xl">
          Terms & Service
        </h1>
        <p className="mt-3 text-sm text-stone-600">
          Please read these terms carefully before using Interiorwala services.
        </p>
      </section>

      <section className="mx-auto max-w-5xl px-4 pb-14 sm:px-6">
        <div className="rounded-3xl border border-stone-300 bg-white p-6 shadow-sm sm:p-8">
          <ul className="space-y-5">
            {terms.map((term) => (
              <li key={term.title}>
                <h2 className="text-lg font-bold text-stone-900">{term.title}</h2>
                <p className="mt-1 text-sm leading-relaxed text-stone-600">{term.text}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>
    </div>
  )
}

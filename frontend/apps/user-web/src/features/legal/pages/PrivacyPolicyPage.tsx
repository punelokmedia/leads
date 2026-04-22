const sections = [
  {
    title: 'Information we collect',
    content:
      'We collect account details, contact information, lead preferences, and usage data needed to provide and improve Interiorwala services.',
  },
  {
    title: 'How we use information',
    content:
      'Your data is used to verify users, match leads, prevent misuse, provide support, send relevant updates, and improve platform performance.',
  },
  {
    title: 'Data sharing',
    content:
      'We only share limited details with trusted service providers required to operate the platform. We do not sell personal data.',
  },
  {
    title: 'Security and retention',
    content:
      'We use reasonable security controls and retain information only for operational, legal, and compliance purposes.',
  },
]

export function PrivacyPolicyPage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-5xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Legal
        </p>
        <h1 className="mt-3 text-4xl font-black text-stone-900 sm:text-5xl">
          Privacy Policy
        </h1>
        <p className="mt-3 text-sm text-stone-600">
          Last updated: {new Date().toLocaleDateString()}
        </p>
      </section>

      <section className="mx-auto max-w-5xl px-4 pb-14 sm:px-6">
        <div className="space-y-4">
          {sections.map((section) => (
            <article
              key={section.title}
              className="rounded-2xl border border-stone-300 bg-white p-6 shadow-sm"
            >
              <h2 className="text-xl font-bold text-stone-900">{section.title}</h2>
              <p className="mt-2 text-sm leading-relaxed text-stone-600">
                {section.content}
              </p>
            </article>
          ))}
        </div>
      </section>
    </div>
  )
}

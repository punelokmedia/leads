const supportChannels = [
  {
    title: 'WhatsApp Support',
    value: '+91 62058 78945',
    actionLabel: 'Chat now',
    actionHref:
      'https://wa.me/916205878945?text=Hi%2C%20I%20need%20support%20for%20my%20Interiorwala%20account.',
  },
  {
    title: 'Email Support',
    value: 'support@interiorwala.com',
    actionLabel: 'Write email',
    actionHref: 'mailto:support@interiorwala.com',
  },
]

export function ContactSupportPage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-5xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">
          Help Center
        </p>
        <h1 className="mt-3 text-4xl font-black text-stone-900 sm:text-5xl">
          Contact Support
        </h1>
        <p className="mt-3 text-sm text-stone-600">
          Need help with leads, payments, or account setup? Our support team is ready.
        </p>
      </section>

      <section className="mx-auto max-w-5xl px-4 pb-14 sm:px-6">
        <div className="grid gap-4 md:grid-cols-2">
          {supportChannels.map((channel) => (
            <article
              key={channel.title}
              className="rounded-2xl border border-stone-300 bg-white p-6 shadow-sm"
            >
              <h2 className="text-lg font-bold text-stone-900">{channel.title}</h2>
              <p className="mt-2 text-sm text-stone-600">{channel.value}</p>
              <a
                href={channel.actionHref}
                target={channel.actionHref.startsWith('http') ? '_blank' : undefined}
                rel={channel.actionHref.startsWith('http') ? 'noreferrer' : undefined}
                className="mt-4 inline-flex rounded-xl bg-[#F8B020] px-4 py-2 text-sm font-semibold text-white transition hover:bg-[#E2A11D]"
              >
                {channel.actionLabel}
              </a>
            </article>
          ))}
        </div>

        <div className="mt-6 rounded-2xl border border-stone-300 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-bold text-stone-900">Support hours</h2>
          <p className="mt-2 text-sm text-stone-600">
            Monday to Saturday: 10:00 AM - 7:00 PM (IST)
          </p>
        </div>
      </section>
    </div>
  )
}

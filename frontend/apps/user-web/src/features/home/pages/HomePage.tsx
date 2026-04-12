import { Link } from 'react-router-dom'

export function HomePage() {
  return (
    <div>
      <section className="border-b border-stone-200 bg-gradient-to-b from-emerald-50/50 to-white">
        <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-24">
          <p className="text-sm font-medium text-emerald-700">Lead marketplace</p>
          <h1 className="mt-3 max-w-2xl text-4xl font-semibold tracking-tight text-stone-900 sm:text-5xl">
            Buy and sell qualified leads with confidence.
          </h1>
          <p className="mt-4 max-w-xl text-lg text-stone-600">
            A scalable foundation for your product: public web, admin console, and
            mobile app — ready to connect to your backend.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              to="/pricing"
              className="inline-flex rounded-xl bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-emerald-500"
            >
              View pricing
            </Link>
            <Link
              to="/contact"
              className="inline-flex rounded-xl border border-stone-300 bg-white px-5 py-2.5 text-sm font-semibold text-stone-800 hover:bg-stone-50"
            >
              Talk to sales
            </Link>
          </div>
        </div>
      </section>
      <section className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
        <h2 className="text-lg font-semibold text-stone-900">Why this stack</h2>
        <ul className="mt-6 grid gap-6 sm:grid-cols-3">
          {[
            {
              title: 'Typed React',
              body: 'TypeScript + Vite + Tailwind for fast iteration and safer refactors.',
            },
            {
              title: 'Feature folders',
              body: 'Colocate routes, UI, and API hooks per domain as you grow.',
            },
            {
              title: 'Flutter app',
              body: 'Same product surface on iOS and Android under mobile/user_app.',
            },
          ].map((item) => (
            <li
              key={item.title}
              className="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm"
            >
              <h3 className="font-medium text-stone-900">{item.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-stone-600">{item.body}</p>
            </li>
          ))}
        </ul>
      </section>
    </div>
  )
}

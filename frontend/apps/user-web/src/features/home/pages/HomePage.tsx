import { Link } from 'react-router-dom'

export function HomePage() {
  const cards = [
    { city: 'Bangalore', price: 'Rs 350 per Lead', soldOut: true },
    { city: 'Mumbai', price: 'Rs 420 per Lead', soldOut: false },
    { city: 'Pune', price: 'Rs 320 per Lead', soldOut: false },
    { city: 'Delhi', price: 'Rs 400 per Lead', soldOut: false },
    { city: 'Hyderabad', price: 'Rs 340 per Lead', soldOut: false },
    { city: 'Chennai', price: 'Rs 300 per Lead', soldOut: false },
  ]

  return (
    <div className="pb-12">
      <section className="border-b border-stone-200 bg-gradient-to-b from-amber-50 to-white">
        <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 sm:py-10">
          <p className="text-xs font-bold uppercase tracking-widest text-amber-700">
            Trending Interior Leads
          </p>
          <h1 className="mt-2 text-3xl font-black tracking-tight text-stone-900 sm:text-5xl">
            Interior Leads
          </h1>
          <p className="mt-3 max-w-2xl text-sm text-stone-600 sm:text-base">
            Verified home interior inquiry leads for your city. Choose plan, add to
            cart, and start receiving customers quickly.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link
              to="/pricing"
              className="inline-flex rounded-xl bg-amber-500 px-5 py-2.5 text-sm font-semibold text-stone-900 shadow-sm hover:bg-amber-400"
            >
              Buy Leads
            </Link>
            <Link
              to="/contact"
              className="inline-flex rounded-xl border border-stone-300 bg-white px-5 py-2.5 text-sm font-semibold text-stone-800 hover:bg-stone-50"
            >
              Talk to Sales
            </Link>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {cards.map((card) => (
            <article
              key={card.city}
              className="group relative overflow-hidden rounded-xl border border-stone-300 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg"
            >
              <div className="h-52 bg-gradient-to-br from-stone-100 via-stone-50 to-amber-100 p-3">
                <div className="relative flex h-full items-center justify-center rounded-lg border border-stone-300 bg-[linear-gradient(120deg,#efefef_0%,#ffffff_45%,#ececec_100%)]">
                  <div className="rounded-xl bg-amber-200/80 px-4 py-3 text-center shadow-sm backdrop-blur">
                    <p className="text-base font-bold text-stone-900">
                      Interior Leads @ {card.city}
                    </p>
                    <p className="mt-1 text-xl font-black text-stone-900">
                      {card.price}
                    </p>
                  </div>
                  {card.soldOut ? (
                    <span className="absolute -rotate-12 rounded-md border-2 border-red-700 bg-red-600 px-4 py-1 text-sm font-black tracking-wide text-white shadow-md">
                      SOLD OUT
                    </span>
                  ) : null}
                </div>
              </div>
              <div className="space-y-3 p-4">
                <p className="text-sm text-stone-600">
                  Verified and filtered buyer leads for {card.city}. Limited daily
                  slots.
                </p>
                <button
                  type="button"
                  className="w-full rounded-lg bg-stone-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-stone-700"
                >
                  Add to Cart
                </button>
              </div>
            </article>
          ))}
        </div>

        <div className="mt-8 rounded-2xl border border-stone-200 bg-stone-50 p-5 sm:p-6">
          <h2 className="text-lg font-bold text-stone-900">
            Need custom leads package?
          </h2>
          <p className="mt-2 text-sm text-stone-600">
            Share your target city and category. Our team will prepare a custom plan
            for your budget.
          </p>
          <Link
            to="/contact"
            className="mt-4 inline-flex rounded-lg bg-amber-500 px-4 py-2 text-sm font-semibold text-stone-900 hover:bg-amber-400"
          >
            Request Custom Quote
          </Link>
        </div>
      </section>
    </div>
  )
}

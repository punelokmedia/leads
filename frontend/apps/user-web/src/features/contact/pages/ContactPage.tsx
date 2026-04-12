export function ContactPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-16 sm:px-6">
      <h1 className="text-3xl font-semibold tracking-tight text-stone-900">
        Contact
      </h1>
      <p className="mt-2 text-sm text-stone-600">
        Send a message — wire this form to your backend or form provider.
      </p>
      <form
        className="mt-8 space-y-4"
        onSubmit={(e) => {
          e.preventDefault()
        }}
      >
        <label className="block text-sm font-medium text-stone-700">
          Name
          <input
            type="text"
            className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
            placeholder="Jane Doe"
          />
        </label>
        <label className="block text-sm font-medium text-stone-700">
          Email
          <input
            type="email"
            className="mt-1.5 w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
            placeholder="you@company.com"
          />
        </label>
        <label className="block text-sm font-medium text-stone-700">
          Message
          <textarea
            rows={4}
            className="mt-1.5 w-full resize-y rounded-lg border border-stone-300 bg-white px-3 py-2 text-stone-900 outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
            placeholder="How can we help?"
          />
        </label>
        <button
          type="submit"
          className="w-full rounded-xl bg-emerald-600 py-2.5 text-sm font-semibold text-white hover:bg-emerald-500"
        >
          Submit
        </button>
      </form>
    </div>
  )
}

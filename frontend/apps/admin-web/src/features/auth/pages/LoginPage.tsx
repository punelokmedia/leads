import { Link } from 'react-router-dom'

export function LoginPage() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center bg-stone-950 px-4">
      <div className="w-full max-w-sm space-y-6 rounded-2xl border border-stone-800 bg-stone-900/60 p-8 shadow-xl">
        <div className="text-center">
          <p className="text-sm font-semibold text-white">Leads Sell</p>
          <h1 className="mt-2 text-lg font-medium text-stone-200">
            Admin sign in
          </h1>
          <p className="mt-1 text-xs text-stone-500">
            Replace with your auth flow (OAuth, magic link, etc.).
          </p>
        </div>
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <label className="block text-xs font-medium text-stone-400">
            Email
            <input
              type="email"
              autoComplete="email"
              className="mt-1.5 w-full rounded-lg border border-stone-700 bg-stone-950 px-3 py-2 text-sm text-stone-100 outline-none focus:border-violet-500"
              placeholder="you@company.com"
            />
          </label>
          <label className="block text-xs font-medium text-stone-400">
            Password
            <input
              type="password"
              autoComplete="current-password"
              className="mt-1.5 w-full rounded-lg border border-stone-700 bg-stone-950 px-3 py-2 text-sm text-stone-100 outline-none focus:border-violet-500"
            />
          </label>
          <button
            type="submit"
            className="w-full rounded-lg bg-violet-600 py-2.5 text-sm font-medium text-white hover:bg-violet-500"
          >
            Continue
          </button>
        </form>
        <p className="text-center text-xs text-stone-600">
          <Link to="/" className="text-violet-400 hover:text-violet-300">
            ← Back to dashboard
          </Link>
        </p>
      </div>
    </div>
  )
}

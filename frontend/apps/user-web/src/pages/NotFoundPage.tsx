import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center bg-white px-4 text-center">
      <p className="text-sm font-medium text-stone-500">404</p>
      <h1 className="mt-2 text-xl font-semibold text-stone-900">Page not found</h1>
      <Link
        to="/"
        className="mt-6 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-500"
      >
        Back home
      </Link>
    </div>
  )
}

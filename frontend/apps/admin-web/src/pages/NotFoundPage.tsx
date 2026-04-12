import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center bg-stone-950 px-4 text-center">
      <p className="text-sm font-medium text-stone-500">404</p>
      <h1 className="mt-2 text-xl font-semibold text-white">Page not found</h1>
      <Link
        to="/"
        className="mt-6 rounded-lg bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-500"
      >
        Go home
      </Link>
    </div>
  )
}

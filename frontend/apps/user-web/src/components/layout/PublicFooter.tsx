export function PublicFooter() {
  return (
    <footer className="border-t border-stone-200 bg-stone-50">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-10 sm:flex-row sm:items-center sm:justify-between sm:px-6">
        <p className="text-sm text-stone-500">
          © {new Date().getFullYear()} Leads Sell. All rights reserved.
        </p>
        <p className="text-xs text-stone-400">
          Public site — pair with <code className="rounded bg-stone-200 px-1">apps/admin-web</code>{' '}
          for operations.
        </p>
      </div>
    </footer>
  )
}

export function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-white">
          Dashboard
        </h1>
        <p className="mt-1 text-sm text-stone-500">
          Overview of pipelines and recent activity.
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {['New leads', 'Qualified', 'Won this month'].map((label) => (
          <div
            key={label}
            className="rounded-xl border border-stone-800 bg-stone-900/50 p-5 shadow-sm"
          >
            <p className="text-sm font-medium text-stone-400">{label}</p>
            <p className="mt-2 text-3xl font-semibold tabular-nums text-white">
              —
            </p>
            <p className="mt-1 text-xs text-stone-600">Connect your API</p>
          </div>
        ))}
      </div>
    </div>
  )
}

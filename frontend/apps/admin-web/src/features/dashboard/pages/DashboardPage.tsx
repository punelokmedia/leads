export function DashboardPage() {
  const metrics = [
    { label: 'New leads', value: '128', trend: '+14.2%', tone: 'positive' },
    { label: 'Qualified', value: '64', trend: '+9.1%', tone: 'positive' },
    { label: 'Closed deals', value: '27', trend: '+5.7%', tone: 'positive' },
    { label: 'Revenue', value: '$18.4k', trend: '+11.4%', tone: 'positive' },
  ] as const

  return (
    <div className="space-y-5 md:space-y-6">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {metrics.map((item) => (
          <div
            key={item.label}
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-medium text-slate-500">{item.label}</p>
            <p className="mt-2 text-3xl font-semibold tabular-nums text-slate-900">
              {item.value}
            </p>
            <div className="mt-3 flex items-center justify-between">
              <p
                className={[
                  'text-xs font-medium',
                  item.tone === 'positive' ? 'text-emerald-600' : 'text-rose-600',
                ].join(' ')}
              >
                {item.trend} vs previous period
              </p>
              <div className="flex items-end gap-0.5">
                {[28, 45, 32, 50, 38].map((height, idx) => (
                  <span
                    key={`${item.label}-${idx}`}
                    style={{ height: `${height}%` }}
                    className="block w-1 rounded bg-violet-200"
                  />
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>

    </div>
  )
}

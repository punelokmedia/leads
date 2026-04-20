import { useMemo, useState } from 'react'

export function DashboardPage() {
  const [range, setRange] = useState<'today' | 'week' | 'month'>('week')

  const stats = [
    { label: 'New leads', value: '128', trend: '+14%' },
    { label: 'Qualified leads', value: '64', trend: '+9%' },
    { label: 'Won this month', value: '27', trend: '+5%' },
    { label: 'Revenue', value: '$18.4k', trend: '+11%' },
  ]

  const activityBars = useMemo(() => {
    if (range === 'today') {
      return [35, 55, 40, 70, 58, 82, 64]
    }
    if (range === 'month') {
      return [22, 40, 66, 80, 72, 88, 95]
    }
    return [30, 60, 52, 78, 64, 84, 74]
  }, [range])

  return (
    <div className="space-y-5 md:space-y-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm md:p-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
              Dashboard
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Overview of leads, performance, and recent team activity.
            </p>
          </div>
          <div className="inline-flex rounded-xl border border-slate-200 bg-slate-50 p-1">
            {[
              ['today', 'Today'],
              ['week', 'This week'],
              ['month', 'This month'],
            ].map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setRange(id as 'today' | 'week' | 'month')}
                className={[
                  'rounded-lg px-3 py-1.5 text-xs font-medium transition',
                  range === id
                    ? 'bg-violet-600 text-white shadow-sm'
                    : 'text-slate-600 hover:bg-white',
                ].join(' ')}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((item) => (
          <div
            key={item.label}
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-medium text-slate-500">{item.label}</p>
            <p className="mt-2 text-3xl font-semibold tabular-nums text-slate-900">
              {item.value}
            </p>
            <p className="mt-1 text-xs text-emerald-400">{item.trend} vs last week</p>
          </div>
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm lg:col-span-2">
          <div className="mb-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-sm font-semibold text-slate-700">
                Lead activity ({range})
              </h2>
              <span className="text-xs text-slate-500">Updated live</span>
            </div>
            <div className="grid h-24 grid-cols-7 items-end gap-2">
              {activityBars.map((height, index) => (
                <div
                  key={`${range}-${index}`}
                  style={{ height: `${height}%` }}
                  className="rounded-md bg-gradient-to-t from-violet-500 to-indigo-400 transition-all duration-300"
                />
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-800">
              Recent leads
            </h2>
            <button
              type="button"
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-700 hover:border-slate-400 hover:bg-slate-100"
            >
              View all
            </button>
          </div>
          <div className="mt-4 space-y-3">
            {[
              ['Rahul Sharma', 'rahul@gmail.com', 'New'],
              ['Ayesha Khan', 'ayesha@demo.com', 'Qualified'],
              ['Vikram Singh', 'vikram@company.com', 'Follow-up'],
            ].map(([name, email, stage]) => (
              <div
                key={email}
                className="grid grid-cols-1 gap-2 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm md:grid-cols-[1fr_1fr_auto]"
              >
                <p className="font-medium text-slate-900">{name}</p>
                <p className="text-slate-500">{email}</p>
                <span className="inline-flex w-fit rounded-full bg-violet-100 px-2.5 py-1 text-xs text-violet-700">
                  {stage}
                </span>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-semibold text-slate-800">Quick actions</h2>
          <div className="mt-4 space-y-2">
            {['Add new lead', 'Export reports', 'Assign sales owner'].map(
              (action) => (
                <button
                  key={action}
                  type="button"
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-left text-sm text-slate-700 hover:border-slate-400 hover:bg-slate-100"
                >
                  {action}
                </button>
              ),
            )}
          </div>
        </section>
      </div>
    </div>
  )
}

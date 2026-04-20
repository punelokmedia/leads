export function LeadsPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
            Leads
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Manage and export lead records.
          </p>
        </div>
        <button
          type="button"
          className="rounded-lg bg-violet-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-violet-500"
        >
          Add lead
        </button>
      </div>
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-200 px-4 py-3 text-sm text-slate-500">
          Table placeholder — wire to your backend when ready.
        </div>
        <div className="p-8 text-center text-sm text-slate-500">
          No rows yet.
        </div>
      </div>
    </div>
  )
}

export function SettingsPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
          Settings
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Workspace and profile preferences.
        </p>
      </div>
      <section className="space-y-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-sm font-medium text-slate-700">Workspace</h2>
        <label className="block text-xs text-slate-500">
          Display name
          <input
            type="text"
            readOnly
            placeholder="Your team"
            className="mt-1.5 w-full rounded-lg border border-slate-300 bg-slate-50 px-3 py-2 text-sm text-slate-700 outline-none focus:border-violet-500"
          />
        </label>
      </section>
    </div>
  )
}

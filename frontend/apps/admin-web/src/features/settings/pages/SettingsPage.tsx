export function SettingsPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-white">
          Settings
        </h1>
        <p className="mt-1 text-sm text-stone-500">
          Workspace and profile preferences.
        </p>
      </div>
      <section className="space-y-4 rounded-xl border border-stone-800 bg-stone-900/40 p-6">
        <h2 className="text-sm font-medium text-stone-300">Workspace</h2>
        <label className="block text-xs text-stone-500">
          Display name
          <input
            type="text"
            readOnly
            placeholder="Your team"
            className="mt-1.5 w-full rounded-lg border border-stone-700 bg-stone-950 px-3 py-2 text-sm text-stone-200 outline-none focus:border-violet-500"
          />
        </label>
      </section>
    </div>
  )
}

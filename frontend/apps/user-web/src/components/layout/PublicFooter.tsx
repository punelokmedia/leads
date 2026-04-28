import { Link } from 'react-router-dom'

export function PublicFooter() {
  return (
    <footer className="bg-[#050505] text-white">
      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6">
        <div className="rounded-3xl border border-white/10 bg-[#070707] p-6 sm:p-8">
          <div className="grid gap-10 lg:grid-cols-[1.4fr_1fr] lg:items-start">
            <div>
              <img
                src="/logo.png"
                alt="Interiorwala"
                className="h-12 w-auto rounded-md bg-white px-2 py-1"
              />
              <p className="mt-5 max-w-xl text-sm leading-relaxed text-stone-300 sm:text-base">
                Building the future of interior design by bridging the gap between
                high-intent clients and world-class design professionals.
              </p>
            </div>

            <div className="space-y-3">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-stone-500">
                Quick Links
              </p>
              <div className="grid grid-cols-2 gap-3 text-sm text-stone-300">
                <Link to="/privacy-policy" className="transition hover:text-[#F8B020]">
                  Privacy Policy
                </Link>
                <Link to="/terms-service" className="transition hover:text-[#F8B020]">
                  Terms & Service
                </Link>
                <Link to="/cookie-policy" className="transition hover:text-[#F8B020]">
                  Cookie Policy
                </Link>
                <Link to="/contact-support" className="transition hover:text-[#F8B020]">
                  Contact Support
                </Link>
              </div>
            </div>
          </div>

          <div className="mt-8 flex flex-col gap-3 border-t border-white/10 pt-5 text-xs text-stone-500 sm:flex-row sm:items-center sm:justify-between">
            <p>Designed for verified interior design lead discovery across India.</p>
            <p>{new Date().getFullYear()} Interiorwala. All rights reserved.</p>
          </div>
        </div>
      </div>
    </footer>
  )
}

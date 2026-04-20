import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'

export function LoginPage() {
  const navigate = useNavigate()
  const { pendingEmail, demoOtp, sendOtp, verifyOtp, resetOtpFlow } = useAdminAuth()

  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [errorMessage, setErrorMessage] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [isVerifying, setIsVerifying] = useState(false)

  const isOtpStep = Boolean(pendingEmail)

  async function handleSendOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const trimmedEmail = email.trim().toLowerCase()

    if (!trimmedEmail) {
      setErrorMessage('Please enter your admin email.')
      return
    }

    setErrorMessage('')
    setIsSending(true)

    try {
      await sendOtp(trimmedEmail)
    } finally {
      setIsSending(false)
    }
  }

  async function handleVerifyOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const cleanOtp = otp.trim()
    if (!cleanOtp) {
      setErrorMessage('Please enter the OTP code.')
      return
    }

    setErrorMessage('')
    setIsVerifying(true)

    try {
      const success = await verifyOtp(cleanOtp)
      if (!success) {
        setErrorMessage('Incorrect OTP. Please check and try again.')
        return
      }
      navigate('/', { replace: true })
    } finally {
      setIsVerifying(false)
    }
  }

  function handleUseDifferentEmail() {
    resetOtpFlow()
    setOtp('')
    setErrorMessage('')
  }

  return (
    <div className="relative flex min-h-dvh items-center justify-center overflow-hidden px-4 py-8 sm:py-10">
      <div className="pointer-events-none absolute -left-20 -top-20 h-72 w-72 rounded-full bg-violet-500/15 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -right-20 h-72 w-72 rounded-full bg-sky-400/15 blur-3xl" />

      <div className="grid w-full max-w-5xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl md:grid-cols-2">
        <section className="flex flex-col justify-between border-b border-slate-200 bg-gradient-to-b from-violet-50 to-indigo-50 p-6 sm:p-8 md:border-b-0 md:border-r md:p-10">
          <div>
            <span className="inline-flex rounded-full border border-violet-300 bg-violet-100 px-3 py-1 text-xs font-semibold text-violet-700">
              Admin Panel
            </span>
            <h1 className="mt-4 text-2xl font-semibold text-slate-900 sm:text-3xl">
              Welcome to Leads Sell
            </h1>
            <p className="mt-3 text-sm leading-6 text-slate-600">
              Secure admin access with email OTP. Monitor leads, team activity,
              and conversion trends from one dashboard.
            </p>
          </div>

          <div className="mt-8 grid gap-3 text-sm text-slate-700">
            {[
              'Lead pipeline overview',
              'Daily revenue snapshot',
              'Team productivity stats',
            ].map((item) => (
              <div
                key={item}
                className="rounded-xl border border-violet-100 bg-white px-4 py-3 shadow-sm"
              >
                {item}
              </div>
            ))}
          </div>
        </section>

        <section className="p-6 sm:p-8 md:p-10">
          <div className="mb-6">
            <div className="mb-4 flex items-center gap-2">
              <span
                className={[
                  'h-2.5 w-2.5 rounded-full',
                  !isOtpStep ? 'bg-violet-600' : 'bg-emerald-500',
                ].join(' ')}
              />
              <span className="text-xs font-medium text-slate-500">
                Step {!isOtpStep ? '1 of 2' : '2 of 2'}
              </span>
            </div>
            <p className="text-sm font-semibold text-slate-900">Sign in as Admin</p>
            <p className="mt-1 text-xs text-slate-500">
              {isOtpStep
                ? 'Enter the OTP sent to your email.'
                : 'Enter your email to receive login OTP.'}
            </p>
          </div>

          {!isOtpStep ? (
            <form className="space-y-4" onSubmit={handleSendOtp}>
              <label className="block text-xs font-medium text-slate-600">
                Admin Email
                <input
                  type="email"
                  autoComplete="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-violet-500"
                  placeholder="admin@company.com"
                />
              </label>
              {errorMessage ? (
                <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
                  {errorMessage}
                </p>
              ) : null}
              <button
                type="submit"
                disabled={isSending}
                className="w-full rounded-lg bg-violet-600 py-2.5 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-70"
              >
                {isSending ? 'Sending OTP...' : 'Send OTP'}
              </button>
              <p className="text-center text-xs text-slate-500">
                Fast, secure, passwordless login for admins.
              </p>
            </form>
          ) : (
            <form className="space-y-4" onSubmit={handleVerifyOtp}>
              <label className="block text-xs font-medium text-slate-600">
                One Time Password
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  value={otp}
                  onChange={(event) =>
                    setOtp(event.target.value.replace(/\D/g, ''))
                  }
                  className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm tracking-[0.3em] text-slate-800 outline-none transition focus:border-violet-500"
                  placeholder="123456"
                />
              </label>
              <div className="flex items-center justify-center gap-2">
                {Array.from({ length: 6 }).map((_, index) => (
                  <div
                    key={index}
                    className={[
                      'flex h-10 w-9 items-center justify-center rounded-lg border text-sm font-semibold',
                      otp[index]
                        ? 'border-violet-300 bg-violet-50 text-violet-700'
                        : 'border-slate-300 bg-slate-50 text-slate-400',
                    ].join(' ')}
                  >
                    {otp[index] ?? '-'}
                  </div>
                ))}
              </div>
              <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
                OTP sent to <span className="font-medium">{pendingEmail}</span>
                <br />
                Demo OTP: <span className="font-semibold">{demoOtp}</span>
              </div>
              {errorMessage ? (
                <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
                  {errorMessage}
                </p>
              ) : null}
              <button
                type="submit"
                disabled={isVerifying}
                className="w-full rounded-lg bg-violet-600 py-2.5 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-70"
              >
                {isVerifying ? 'Verifying...' : 'Verify and Login'}
              </button>
              <button
                type="button"
                onClick={handleUseDifferentEmail}
                className="w-full rounded-lg border border-slate-300 py-2.5 text-sm font-medium text-slate-700 transition hover:border-slate-400 hover:bg-slate-100"
              >
                Use different email
              </button>
            </form>
          )}

          <div className="mt-6 grid grid-cols-3 gap-2 rounded-xl border border-slate-200 bg-slate-50 p-3 text-center">
            {[
              ['99.9%', 'Uptime'],
              ['2 sec', 'OTP time'],
              ['256-bit', 'Encryption'],
            ].map(([value, label]) => (
              <div key={label}>
                <p className="text-sm font-semibold text-slate-900">{value}</p>
                <p className="text-[11px] text-slate-500">{label}</p>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}

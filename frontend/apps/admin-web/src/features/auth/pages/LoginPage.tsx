import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAdminAuth } from '@/features/auth/context/AdminAuthContext'
import { useToast } from '@/components/feedback/ToastProvider'

export function LoginPage() {
  const navigate = useNavigate()
  const toast = useToast()
  const { pendingEmail, sendOtp, verifyOtp, resetOtpFlow } = useAdminAuth()

  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [errorMessage, setErrorMessage] = useState('')
  const [infoMessage, setInfoMessage] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [isVerifying, setIsVerifying] = useState(false)
  const [resendInSeconds, setResendInSeconds] = useState(0)

  const isOtpStep = Boolean(pendingEmail)
  const otpFilledCount = otp.length
  const resendLabel = `${Math.floor(resendInSeconds / 60)}:${String(
    resendInSeconds % 60,
  ).padStart(2, '0')}`

  useEffect(() => {
    if (!isOtpStep || resendInSeconds <= 0) {
      return
    }

    const timer = window.setTimeout(() => {
      setResendInSeconds((previous) => Math.max(0, previous - 1))
    }, 1000)

    return () => window.clearTimeout(timer)
  }, [isOtpStep, resendInSeconds])

  async function handleSendOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const trimmedEmail = email.trim().toLowerCase()

    if (!trimmedEmail) {
      setInfoMessage('')
      const message = 'Please enter your admin email.'
      setErrorMessage(message)
      toast.error(message)
      return
    }

    setInfoMessage('')
    setErrorMessage('')
    setIsSending(true)

    try {
      const result = await sendOtp(trimmedEmail)
      setInfoMessage(
        result.devOtp
          ? `Test mode OTP: ${result.devOtp} (email delivery restricted)`
          : `OTP sent to ${trimmedEmail}`,
      )
      toast.success(result.devOtp ? 'OTP generated in test mode' : 'OTP sent successfully')
      setResendInSeconds(30)
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to send OTP. Try again.'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setIsSending(false)
    }
  }

  async function handleVerifyOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const cleanOtp = otp.trim()
    if (!cleanOtp) {
      setInfoMessage('')
      const message = 'Please enter the OTP code.'
      setErrorMessage(message)
      toast.error(message)
      return
    }

    setInfoMessage('')
    setErrorMessage('')
    setIsVerifying(true)

    try {
      const success = await verifyOtp(cleanOtp)
      if (!success) {
        const message = 'Incorrect OTP. Please check and try again.'
        setErrorMessage(message)
        toast.error(message)
        return
      }
      setInfoMessage('Login successful. Redirecting to dashboard...')
      toast.success('Login successful')
      navigate('/', { replace: true })
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to verify OTP. Try again.'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setIsVerifying(false)
    }
  }

  function handleUseDifferentEmail() {
    resetOtpFlow()
    setOtp('')
    setErrorMessage('')
    setInfoMessage('')
    setResendInSeconds(0)
  }

  async function handleResendOtp() {
    if (!pendingEmail || resendInSeconds > 0 || isSending) {
      return
    }

    setErrorMessage('')
    setInfoMessage('')
    setIsSending(true)

    try {
      const result = await sendOtp(pendingEmail)
      setInfoMessage(
        result.devOtp
          ? `Test mode OTP: ${result.devOtp} (email delivery restricted)`
          : `New OTP sent to ${pendingEmail}`,
      )
      toast.success('OTP resent successfully')
      setResendInSeconds(30)
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to resend OTP. Try again.'
      setErrorMessage(message)
      toast.error(message)
    } finally {
      setIsSending(false)
    }
  }

  return (
    <div className="relative min-h-dvh overflow-hidden bg-slate-950">
      <header className="relative z-10 border-b border-white/10 bg-slate-950/70 backdrop-blur-xl">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-4 sm:px-6">
          <div className="flex items-center gap-2">
            <div className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500 to-indigo-500 text-sm font-bold text-white">
              LS
            </div>
            <div>
              <p className="text-sm font-semibold text-white">Leads Sell</p>
              <p className="text-[11px] text-slate-400">Admin Control Center</p>
            </div>
          </div>
          <div className="hidden items-center gap-2 text-xs sm:flex">
            <span className="rounded-full border border-emerald-500/40 bg-emerald-500/10 px-2.5 py-1 font-medium text-emerald-300">
              Secure OTP Access
            </span>
            <span className="rounded-full border border-slate-700 bg-slate-900 px-2.5 py-1 font-medium text-slate-300">
              24x7 Monitoring
            </span>
          </div>
        </div>
      </header>

      <div className="relative flex min-h-[calc(100dvh-8rem)] items-center justify-center px-4 py-8 sm:py-10">
      <div className="pointer-events-none absolute -left-20 -top-20 h-72 w-72 rounded-full bg-violet-500/15 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -right-20 h-72 w-72 rounded-full bg-sky-400/15 blur-3xl" />
      <div className="pointer-events-none absolute left-1/2 top-14 hidden h-44 w-44 -translate-x-1/2 rounded-full bg-fuchsia-400/10 blur-3xl md:block" />
      <div className="pointer-events-none absolute right-24 top-28 hidden rounded-full border border-white/15 bg-white/5 px-3 py-1 text-[10px] font-semibold tracking-wide text-white/80 md:block">
        LIVE SECURE MODE
      </div>

      <div className="grid w-full max-w-5xl overflow-hidden rounded-3xl border border-white/10 bg-white shadow-2xl md:grid-cols-2">
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
            <div className="mt-5 grid grid-cols-3 gap-2 rounded-xl border border-violet-200/70 bg-white/70 p-3 text-center">
              {[
                ['24/7', 'Monitoring'],
                ['OTP', 'Zero Password'],
                ['1 Click', 'Secure Sign-in'],
              ].map(([value, label]) => (
                <div key={label}>
                  <p className="text-sm font-semibold text-slate-900">{value}</p>
                  <p className="text-[11px] text-slate-500">{label}</p>
                </div>
              ))}
            </div>
            <div className="mt-4 rounded-xl border border-indigo-100 bg-white/80 p-3">
              <p className="text-xs font-semibold uppercase tracking-wide text-indigo-600">
                Security checkpoint
              </p>
              <p className="mt-1 text-xs leading-5 text-slate-600">
                Device and login attempts are monitored in real-time to protect admin accounts.
              </p>
            </div>
          </div>

          <div className="mt-8 rounded-xl border border-violet-100 bg-white/80 px-4 py-3 text-sm text-slate-600 shadow-sm">
            One secure place to manage admins, leads, and platform operations.
          </div>
        </section>

        <section className="p-6 sm:p-8 md:p-10">
          <div className="mb-6">
            <div className="mb-3 flex items-center justify-between gap-3">
              <span className="text-xs font-medium text-slate-500">
                Step {!isOtpStep ? '1 of 2' : '2 of 2'}
              </span>
              <span
                className={[
                  'rounded-full px-2 py-0.5 text-[11px] font-medium',
                  isOtpStep
                    ? 'bg-emerald-100 text-emerald-700'
                    : 'bg-violet-100 text-violet-700',
                ].join(' ')}
              >
                {!isOtpStep ? 'Email verification' : 'OTP confirmation'}
              </span>
            </div>
            <div className="mb-4 h-2 overflow-hidden rounded-full bg-slate-100">
              <div
                className={[
                  'h-full rounded-full bg-gradient-to-r from-violet-600 to-indigo-500 transition-all duration-500',
                  isOtpStep ? 'w-full' : 'w-1/2',
                ].join(' ')}
              />
            </div>
            <p className="text-sm font-semibold text-slate-900">Sign in as Admin</p>
            <p className="mt-1 text-xs text-slate-500">
              {isOtpStep
                ? 'Enter the OTP sent to your email.'
                : 'Enter your email to receive login OTP.'}
            </p>
            {isOtpStep ? (
              <div className="mt-3 flex items-center gap-2 text-[11px] text-slate-500">
                <span className="inline-flex h-2 w-2 animate-pulse rounded-full bg-emerald-500" />
                Session secured. Enter the 4-digit OTP to continue.
              </div>
            ) : null}
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
                  className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  placeholder="admin@company.com"
                />
              </label>
              {infoMessage ? (
                <p className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
                  {infoMessage}
                </p>
              ) : null}
              {errorMessage ? (
                <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
                  {errorMessage}
                </p>
              ) : null}
              <button
                type="submit"
                disabled={isSending}
                className="w-full rounded-lg bg-gradient-to-r from-violet-600 to-indigo-600 py-2.5 text-sm font-semibold text-white shadow-lg shadow-violet-200 transition hover:from-violet-500 hover:to-indigo-500 disabled:cursor-not-allowed disabled:opacity-70"
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
                  maxLength={4}
                  value={otp}
                  onChange={(event) =>
                    setOtp(event.target.value.replace(/\D/g, ''))
                  }
                  className="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-center text-sm tracking-[0.3em] text-slate-800 outline-none transition focus:border-violet-500 focus:ring-2 focus:ring-violet-100"
                  placeholder="1234"
                />
              </label>
              <div className="flex items-center justify-center gap-2">
                {Array.from({ length: 4 }).map((_, index) => (
                  <div
                    key={index}
                    className={[
                      'flex h-10 w-9 items-center justify-center rounded-lg border text-sm font-semibold transition',
                      otp[index]
                        ? 'border-violet-300 bg-violet-50 text-violet-700 shadow-sm'
                        : 'border-slate-300 bg-slate-50 text-slate-400',
                    ].join(' ')}
                  >
                    {otp[index] ?? '-'}
                  </div>
                ))}
              </div>
              <div className="h-1.5 overflow-hidden rounded-full bg-slate-100">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-violet-500 to-indigo-500 transition-all duration-300"
                  style={{ width: `${(otpFilledCount / 4) * 100}%` }}
                />
              </div>
              <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
                OTP sent to <span className="font-medium">{pendingEmail}</span>
              </div>
              {infoMessage ? (
                <p className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
                  {infoMessage}
                </p>
              ) : null}
              {errorMessage ? (
                <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
                  {errorMessage}
                </p>
              ) : null}
              <button
                type="submit"
                disabled={isVerifying}
                className="w-full rounded-lg bg-gradient-to-r from-violet-600 to-indigo-600 py-2.5 text-sm font-semibold text-white shadow-lg shadow-violet-200 transition hover:from-violet-500 hover:to-indigo-500 disabled:cursor-not-allowed disabled:opacity-70"
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
              <button
                type="button"
                onClick={handleResendOtp}
                disabled={resendInSeconds > 0 || isSending}
                className="w-full rounded-lg border border-violet-200 bg-violet-50 py-2.5 text-sm font-medium text-violet-700 transition hover:border-violet-300 hover:bg-violet-100 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {resendInSeconds > 0
                  ? `Resend OTP in ${resendLabel}`
                  : isSending
                    ? 'Resending...'
                    : 'Resend OTP'}
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

      <footer className="relative z-10 border-t border-white/10 bg-slate-950/70">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center justify-between gap-2 px-4 py-4 text-center sm:flex-row sm:px-6 sm:text-left">
          <p className="text-xs text-slate-400">
            © {new Date().getFullYear()} Leads Sell. All rights reserved.
          </p>
          <div className="flex items-center gap-3 text-[11px] text-slate-400">
            <span className="rounded-md border border-slate-700 bg-slate-900 px-2 py-1">
              Encrypted Session
            </span>
            <span className="rounded-md border border-slate-700 bg-slate-900 px-2 py-1">
              Admin Access Only
            </span>
          </div>
        </div>
      </footer>
    </div>
  )
}

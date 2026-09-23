import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

const CONFIGURED_API_BASE_URL = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
const API_BASE_URL_CANDIDATES = Array.from(
  new Set([CONFIGURED_API_BASE_URL, `${window.location.protocol}//${window.location.hostname}:5000`].filter(Boolean)),
)

const TOTAL_STEPS = 6
const OTP_RESEND_SECONDS = 25

type ProfileForm = {
  fullName: string
  businessName: string
  workType: string
}

const stepTitleMap: Record<number, string> = {
  1: 'Splash Screen',
  2: 'Welcome Screen',
  3: 'Login / Signup',
  4: 'Verify Your Number',
  5: 'Enter OTP',
  6: 'Tell Us About Yourself',
}

export function MobileAuthPage() {
  const navigate = useNavigate()
  const [step, setStep] = useState(1)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', ''])
  const [token, setToken] = useState('')
  const [otpSecondsLeft, setOtpSecondsLeft] = useState(0)
  const [profileForm, setProfileForm] = useState<ProfileForm>({
    fullName: '',
    businessName: '',
    workType: '',
  })

  const progress = useMemo(() => Math.round((step / TOTAL_STEPS) * 100), [step])

  const requestAuth = async (path: string, init?: RequestInit) => {
    let lastError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        return await fetch(`${baseUrl}/api/v1/auth${path}`, init)
      } catch (networkError) {
        lastError =
          networkError instanceof Error
            ? networkError
            : new Error('Unable to connect with auth server.')
      }
    }

    throw lastError ?? new Error('Unable to connect with auth server.')
  }

  const handleGoogleLogin = () => {
    const preferredBaseUrl =
      CONFIGURED_API_BASE_URL && API_BASE_URL_CANDIDATES.includes(CONFIGURED_API_BASE_URL)
        ? CONFIGURED_API_BASE_URL
        : API_BASE_URL_CANDIDATES[0]

    if (!preferredBaseUrl) {
      setError('Google login is not configured right now.')
      return
    }

    window.location.href = `${preferredBaseUrl}/api/v1/auth/google`
  }

  const clearMessages = () => {
    setError('')
    setSuccess('')
  }

  const startOtpTimer = () => {
    setOtpSecondsLeft(OTP_RESEND_SECONDS)
    const timer = window.setInterval(() => {
      setOtpSecondsLeft((prev) => {
        if (prev <= 1) {
          window.clearInterval(timer)
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }

  const handleRequestOtp = async () => {
    clearMessages()
    if (!/^[6-9]\d{9}$/.test(phoneNumber)) {
      setError('Please enter a valid 10-digit mobile number.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/mobile/request-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phoneNumber }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Failed to send OTP.')
      }

      // Dev convenience: backend exposes OTP in non-production mode.
      if (payload?.data?.otp) {
        setSuccess(`OTP sent successfully. Test OTP: ${payload.data.otp}`)
      } else {
        setSuccess(payload?.message ?? 'OTP sent successfully.')
      }
      startOtpTimer()
      setStep(5)
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Failed to send OTP.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleVerifyOtp = async () => {
    clearMessages()
    const otp = otpDigits.join('')
    if (otp.length !== 6) {
      setError('Please enter 6-digit OTP.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/mobile/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phoneNumber, otp }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'OTP verification failed.')
      }

      const userToken = payload?.token as string
      if (userToken) {
        localStorage.setItem('user_token', userToken)
        localStorage.setItem('user_profile', JSON.stringify(payload?.data ?? {}))
        setToken(userToken)
      }

      if (payload?.meta?.needsProfile) {
        setSuccess('OTP verified. Please complete your profile.')
        setStep(6)
      } else {
        localStorage.setItem('auth_provider', 'mobile-otp')
        navigate('/')
      }
    } catch (verifyError) {
      setError(verifyError instanceof Error ? verifyError.message : 'OTP verification failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCompleteProfile = async () => {
    clearMessages()
    if (!profileForm.fullName || !profileForm.businessName || !profileForm.workType) {
      setError('Please fill all required profile details.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/mobile/complete-profile', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token || localStorage.getItem('user_token') || ''}`,
        },
        body: JSON.stringify({
          fullName: profileForm.fullName,
          role: 'USER',
          businessName: profileForm.businessName,
          workType: profileForm.workType,
        }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Profile update failed.')
      }

      localStorage.setItem('user_profile', JSON.stringify(payload?.data ?? {}))
      localStorage.setItem('auth_provider', 'mobile-otp')
      navigate('/')
    } catch (completeError) {
      setError(completeError instanceof Error ? completeError.message : 'Profile update failed.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/45">
      <div className="ml-auto h-full w-full max-w-md overflow-y-auto bg-[#f6f4ff] p-4 sm:p-5">
        <div className="w-full rounded-[30px] border border-[#e3defb] bg-white p-6 shadow-[0_20px_45px_rgba(65,40,140,0.08)] sm:p-7">
        <div className="mb-6 flex items-center justify-between">
          <Link to="/" className="text-sm font-semibold text-[#6144F5] hover:underline">
            Back
          </Link>
          <p className="text-xs font-semibold text-[#8A89A2]">
            Step {step}/{TOTAL_STEPS}
          </p>
        </div>

        <div className="mb-6 h-2 overflow-hidden rounded-full bg-[#EDECF8]">
          <div className="h-full rounded-full bg-[#5A35F0] transition-all" style={{ width: `${progress}%` }} />
        </div>

        <p className="text-xs font-semibold tracking-wide text-[#8A89A2] uppercase">NextLeads Web User</p>
        <h1 className="mt-2 text-2xl font-bold text-[#1F1D35]">{stepTitleMap[step]}</h1>

        {error ? (
          <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
        ) : null}
        {success ? (
          <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">
            {success}
          </p>
        ) : null}

        {step === 1 ? (
          <div className="mt-6 flex min-h-[360px] flex-col items-center justify-between rounded-3xl bg-gradient-to-b from-[#ffffff] via-[#f8f5ff] to-[#f1ecff] px-6 py-8 text-center">
            <div className="space-y-2">
              <div className="mx-auto h-16 w-16 rounded-2xl bg-[#f2ecff] p-3">
                <svg viewBox="0 0 24 24" className="h-full w-full text-[#5A35F0]" fill="none" stroke="currentColor" strokeWidth="1.8">
                  <path d="M4 15.5c1.4-1.9 3.3-3.2 5.6-3.9 2.8-.9 5.7-.7 8.4.7" />
                  <path d="M5.5 8.3c1.2-.8 2.7-1.4 4.3-1.7 3.2-.6 6.4.3 8.8 2.4" />
                  <circle cx="8.5" cy="16.5" r="2.1" />
                  <circle cx="15.6" cy="8" r="2.1" />
                </svg>
              </div>
              <p className="text-xl font-bold text-[#1f1d35]">NextLeads</p>
              <p className="text-sm text-[#706b94]">India&apos;s Premium Vendor Network</p>
            </div>
            <button
              type="button"
              onClick={() => setStep(2)}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA]"
            >
              Continue
            </button>
          </div>
        ) : null}

        {step === 2 ? (
          <div className="mt-6 space-y-5">
            <div className="rounded-2xl bg-[#f7f4ff] p-5">
              <h2 className="text-xl font-bold leading-7 text-[#1f1d35]">High Quality Leads</h2>
              <p className="text-xl font-bold leading-7 text-[#1f1d35]">High Value Projects</p>
              <p className="mt-1 text-xs font-medium text-[#6f6a91]">Only 2 Vendors per Lead</p>
            </div>
            <ul className="space-y-2 text-sm text-[#5f5b7b]">
              <li>1000+ Cities Coverage</li>
              <li>Trusted by 10,000+ Vendors</li>
              <li>High Quality Leads</li>
              <li>Better ROI</li>
            </ul>
            <button
              type="button"
              onClick={() => setStep(3)}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA]"
            >
              Get Started
            </button>
          </div>
        ) : null}

        {step === 3 ? (
          <div className="mt-6 space-y-4">
            <p className="text-sm text-[#6c678c]">Login to continue</p>
            <label className="block text-sm font-medium text-[#3A365F]">
              Mobile Number
              <div className="mt-2 flex items-center rounded-xl border border-[#D9D7EC] px-3">
                <span className="text-sm text-[#777396]">+91</span>
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(event) => setPhoneNumber(event.target.value.replace(/\D/g, '').slice(0, 10))}
                  placeholder="98765 43210"
                  className="h-11 w-full border-0 bg-transparent px-2 text-sm outline-none"
                />
              </div>
            </label>
            <button
              type="button"
              onClick={() => setStep(4)}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA]"
            >
              Continue
            </button>
            <p className="text-center text-sm text-[#8A89A2]">or</p>
            <button
              type="button"
              onClick={handleGoogleLogin}
              className="flex h-11 w-full items-center justify-center gap-2 rounded-xl border border-[#ded8f6] bg-white text-sm font-semibold text-[#4f4a73] transition hover:bg-[#f6f3ff]"
            >
              <span className="inline-grid h-5 w-5 place-items-center rounded-full bg-[#f1ebff] text-xs font-bold text-[#5A35F0]">
                G
              </span>
              Continue with Google
            </button>
          </div>
        ) : null}

        {step === 4 ? (
          <div className="mt-6 space-y-4">
            <p className="text-sm text-[#5D5A79]">
              We will send you an OTP on <span className="font-semibold">+91 {phoneNumber}</span>.
            </p>
            <button
              type="button"
              disabled={isLoading}
              onClick={() => void handleRequestOtp()}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA] disabled:opacity-70"
            >
              {isLoading ? 'Sending OTP...' : 'Send OTP'}
            </button>
            <div className="rounded-xl bg-[#f7f4ff] p-3 text-center text-xs text-[#7d78a0]">
              Your number is safe and secure with us.
            </div>
          </div>
        ) : null}

        {step === 5 ? (
          <div className="mt-6 space-y-4">
            <p className="text-sm text-[#5D5A79]">Enter the OTP received on your mobile number.</p>
            <div className="flex items-center justify-between gap-2">
              {otpDigits.map((digit, index) => (
                <input
                  key={index}
                  type="text"
                  maxLength={1}
                  value={digit}
                  onChange={(event) => {
                    const value = event.target.value.replace(/\D/g, '')
                    setOtpDigits((prev) => {
                      const next = [...prev]
                      next[index] = value
                      return next
                    })
                  }}
                  className="h-12 w-12 rounded-xl border border-[#D9D7EC] text-center text-lg font-semibold text-[#1F1D35] outline-none focus:border-[#5A35F0]"
                />
              ))}
            </div>
            <button
              type="button"
              disabled={isLoading}
              onClick={() => void handleVerifyOtp()}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA] disabled:opacity-70"
            >
              {isLoading ? 'Verifying...' : 'Verify OTP'}
            </button>
            <div className="text-center text-xs text-[#7d78a0]">
              {otpSecondsLeft > 0 ? (
                <span>Resend OTP in 00:{String(otpSecondsLeft).padStart(2, '0')}</span>
              ) : (
                <button
                  type="button"
                  onClick={() => void handleRequestOtp()}
                  className="font-semibold text-[#5A35F0] hover:underline"
                >
                  Didn&apos;t receive OTP? Resend
                </button>
              )}
            </div>
          </div>
        ) : null}

        {step === 6 ? (
          <div className="mt-6 space-y-3">
            <p className="text-sm text-[#6c678c]">We need a few details to set up your account.</p>
            <input
              type="text"
              value={profileForm.fullName}
              onChange={(event) => setProfileForm((prev) => ({ ...prev, fullName: event.target.value }))}
              placeholder="Full Name"
              className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#5A35F0]"
            />
            <input
              type="text"
              value={profileForm.businessName}
              onChange={(event) => setProfileForm((prev) => ({ ...prev, businessName: event.target.value }))}
              placeholder="Business / Company Name"
              className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#5A35F0]"
            />
            <input
              type="text"
              value={profileForm.workType}
              onChange={(event) => setProfileForm((prev) => ({ ...prev, workType: event.target.value }))}
              placeholder="Work Type"
              className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#5A35F0]"
            />
            <button
              type="button"
              disabled={isLoading}
              onClick={() => void handleCompleteProfile()}
              className="h-12 w-full rounded-xl bg-[#5A35F0] text-sm font-semibold text-white hover:bg-[#4C2CDA] disabled:opacity-70"
            >
              {isLoading ? 'Saving...' : 'Continue'}
            </button>
          </div>
        ) : null}
        </div>
      </div>
    </div>
  )
}

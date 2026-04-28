import { useEffect, useState, type KeyboardEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'

const CONFIGURED_API_BASE_URL = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
const API_BASE_URL_CANDIDATES = Array.from(
  new Set(['http://localhost:5000', CONFIGURED_API_BASE_URL].filter(Boolean)),
)
const OTP_RESEND_SECONDS = 25
const REGISTRATION_AMOUNT_INR = 499

type ProfileForm = {
  fullName: string
  email: string
  city: string
  businessName: string
  workType: string
}

type WorkTypeOption = {
  id: string
  label: string
}

const DEFAULT_WORK_TYPES: WorkTypeOption[] = [
  { id: 'interior-designer', label: 'Interior Designer' },
  { id: 'architect', label: 'Architect' },
  { id: 'contractor', label: 'Contractor' },
]

export function MobileAuthDrawerPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const isGoogleOnboardingFlow = searchParams.get('flow') === 'google'
  const [step, setStep] = useState(0)
  const [authIntent, setAuthIntent] = useState<'login' | 'signup'>('login')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', ''])
  const [token, setToken] = useState('')
  const [otpSecondsLeft, setOtpSecondsLeft] = useState(0)
  const [toastMessage, setToastMessage] = useState('')
  const [profileForm, setProfileForm] = useState<ProfileForm>({
    fullName: '',
    email: '',
    city: '',
    businessName: '',
    workType: '',
  })
  const [workTypeOptions, setWorkTypeOptions] = useState<WorkTypeOption[]>([])
  const [isWorkTypeLoading, setIsWorkTypeLoading] = useState(false)
  const stepImageByScreen: Record<number, string> = {
    1: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=2000&q=90',
    2: 'https://images.unsplash.com/photo-1460472178825-e5240623afd5?auto=format&fit=crop&w=2000&q=90',
    3: 'https://images.unsplash.com/photo-1559526324-593bc073d938?auto=format&fit=crop&w=2000&q=90',
    4: 'https://images.unsplash.com/photo-1552581234-26160f608093?auto=format&fit=crop&w=2000&q=90',
    5: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=2000&q=90',
  }

  useEffect(() => {
    if (step !== 0) return
    const timer = window.setTimeout(() => setStep(1), 2000)
    return () => window.clearTimeout(timer)
  }, [step])

  useEffect(() => {
    if (!isGoogleOnboardingFlow) return

    const userToken = localStorage.getItem('user_token') || ''
    if (!userToken) return

    setToken(userToken)

    let profile: {
      firstname?: string
      lastname?: string
      email?: string
      phoneNumber?: string
      city?: string
      businessName?: string
      workType?: string
      registrationFeePaid?: boolean
    } = {}

    try {
      profile = JSON.parse(localStorage.getItem('user_profile') || '{}')
    } catch {
      profile = {}
    }

    const fullName = [profile.firstname, profile.lastname].filter(Boolean).join(' ').trim()
    if (profile.phoneNumber) {
      setPhoneNumber(String(profile.phoneNumber))
    }
    setProfileForm((prev) => ({
      ...prev,
      fullName: fullName || prev.fullName,
      email: profile.email || prev.email,
      city: profile.city || prev.city,
      businessName: profile.businessName || prev.businessName,
      workType: profile.workType || prev.workType,
    }))

    const hasProfile =
      Boolean(fullName) &&
      Boolean(profile.email) &&
      Boolean(profile.city) &&
      Boolean(profile.businessName) &&
      Boolean(profile.workType)

    setStep(hasProfile ? 5 : 2)
  }, [isGoogleOnboardingFlow, searchParams])

  useEffect(() => {
    if (!toastMessage) return
    const timer = window.setTimeout(() => setToastMessage(''), 2600)
    return () => window.clearTimeout(timer)
  }, [toastMessage])

  const requestApi = async (path: string, init?: RequestInit) => {
    let lastError: Error | null = null
    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        return await fetch(`${baseUrl}/api/v1${path}`, init)
      } catch (networkError) {
        lastError =
          networkError instanceof Error
            ? networkError
            : new Error('Unable to connect with auth server.')
      }
    }
    throw lastError ?? new Error('Unable to connect with auth server.')
  }

  const requestAuth = async (path: string, init?: RequestInit) => requestApi(`/auth${path}`, init)

  const loadRazorpayScript = async () => {
    if (window.Razorpay) return true
    return new Promise<boolean>((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://checkout.razorpay.com/v1/checkout.js'
      script.async = true
      script.onload = () => resolve(true)
      script.onerror = () => resolve(false)
      document.body.appendChild(script)
    })
  }

  const handleGoogleLogin = () => {
    const preferredBaseUrl =
      CONFIGURED_API_BASE_URL && API_BASE_URL_CANDIDATES.includes(CONFIGURED_API_BASE_URL)
        ? CONFIGURED_API_BASE_URL
        : API_BASE_URL_CANDIDATES[0]
    if (!preferredBaseUrl) return setError('Google login is not configured right now.')
    window.location.href = `${preferredBaseUrl}/api/v1/auth/google`
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
    setError('')
    setSuccess('')
    if (!/^[6-9]\d{9}$/.test(phoneNumber)) {
      return setError('Please enter a valid 10-digit mobile number.')
    }
    try {
      setIsLoading(true)
      const response = await requestAuth(
        isGoogleOnboardingFlow ? '/mobile/request-otp-session' : '/mobile/request-otp',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(isGoogleOnboardingFlow
              ? { Authorization: `Bearer ${token || localStorage.getItem('user_token') || ''}` }
              : {}),
          },
          body: JSON.stringify({ phoneNumber }),
        },
      )
      const payload = await response.json()
      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Failed to send OTP.')
      }
      setSuccess(payload?.data?.otp ? `Test OTP: ${payload.data.otp}` : 'OTP sent successfully.')
      startOtpTimer()
      setStep(3)
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Failed to send OTP.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleVerifyOtp = async () => {
    setError('')
    setSuccess('')
    const otp = otpDigits.join('')
    if (otp.length !== 6) return setError('Please enter 6-digit OTP.')
    try {
      setIsLoading(true)
      const response = await requestAuth(
        isGoogleOnboardingFlow ? '/mobile/verify-otp-session' : '/mobile/verify-otp',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(isGoogleOnboardingFlow
              ? { Authorization: `Bearer ${token || localStorage.getItem('user_token') || ''}` }
              : {}),
          },
          body: JSON.stringify({ phoneNumber, otp }),
        },
      )
      const payload = await response.json()
      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'OTP verification failed.')
      }
      if (isGoogleOnboardingFlow) {
        const userProfileRaw = localStorage.getItem('user_profile') || '{}'
        let userProfile: Record<string, unknown> = {}
        try {
          userProfile = JSON.parse(userProfileRaw)
        } catch {
          userProfile = {}
        }
        userProfile.phoneNumber = phoneNumber
        localStorage.setItem('user_profile', JSON.stringify(userProfile))
        setStep(4)
      } else {
        const userToken = payload?.token as string
        if (userToken) {
          localStorage.setItem('user_token', userToken)
          localStorage.setItem('user_profile', JSON.stringify(payload?.data ?? {}))
          setToken(userToken)
        }
        if (authIntent === 'signup' || payload?.meta?.needsProfile) {
          setStep(4)
        } else {
          localStorage.setItem('auth_provider', 'mobile-otp')
          navigate('/')
        }
      }
    } catch (verifyError) {
      setError(verifyError instanceof Error ? verifyError.message : 'OTP verification failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCompleteProfile = async () => {
    setError('')
    if (!profileForm.fullName || !profileForm.email || !profileForm.businessName || !profileForm.workType || !profileForm.city) {
      return setError('Please fill all required profile details.')
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(profileForm.email.trim())) {
      return setError('Please enter a valid email address.')
    }
    setStep(5)
  }

  const handleRegistrationPayment = async () => {
    setError('')
    setSuccess('')
    try {
      setIsLoading(true)
      const isRazorpayReady = await loadRazorpayScript()
      if (!isRazorpayReady || !window.Razorpay) {
        throw new Error('Unable to load payment gateway. Please retry.')
      }

      const orderResponse = await requestAuth('/mobile/create-registration-order', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token || localStorage.getItem('user_token') || ''}`,
        },
      })
      const orderPayload = await orderResponse.json()
      if (!orderResponse.ok || !orderPayload?.success) {
        throw new Error(orderPayload?.message ?? 'Unable to start payment.')
      }

      const { orderId, amount, currency, keyId } = orderPayload.data ?? {}
      if (!orderId || !amount || !currency || !keyId) {
        throw new Error('Invalid order response from server.')
      }

      const razorpay = new window.Razorpay({
        key: keyId,
        amount,
        currency,
        name: 'Leads Sell',
        description: 'Lifetime registration fee',
        order_id: orderId,
        image: '/logo.png',
        prefill: {
          name: profileForm.fullName,
          email: profileForm.email,
          contact: phoneNumber,
        },
        theme: {
          color: '#4B2CF5',
        },
        handler: async (paymentResponse: Record<string, string>) => {
          try {
            const verifyResponse = await requestAuth('/mobile/verify-registration-payment', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token || localStorage.getItem('user_token') || ''}`,
              },
              body: JSON.stringify({
                razorpayOrderId: paymentResponse.razorpay_order_id,
                razorpayPaymentId: paymentResponse.razorpay_payment_id,
                razorpaySignature: paymentResponse.razorpay_signature,
                ...profileForm,
                email: profileForm.email.trim().toLowerCase(),
              }),
            })
            const verifyPayload = await verifyResponse.json()
            if (!verifyResponse.ok || !verifyPayload?.success) {
              throw new Error(verifyPayload?.message ?? 'Payment verification failed.')
            }

            localStorage.setItem('user_profile', JSON.stringify(verifyPayload?.data ?? {}))
            localStorage.setItem('auth_provider', 'mobile-otp')
            setToastMessage('Registration successful! Payment received.')
            window.setTimeout(() => {
              navigate('/')
            }, 900)
          } catch (verifyError) {
            setError(
              verifyError instanceof Error
                ? verifyError.message
                : 'Payment completed but verification failed.',
            )
          } finally {
            setIsLoading(false)
          }
        },
      })

      razorpay.open()
    } catch (paymentError) {
      setError(paymentError instanceof Error ? paymentError.message : 'Unable to process payment.')
      setIsLoading(false)
    }
  }

  const handleOtpDigitChange = (index: number, rawValue: string) => {
    const value = rawValue.replace(/\D/g, '')
    if (!value) return

    setOtpDigits((prev) => {
      const next = [...prev]
      next[index] = value[0]
      return next
    })

    if (index < otpDigits.length - 1) {
      const nextInput = document.getElementById(`otp-input-${index + 1}`) as HTMLInputElement | null
      nextInput?.focus()
      nextInput?.select()
    }
  }

  const handleOtpKeyDown = (index: number, event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key !== 'Backspace') return

    if (otpDigits[index]) {
      setOtpDigits((prev) => {
        const next = [...prev]
        next[index] = ''
        return next
      })
      return
    }

    if (index > 0) {
      const prevInput = document.getElementById(`otp-input-${index - 1}`) as HTMLInputElement | null
      prevInput?.focus()
      setOtpDigits((prev) => {
        const next = [...prev]
        next[index - 1] = ''
        return next
      })
    }
  }

  useEffect(() => {
    if (step !== 4) return

    let isCancelled = false
    const fetchWorkTypes = async () => {
      try {
        setIsWorkTypeLoading(true)
        const response = await requestApi('/categories/get-all-categories', { method: 'GET' })
        const payload = await response.json()

        if (!response.ok || !payload?.success) {
          throw new Error(payload?.message ?? 'Unable to fetch work types.')
        }

        const options = Array.isArray(payload?.data)
          ? payload.data
              .map((item: { _id?: string; name?: string }) => ({
                id: item._id ?? item.name ?? '',
                label: (item.name ?? '').trim(),
              }))
              .filter((item: WorkTypeOption) => Boolean(item.id) && Boolean(item.label))
          : []

        if (isCancelled) return
        setWorkTypeOptions(options.length > 0 ? options : DEFAULT_WORK_TYPES)
      } catch {
        if (isCancelled) return
        setWorkTypeOptions(DEFAULT_WORK_TYPES)
      } finally {
        if (!isCancelled) setIsWorkTypeLoading(false)
      }
    }

    void fetchWorkTypes()

    return () => {
      isCancelled = true
    }
  }, [step])

  return (
    <div className="fixed inset-x-0 top-[74px] bottom-0 z-20 bg-black/35">
      {toastMessage ? (
        <div className="pointer-events-none fixed right-4 top-24 z-50 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-lg">
          {toastMessage}
        </div>
      ) : null}
      <div className="ml-auto h-full w-full max-w-[380px] overflow-y-auto bg-white p-6 sm:p-7">
          <div className="mb-3 flex items-center justify-between">
            {step > 0 ? (
              <button
                type="button"
                onClick={() => (step === 1 ? navigate('/') : setStep((prev) => Math.max(1, prev - 1)))}
                className="grid h-9 w-9 place-items-center rounded-full text-[#2e2a4f] hover:bg-[#f3efff]"
              >
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M15 18l-6-6 6-6" />
                </svg>
              </button>
            ) : (
              <span />
            )}
            <Link to="/" className="text-xs font-semibold text-[#8A89A2] hover:underline">
              Close
            </Link>
          </div>

          {step === 0 ? (
            <div className="flex min-h-[78dvh] flex-col items-center justify-between pb-8 pt-14">
              <div />
              <div className="text-center">
                <img src="/first.png" alt="Next Lead splash" className="mx-auto h-[440px] w-auto max-w-full object-contain" />
              </div>
              <div />
            </div>
          ) : null}

          {step > 0 ? (
            <>
          {step === 1 ? <h1 className="text-3xl font-bold text-[#1F1D35]">Welcome Back!</h1> : null}
          {step === 2 ? <h1 className="text-3xl font-bold text-[#1F1D35]">Verify Your Number</h1> : null}
          {step === 3 ? <h1 className="text-3xl font-bold text-[#1F1D35]">Enter OTP</h1> : null}
          {step === 4 ? <h1 className="text-3xl font-bold text-[#1F1D35]">Tell us about yourself</h1> : null}
          {step === 5 ? <h1 className="text-3xl font-bold text-[#1F1D35]">Complete Payment</h1> : null}

          {step === 1 ? <p className="mt-1 text-sm text-[#8A89A2]">Login to continue</p> : null}
          {step === 2 ? <p className="mt-1 text-sm text-[#8A89A2]">We will send you an OTP on this number</p> : null}
          {step === 3 ? <p className="mt-1 text-sm text-[#8A89A2]">We have sent a 6 digit OTP on +91 {phoneNumber}</p> : null}

          {error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p> : null}
          {success ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">{success}</p> : null}

          {step === 1 ? (
            <div className="mt-6 space-y-4">
              <div className="grid grid-cols-2 gap-2 rounded-xl bg-[#f5f3ff] p-1">
                <button
                  type="button"
                  onClick={() => setAuthIntent('login')}
                  className={`h-9 rounded-lg text-sm font-semibold transition ${
                    authIntent === 'login'
                      ? 'bg-white text-[#4B2CF5] shadow-sm'
                      : 'text-[#7A73A8] hover:text-[#4B2CF5]'
                  }`}
                >
                  Login
                </button>
                <button
                  type="button"
                  onClick={() => setAuthIntent('signup')}
                  className={`h-9 rounded-lg text-sm font-semibold transition ${
                    authIntent === 'signup'
                      ? 'bg-white text-[#4B2CF5] shadow-sm'
                      : 'text-[#7A73A8] hover:text-[#4B2CF5]'
                  }`}
                >
                  Signup
                </button>
              </div>
              <label className="block text-sm font-medium text-[#3A365F]">
                Enter Mobile Number
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
                onClick={() => setStep(2)}
                className="h-12 w-full rounded-xl bg-[#4B2CF5] text-sm font-semibold text-white hover:bg-[#3C20D9]"
              >
                Next
              </button>
              <p className="text-center text-sm text-[#8A89A2]">or</p>
              <button
                type="button"
                onClick={handleGoogleLogin}
                className="flex h-11 w-full items-center justify-center gap-2 rounded-xl border border-[#ded8f6] bg-[#f7f5ff] text-sm font-semibold text-[#4f4a73] transition hover:bg-[#f2efff]"
              >
                <svg viewBox="0 0 24 24" className="h-5 w-5" aria-hidden="true">
                  <path
                    fill="#EA4335"
                    d="M12.24 10.285v3.974h5.518c-.241 1.28-.964 2.365-2.053 3.094l3.318 2.576c1.934-1.783 3.047-4.407 3.047-7.524 0-.729-.066-1.43-.187-2.12h-9.643z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 22c2.76 0 5.075-.914 6.767-2.472l-3.318-2.576c-.922.617-2.1.982-3.449.982-2.652 0-4.899-1.79-5.702-4.198H2.87v2.641A10 10 0 0 0 12 22z"
                  />
                  <path
                    fill="#4A90E2"
                    d="M6.298 13.736A5.997 5.997 0 0 1 6 12c0-.603.103-1.188.298-1.736V7.623H2.87A10 10 0 0 0 2 12c0 1.62.389 3.152 1.08 4.377l3.218-2.64z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M12 6.066c1.5 0 2.847.516 3.907 1.529l2.93-2.93C17.07 3.02 14.755 2 12 2A10 10 0 0 0 3.08 7.623l3.218 2.64c.803-2.407 3.05-4.197 5.702-4.197z"
                  />
                </svg>
                Continue with Google
              </button>
            </div>
          ) : null}

          {step === 2 ? (
            <div className="mt-6 space-y-4">
              <div className="flex items-center rounded-xl border border-[#D9D7EC] px-3">
                <span className="text-sm text-[#777396]">+91</span>
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(event) => setPhoneNumber(event.target.value.replace(/\D/g, '').slice(0, 10))}
                  placeholder="98765 43210"
                  className="h-11 w-full border-0 bg-transparent px-2 text-sm outline-none"
                />
              </div>
              <button
                type="button"
                disabled={isLoading}
                onClick={() => void handleRequestOtp()}
                className="h-12 w-full rounded-xl bg-[#4B2CF5] text-sm font-semibold text-white hover:bg-[#3C20D9] disabled:opacity-70"
              >
                {isLoading ? 'Sending OTP...' : 'Send OTP'}
              </button>
            </div>
          ) : null}

          {step === 3 ? (
            <div className="mt-6 space-y-4">
              <div className="flex items-center justify-between gap-2">
                {otpDigits.map((digit, index) => (
                  <input
                    key={index}
                    id={`otp-input-${index}`}
                    type="text"
                    maxLength={1}
                    value={digit}
                    onChange={(event) => handleOtpDigitChange(index, event.target.value)}
                    onKeyDown={(event) => handleOtpKeyDown(index, event)}
                    className="h-12 w-12 rounded-xl border border-[#D9D7EC] text-center text-lg font-semibold text-[#1F1D35] outline-none focus:border-[#4B2CF5]"
                  />
                ))}
              </div>
              <button
                type="button"
                disabled={isLoading}
                onClick={() => void handleVerifyOtp()}
                className="h-12 w-full rounded-xl bg-[#4B2CF5] text-sm font-semibold text-white hover:bg-[#3C20D9] disabled:opacity-70"
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
                    className="font-semibold text-[#4B2CF5] hover:underline"
                  >
                    Didn&apos;t receive OTP? Resend
                  </button>
                )}
              </div>
            </div>
          ) : null}

          {step === 4 ? (
            <div className="mt-6 space-y-3">
              <input
                type="text"
                value={profileForm.fullName}
                onChange={(event) => setProfileForm((prev) => ({ ...prev, fullName: event.target.value }))}
                placeholder="Full Name"
                className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#4B2CF5]"
              />
              <input
                type="text"
                value={profileForm.businessName}
                onChange={(event) => setProfileForm((prev) => ({ ...prev, businessName: event.target.value }))}
                placeholder="Business / Company Name"
                className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#4B2CF5]"
              />
              <input
                type="email"
                value={profileForm.email}
                onChange={(event) => setProfileForm((prev) => ({ ...prev, email: event.target.value }))}
                placeholder="Email"
                className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#4B2CF5]"
              />
              <input
                type="text"
                value={profileForm.city}
                onChange={(event) => setProfileForm((prev) => ({ ...prev, city: event.target.value }))}
                placeholder="City"
                className="h-11 w-full rounded-xl border border-[#D9D7EC] px-3 text-sm outline-none focus:border-[#4B2CF5]"
              />
              <select
                value={profileForm.workType}
                onChange={(event) => setProfileForm((prev) => ({ ...prev, workType: event.target.value }))}
                className="h-11 w-full rounded-xl border border-[#D9D7EC] bg-white px-3 text-sm outline-none focus:border-[#4B2CF5]"
                disabled={isWorkTypeLoading}
              >
                <option value="">{isWorkTypeLoading ? 'Loading work types...' : 'Select Work Type'}</option>
                {workTypeOptions.map((option) => (
                  <option key={option.id} value={option.label}>
                    {option.label}
                  </option>
                ))}
              </select>
              <button
                type="button"
                disabled={isLoading}
                onClick={() => void handleCompleteProfile()}
                className="h-12 w-full rounded-xl bg-[#4B2CF5] text-sm font-semibold text-white hover:bg-[#3C20D9] disabled:opacity-70"
              >
                {isLoading ? 'Saving...' : 'Continue'}
              </button>
            </div>
          ) : null}
          {step === 5 ? (
            <div className="mt-6 space-y-4">
              <div className="rounded-2xl border border-[#ded8f6] bg-[#f7f5ff] p-4">
                <p className="text-xs font-semibold uppercase tracking-wider text-[#6f66ad]">
                  Lifetime Register Fee
                </p>
                <p className="mt-2 text-5xl font-black text-[#4B2CF5]">₹{REGISTRATION_AMOUNT_INR}</p>
                <p className="mt-1 text-xs font-semibold text-[#5b5678]">ONE TIME PAYMENT</p>
                <div className="mt-4 grid grid-cols-3 gap-2 text-center text-[11px] text-[#5d5980]">
                  <div className="rounded-xl bg-white p-2">
                    <p className="text-lg">🔒</p>
                    <p>Secure</p>
                  </div>
                  <div className="rounded-xl bg-white p-2">
                    <p className="text-lg">✅</p>
                    <p>No Hidden</p>
                  </div>
                  <div className="rounded-xl bg-white p-2">
                    <p className="text-lg">👥</p>
                    <p>Trusted</p>
                  </div>
                </div>
              </div>
              <button
                type="button"
                disabled={isLoading}
                onClick={() => void handleRegistrationPayment()}
                className="h-12 w-full rounded-xl bg-[#4B2CF5] text-sm font-semibold text-white hover:bg-[#3C20D9] disabled:opacity-70"
              >
                {isLoading ? 'Processing...' : `Pay ₹${REGISTRATION_AMOUNT_INR} Securely`}
              </button>
            </div>
          ) : null}
          {stepImageByScreen[step] ? (
            <div className="mt-5 overflow-hidden rounded-2xl border border-[#ebe6ff] bg-[#f7f4ff]">
              <img
                src={stepImageByScreen[step]}
                alt="Authentication visual"
                className="h-32 w-full object-cover"
                loading="lazy"
                referrerPolicy="no-referrer"
              />
            </div>
          ) : null}
            </>
          ) : null}
      </div>
    </div>
  )
}

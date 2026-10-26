import { apiFetch } from '@/features/auth/session'
import { ProfileCompletionForm } from './ProfileCompletionForm'
import { Navigate } from 'react-router-dom'

import { API_BASE_URL } from '@/config/api'
import { useEffect, useState, type KeyboardEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'


const API_BASE_URL_CANDIDATES = [API_BASE_URL]
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
  const isMembershipFlow = searchParams.get('flow') === 'membership'
  const isGoogleOnboardingFlow = searchParams.get('flow') === 'google'
  const [step, setStep] = useState(isMembershipFlow ? 5 : isGoogleOnboardingFlow ? 4 : searchParams.get('method') === 'phone' ? 2 : 1)
  const [authIntent, setAuthIntent] = useState<'login' | 'signup'>('login')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', ''])
  const [token, setToken] = useState('')
  const [referralCode, setReferralCode] = useState(() => searchParams.get('ref')?.trim().toUpperCase() || sessionStorage.getItem('pending_referral_code') || '')
  useEffect(() => {
    const code = searchParams.get('ref')?.trim().toUpperCase()
    if (code) { sessionStorage.setItem('pending_referral_code', code); setReferralCode(code) }
  }, [searchParams])
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
    if (!isGoogleOnboardingFlow && !isMembershipFlow) return

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

    if (hasProfile && !sessionStorage.getItem('pending_referral_code') && (!isMembershipFlow || profile.registrationFeePaid)) {
      navigate('/', { replace: true })
    } else {
      setStep(isMembershipFlow ? 5 : 4)
    }
  }, [isGoogleOnboardingFlow, isMembershipFlow, searchParams, navigate])

  useEffect(() => {
    if (!toastMessage) return
    const timer = window.setTimeout(() => setToastMessage(''), 2600)
    return () => window.clearTimeout(timer)
  }, [toastMessage])

  const requestApi = async (path: string, init?: RequestInit) => {
    let lastError: Error | null = null
    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        return await apiFetch(`${baseUrl}/api/v1${path}`, init)
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
          localStorage.setItem('has_signed_in', '1')
          window.dispatchEvent(new Event('user-session-changed'))
          localStorage.setItem('user_profile', JSON.stringify(payload?.data ?? {}))
          setToken(userToken)
        }
        if (authIntent === 'signup' || payload?.meta?.needsProfile || referralCode.trim()) {
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
    if (isLoading) return
    setError('')
    if (!profileForm.fullName || !profileForm.email || !profileForm.businessName || !profileForm.workType || !profileForm.city) {
      return setError('Please fill all required profile details.')
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(profileForm.email.trim())) {
      return setError('Please enter a valid email address.')
    }
    try {
      setIsLoading(true)
      const code = referralCode.trim().toUpperCase()
      if (code) {
        const referralResponse = await requestApi('/referrals/apply', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + (token || localStorage.getItem('user_token') || '') },
          body: JSON.stringify({ referralCode: code }),
        })
        const referralPayload = await referralResponse.json()
        if (!referralResponse.ok || referralPayload?.success !== true) {
          throw new Error(referralPayload?.message || 'Unable to apply referral code.')
        }
        sessionStorage.removeItem('pending_referral_code')
      }
      const response = await requestAuth('/mobile/complete-profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + (token || localStorage.getItem('user_token') || '') },
        body: JSON.stringify(profileForm),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.success) throw new Error(payload?.message || 'Unable to save profile.')
      localStorage.setItem('user_profile', JSON.stringify(payload.data))
      navigate('/')
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Unable to save profile.')
    } finally { setIsLoading(false) }
  }

  const handleRegistrationPayment = async () => {
    if (isLoading) return
    setError(''); setSuccess(''); setIsLoading(true)
    try {
      const response = await apiFetch(API_BASE_URL + '/api/v1/wallet/membership', {
        method: 'POST', headers: { Authorization: 'Bearer ' + (token || localStorage.getItem('user_token') || '') },
      })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to activate membership from your wallet.')
      const profileResponse = await requestAuth('/profile', { headers: { Authorization: 'Bearer ' + (token || localStorage.getItem('user_token') || '') } })
      if (profileResponse.ok) { const profile = await profileResponse.json(); if (profile.success) localStorage.setItem('user_profile', JSON.stringify(profile.data)) }
      setToastMessage('Lifetime membership activated using your wallet!')
      navigate('/')
    } catch (error) { setError(error instanceof Error ? error.message : 'Wallet payment failed.') }
    finally { setIsLoading(false) }
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

  if (step === 0 || step === 1) return <Navigate to={`/login${searchParams.size ? `?${searchParams}` : ''}`} replace />

  if (step === 4) {
    return (
      <ProfileCompletionForm
        details={profileForm}
        onChange={(field, value) => setProfileForm(previous => ({ ...previous, [field]: value }))}
        workTypes={workTypeOptions}
        isWorkTypeLoading={isWorkTypeLoading}
        referralCode={referralCode}
        onReferralChange={value => {
          const code = value.toUpperCase()
          setReferralCode(code)
          if (code.trim()) sessionStorage.setItem('pending_referral_code', code.trim())
          else sessionStorage.removeItem('pending_referral_code')
        }}
        onContinue={handleCompleteProfile}
        isLoading={isLoading}
        error={error}
        success={success}
      />
    )
  }

  return (
    <div className="min-h-[70vh] bg-[#f8fafc] px-4 py-8 sm:py-12">
      {toastMessage ? (
        <div role="status" className="mx-auto mb-4 max-w-xl rounded-xl bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-800">
          {toastMessage}
        </div>
      ) : null}
      <div className="mx-auto w-full max-w-xl rounded-3xl border border-stone-200 bg-white p-6 shadow-sm sm:p-8">
          <div className="mb-3 flex items-center justify-between">
            {step > 0 ? (
              <button
                type="button"
                onClick={() => {
                  setError(''); setSuccess('')
                  if (step === 1 || (isGoogleOnboardingFlow && step === 4) || isMembershipFlow) navigate('/')
                  else if (step === 4) setStep(2)
                  else setStep((prev) => Math.max(1, prev - 1))
                }}
                className="grid h-9 w-9 place-items-center rounded-full text-[#2e2a4f] hover:bg-[#f3efff]"
              >
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M15 18l-6-6 6-6" />
                </svg>
              </button>
            ) : (
              <span />
            )}
            <Link to="/" className="text-xs font-semibold text-[#7a8fae] hover:underline">
              Close
            </Link>
          </div>
          {step === 2 ? <h1 className="text-3xl font-bold text-[#13233d]">Verify Your Number</h1> : null}
          {step === 3 ? <h1 className="text-3xl font-bold text-[#13233d]">Enter OTP</h1> : null}
          {step === 5 ? <h1 className="text-3xl font-bold text-[#13233d]">Lifetime membership</h1> : null}
          {referralCode && step < 4 && <p className="mt-3 break-all rounded-xl bg-violet-50 p-3 text-sm text-violet-800">Invitation code: {referralCode}. It will be filled in during profile setup.</p>}
          {step === 2 ? <p className="mt-1 text-sm text-[#7a8fae]">We will send you an OTP on this number</p> : null}
          {step === 3 ? <p className="mt-1 text-sm text-[#7a8fae]">We have sent a 6 digit OTP on +91 {phoneNumber}</p> : null}

          {error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p> : null}
          {success ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">{success}</p> : null}

          {step === 2 ? (
            <div className="mt-6 space-y-4">
              <div className="grid grid-cols-2 gap-2 rounded-xl bg-[#f5f3ff] p-1">
                <button
                  type="button"
                  onClick={() => setAuthIntent('login')}
                  className={`h-9 rounded-lg text-sm font-semibold transition ${
                    authIntent === 'login'
                      ? 'bg-white text-[#0066ff] shadow-sm'
                      : 'text-[#7A73A8] hover:text-[#0066ff]'
                  }`}
                >
                  Login
                </button>
                <button
                  type="button"
                  onClick={() => setAuthIntent('signup')}
                  className={`h-9 rounded-lg text-sm font-semibold transition ${
                    authIntent === 'signup'
                      ? 'bg-white text-[#0066ff] shadow-sm'
                      : 'text-[#7A73A8] hover:text-[#0066ff]'
                  }`}
                >
                  Signup
                </button>
              </div>

              <div className="flex items-center rounded-xl border border-[#d5e1f0] px-3">
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
                className="h-12 w-full rounded-xl bg-[#0066ff] text-sm font-semibold text-white hover:bg-[#0050cb] disabled:opacity-70"
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
                    className="h-12 w-12 rounded-xl border border-[#d5e1f0] text-center text-lg font-semibold text-[#13233d] outline-none focus:border-[#0066ff]"
                  />
                ))}
              </div>
              <button
                type="button"
                disabled={isLoading}
                onClick={() => void handleVerifyOtp()}
                className="h-12 w-full rounded-xl bg-[#0066ff] text-sm font-semibold text-white hover:bg-[#0050cb] disabled:opacity-70"
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
                    className="font-semibold text-[#0066ff] hover:underline"
                  >
                    Didn&apos;t receive OTP? Resend
                  </button>
                )}
              </div>
            </div>
          ) : null}

          {step === 5 ? (
            <div className="mt-6 space-y-4">
              <p className="text-sm text-[#536b8b]">Pay ₹499 once before your first lead purchase. Lifetime access, no recurring subscription. Each lead is purchased separately.</p>
              <div className="rounded-2xl border border-[#dce5f2] bg-[#f1f7ff] p-4">
                <p className="text-xs font-semibold uppercase tracking-wider text-[#627898]">
                  Lifetime membership
                </p>
                <p className="mt-2 text-5xl font-black text-[#0066ff]">₹{REGISTRATION_AMOUNT_INR}</p>
                <p className="mt-1 text-xs font-semibold text-[#627898]">ONE TIME PAYMENT</p>
                <div className="mt-4 grid grid-cols-3 gap-2 text-center text-[11px] text-[#627898]">
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
                className="h-12 w-full rounded-xl bg-[#0066ff] text-sm font-semibold text-white hover:bg-[#0050cb] disabled:opacity-70"
              >
                {isLoading ? 'Processing...' : `Pay ₹${REGISTRATION_AMOUNT_INR} from wallet`}
              </button>
              <button type="button" disabled={isLoading} onClick={() => navigate('/wallet')} className="mt-3 w-full rounded-xl border border-amber-300 py-3 text-sm font-semibold">Add money to wallet</button>
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
      </div>
    </div>
  )
}

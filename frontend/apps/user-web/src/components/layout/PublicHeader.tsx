import './cart.css'
import './signup.css'
import { animateWindowClose } from './motion'
import { apiFetch } from '@/features/auth/session'
import { startGoogleLogin } from '@/features/auth/googleHandoff'
import { createPortal } from 'react-dom'
import { API_BASE_URL } from '@/config/api'
import { notifyUserSessionChanged, useUserToken } from '@/features/auth/useUserToken'
import './my-leads.css'
import { MarketplaceHeader } from './MarketplaceHeader'
import { RowsSkeleton } from '@/components/loading/Skeleton'
import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'

const API_BASE_URL_CANDIDATES = [API_BASE_URL]

const buildAuthUrl = (apiBaseUrl: string, path: string) =>
  `${apiBaseUrl}/api/v1/auth${path}`
const buildApiUrl = (apiBaseUrl: string, path: string) => `${apiBaseUrl}/api/v1${path}`
const getLeadPreviewImage = (id: string) => {
  const lastChar = id?.slice(-1) ?? ''
  const parsed = Number.parseInt(lastChar, 16)
  const index = Number.isNaN(parsed) ? 1 : (parsed % 3) + 1
  return `/lead-room-${index}.jpg`
}

declare global {
  interface RazorpayCheckout {
    open: () => void
    on: (event: string, callback: (response: Record<string, unknown>) => void) => void
  }
  interface Window {
    Razorpay?: new (options: Record<string, unknown>) => RazorpayCheckout
  }
}

type HistoryLead = {
  id: string
  orderId: string
  title: string
  city: string
  customerName: string
  address: string
  phone: string
  price: number
  quantity: number
  status: string
  isDownloaded: boolean
  paidAt: string
}

type HistoryApiOrder = {
  orderId?: string
  status?: string
  isDownloaded?: boolean
  paidAt?: string
  items?: Array<{
    leadId?: string
    title?: string
    city?: string
    customerName?: string
    address?: string
    phone?: string
    price?: number
    quantity?: number
  }>
}

type CartLead = {
  _id: string
  title: string
  price: number
  quantity: number
  city: string
  state: string
  remainingSlots: number
  totalSlots: number
  expiresAt: string
}

type Category = {
  _id: string
  name: string
  icon?: string
}

type City = {
  _id: string
  name: string
}

export function PublicHeader() {
  const navigate = useNavigate()
  const pathname = useLocation().pathname

  const pagePaths = { history: '/my-leads', cart: '/cart', login: '/login', signup: '/signup', 'forgot-email': '/forgot-password', 'forgot-otp': '/forgot-password/verify', 'forgot-reset': '/forgot-password/reset' } as const
  type PanelMode = keyof typeof pagePaths
  const panelMode = (Object.keys(pagePaths) as PanelMode[]).find(mode => pagePaths[mode] === pathname) ?? null
  const setPanelMode = (mode: PanelMode | null) => { navigate(mode ? pagePaths[mode] : '/') }
  const [pageContainer, setPageContainer] = useState<HTMLElement | null>(null)
  useEffect(() => { setPageContainer(document.getElementById('account-page-content')) }, [])
  useEffect(() => { window.scrollTo(0, 0) }, [pathname])
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [authError, setAuthError] = useState('')
  const [authSuccess, setAuthSuccess] = useState('')
  const [loginForm, setLoginForm] = useState({
    email: '',
    password: '',
    rememberMe: false,
  })
  const [signupForm, setSignupForm] = useState({
    firstname: '',
    lastname: '',
    phoneNumber: '',
    email: '',
    password: '',
    confirmPassword: '',
    rememberMe: false,
  })
  const [forgotForm, setForgotForm] = useState({
    email: '',
    otpDigits: ['', '', '', ''],
    newPassword: '',
    confirmPassword: '',
  })
  const [historyLeads, setHistoryLeads] = useState<HistoryLead[]>([])
  const [isHistoryLoading, setIsHistoryLoading] = useState(false)
  const [cartLeads, setCartLeads] = useState<CartLead[]>([])
  const [removedCartLeads, setRemovedCartLeads] = useState<{ _id: string; title: string; reason: string }[]>(
    [],
  )
  const [cartSummary, setCartSummary] = useState({ totalItems: 0, totalAmount: 0 })
  const [isCartLoading, setIsCartLoading] = useState(false)
  const [isPaymentProcessing, setIsPaymentProcessing] = useState(false)
  const [downloadOrderId, setDownloadOrderId] = useState<string | null>(null)
  const [isDownloadPopupOpen, setIsDownloadPopupOpen] = useState(false)
  const [categories, setCategories] = useState<Category[]>([])
  const [cities, setCities] = useState<City[]>([])
  const [isCategoriesLoading, setIsCategoriesLoading] = useState(false)
  const [isCitiesLoading, setIsCitiesLoading] = useState(false)
  const [isCategoryDropdownOpen, setIsCategoryDropdownOpen] = useState(false)
  const [isCityDropdownOpen, setIsCityDropdownOpen] = useState(false)
  useEffect(() => {
    setIsCategoryDropdownOpen(false)
    setIsCityDropdownOpen(false)
    setIsMobileMenuOpen(false)
  }, [pathname])
  const isPanelOpen = panelMode !== null
  const userToken = useUserToken()
  const resetAuthMessages = useCallback(() => {
    setAuthError('')
    setAuthSuccess('')
  }, [])

  const requestAuth = async (path: string, init?: RequestInit) => {
    return requestApi(`/auth${path}`, init)
  }

  const requestApi = useCallback(async (path: string, init?: RequestInit) => {
    let lastNetworkError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        return await apiFetch(buildApiUrl(baseUrl, path), { ...init, signal: init?.signal ?? ((init?.method ?? 'GET') === 'GET' ? AbortSignal.timeout(15000) : undefined) })
      } catch (error) {
        lastNetworkError =
          error instanceof Error ? error : new Error('Unable to connect to auth server.')
      }
    }

    throw lastNetworkError ?? new Error('Unable to connect to auth server.')
  }, [])

  const storeUserSession = (token: string, user?: unknown) => {
    localStorage.setItem('user_token', token)
    notifyUserSessionChanged()
    if (user) {
      localStorage.setItem('user_profile', JSON.stringify(user))
    }
  }

  const handleLoginSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (!loginForm.email || !loginForm.password) {
      setAuthError('Email and password are required.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: loginForm.email,
          password: loginForm.password,
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Login failed. Please try again.')
      }

      if (payload?.token) {
        storeUserSession(payload.token, payload?.data)
      }
      setAuthSuccess(payload?.message ?? 'Logged in successfully.')
      setIsMobileMenuOpen(false)
      setPanelMode(null)
                navigate('/profile')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Login failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleSignupSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (
      !signupForm.firstname ||
      !signupForm.lastname ||
      !signupForm.phoneNumber ||
      !signupForm.email ||
      !signupForm.password
    ) {
      setAuthError('Please fill all required fields.')
      return
    }
    if (signupForm.password !== signupForm.confirmPassword) {
      setAuthError('Password and confirm password must match.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          firstname: signupForm.firstname,
          lastname: signupForm.lastname,
          email: signupForm.email,
          phoneNumber: signupForm.phoneNumber,
          password: signupForm.password,
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Signup failed. Please try again.')
      }

      setAuthSuccess(payload?.message ?? 'Signup successful. Please login now.')
      setPanelMode('login')
      setLoginForm((prev) => ({ ...prev, email: signupForm.email }))
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Signup failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = () => {
    resetAuthMessages()
    const googleAuthUrl = buildAuthUrl(API_BASE_URL_CANDIDATES[0], '/google')
    void startGoogleLogin(googleAuthUrl).catch(() => setAuthError('Unable to start Google login.'))
  }

  const fetchHistoryLeads = useCallback(async () => {
    if (!userToken) return

    try {
      setIsHistoryLoading(true)
      resetAuthMessages()
      const response = await requestApi('/leads/history', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to load purchase history.')
      }

      const orders = Array.isArray(payload?.data) ? (payload.data as HistoryApiOrder[]) : []
      const flattened: HistoryLead[] = orders.flatMap((order) => {
        const orderId = order?.orderId ?? ''
        const status = order?.status ?? 'PAID'
        const isDownloaded = Boolean(order?.isDownloaded)
        const paidAt = order?.paidAt ?? new Date().toISOString()
        const items = Array.isArray(order?.items) ? order.items : []

        return items.map((item, index) => ({
          id: item?.leadId || `${orderId}-${index}`,
          orderId,
          title: item?.title ?? 'Lead',
          city: item?.city ?? 'N/A',
          customerName: item?.customerName ?? 'N/A',
          address: item?.address ?? 'N/A',
          phone: item?.phone ?? 'N/A',
          price: Number(item?.price) || 0,
          quantity: Number(item?.quantity) || 1,
          status,
          isDownloaded,
          paidAt,
        }))
      })

      setHistoryLeads(flattened)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to load purchase history.')
    } finally {
      setIsHistoryLoading(false)
    }
  }, [userToken, requestApi, resetAuthMessages])

  const fetchCart = useCallback(async () => {
    if (!userToken) {
      setCartLeads([])
      setRemovedCartLeads([])
      setCartSummary({ totalItems: 0, totalAmount: 0 })
      return
    }

    try {
      setIsCartLoading(true)
      resetAuthMessages()
      const response = await requestApi('/cart/get-cart', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to load cart.')
      }

      const data = payload?.data ?? {}
      setCartLeads(Array.isArray(data.leads) ? data.leads : [])
      setRemovedCartLeads(previous => Array.from(new Map([
        ...previous,
        ...(Array.isArray(data.removedLeads) ? data.removedLeads : []),
      ].map(lead => [lead._id, lead])).values()))
      setCartSummary({
        totalItems: Number(data.totalItems) || 0,
        totalAmount: Number(data.totalAmount) || 0,
      })
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to load cart.')
    } finally {
      setIsCartLoading(false)
    }
  }, [userToken, requestApi, resetAuthMessages])

  const handleAddCartQuantity = async (leadId: string) => {
    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      resetAuthMessages()
      const response = await requestApi('/cart/add-cart', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({ leadId, quantity: 1 }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to update cart.')
      }

      setAuthSuccess(payload?.message ?? 'Cart updated successfully.')
      await fetchCart()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to update cart.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleRemoveCartQuantity = async (leadId: string) => {
    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      resetAuthMessages()
      const response = await requestApi('/cart/delete-cart-item', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({ leadId, quantity: 1 }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to update cart.')
      }

      setAuthSuccess(payload?.message ?? 'Cart updated successfully.')
      await fetchCart()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to update cart.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleDeleteCartItem = async (leadId: string, quantity: number) => {
    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      resetAuthMessages()
      const response = await requestApi('/cart/delete-cart-item', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({ leadId, quantity }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to delete cart item.')
      }

      setAuthSuccess(payload?.message ?? 'Cart updated successfully.')
      await fetchCart()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to delete cart item.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleClearCart = async () => {
    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      resetAuthMessages()
      const response = await requestApi('/cart/delete-cart', {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to clear cart.')
      }

      setAuthSuccess(payload?.message ?? 'Cart cleared successfully.')
      await fetchCart()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to clear cart.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleProceedToPay = async () => {
    if (isPaymentProcessing) return
    if (!userToken) { setAuthError('Please login first.'); setPanelMode('login'); return }
    if (!cartLeads.length) { setAuthError('Your cart is empty.'); return }
    setIsPaymentProcessing(true)
    resetAuthMessages()
    try {
      const response = await requestApi('/wallet/purchase', {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + userToken, 'Content-Type': 'application/json' },
        body: JSON.stringify({ leadIds: cartLeads.map(lead => lead._id), expectedTotalPaise: Math.round(cartLeads.reduce((total, lead) => total + lead.price, 0) * 100) }),
      })
      const payload = await response.json()
      if (payload.code === 'MEMBERSHIP_REQUIRED') { setPanelMode(null); navigate('/auth/mobile?flow=membership'); return }
      if (payload.code === 'INSUFFICIENT_BALANCE') { setAuthError('Add money to your wallet before purchasing.'); setPanelMode(null); navigate('/wallet'); return }
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Wallet purchase failed.')
      setAuthSuccess('Paid from your wallet. Your leads are ready.')
      await fetchCart()
      setPanelMode('history')
      await fetchHistoryLeads()
      const orderId = payload.data?.orderId
      if (orderId) { setDownloadOrderId(String(orderId)) }
    } catch (error) {
      await fetchCart()
      setAuthError(error instanceof Error ? error.message : 'Wallet purchase failed. Review your cart before retrying.')
    }
    finally { setIsPaymentProcessing(false) }
  }

  const handleDownloadLead = async (orderId: string) => {
    if (!userToken) {
      setAuthError('Please login first.')
      return
    }

    try {
      setIsLoading(true)
      resetAuthMessages()
      const response = await requestApi(`/leads/download/${orderId}`, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })

      if (!response.ok) {
        let message = 'Unable to download leads.'
        try {
          const errorPayload = await response.json()
          message = errorPayload?.message ?? message
        } catch {
          // non-json response
        }
        throw new Error(message)
      }

      const blob = await response.blob()
      const contentDisposition = response.headers.get('content-disposition') ?? ''
      const filenameMatch = /filename="?([^"]+)"?/i.exec(contentDisposition)
      const filename = filenameMatch?.[1] ?? `leads-${orderId}.xlsx`

      const objectUrl = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = objectUrl
      link.download = filename
      document.body.appendChild(link)
      link.click()
      link.remove()
      URL.revokeObjectURL(objectUrl)

      // Reflect one-time download state immediately in history UI.
      setHistoryLeads((prev) =>
        prev.map((lead) =>
          (lead.orderId || lead.id) === orderId ? { ...lead, isDownloaded: true } : lead,
        ),
      )
      setAuthSuccess('Leads downloaded successfully.')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Download failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleDownloadAfterPayment = async () => {
    if (!downloadOrderId) {
      setAuthError('Order ID missing for download.')
      return
    }

    await handleDownloadLead(downloadOrderId)
    setIsDownloadPopupOpen(false)
    setPanelMode('history')
    void fetchHistoryLeads()
  }

  const handleLogout = async () => {
    resetAuthMessages()
    try {
      if (userToken) {
        await requestAuth('/logout', {
          method: 'GET',
          headers: { Authorization: `Bearer ${userToken}` },
        })
      }
    } catch {
      // Ignore logout API errors and clear local session anyway.
    } finally {
      localStorage.removeItem('user_token')
      notifyUserSessionChanged()
      localStorage.removeItem('user_profile')
      sessionStorage.clear()

      // Best-effort cleanup for browser-managed cache storage.
      try {
        if ('caches' in window) {
          const cacheKeys = await window.caches.keys()
          await Promise.all(cacheKeys.map((cacheKey) => window.caches.delete(cacheKey)))
        }
      } catch {
        // Ignore cache cleanup errors.
      }

      setCartLeads([])
      setRemovedCartLeads([])
      setCartSummary({ totalItems: 0, totalAmount: 0 })
      setHistoryLeads([])
      setPanelMode(null)
      setIsMobileMenuOpen(false)
      navigate('/auth/mobile')
    }
  }

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    if (params.get('gauth') !== '1') return
    const code = new URLSearchParams(window.location.hash.slice(1)).get('oauth_code')
    const verifier = sessionStorage.getItem('google_verifier')
    const googleError = params.get('error')
    window.history.replaceState({}, '', window.location.pathname)
    if (googleError || !code || !verifier) { setAuthError(googleError || 'Google login expired. Please retry.'); return }
    sessionStorage.removeItem('google_verifier')
    void (async () => {
      try {
        const response = await requestApi('/auth/google/exchange', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ code, verifier }) })
        const payload = await response.json()
        if (!response.ok || !payload.success || !payload.token) throw new Error('Login exchange failed')
        storeUserSession(payload.token, payload.data)
        setIsMobileMenuOpen(false)
        const profile = payload.data
        if (sessionStorage.getItem('pending_referral_code') || !profile.firstname || !profile.email || !profile.city || !profile.businessName || !profile.workType) navigate('/auth/mobile?flow=google', { replace: true })
        else { setAuthSuccess('Logged in successfully using Google.'); navigate('/', { replace: true }) }
      } catch { setAuthError('Unable to complete Google login. Please retry.'); navigate('/', { replace: true }) }
    })()
  }, [navigate, requestApi])

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        setIsCategoriesLoading(true)
        const response = await requestApi('/categories/get-all-categories')
        const payload = await response.json()
        if (response.ok && payload?.success) {
          setCategories(payload?.data || [])
        }
      } catch (error) {
        console.error('Failed to fetch categories:', error)
      } finally {
        setIsCategoriesLoading(false)
      }
    }
    fetchCategories()
  }, [requestApi])

  useEffect(() => {
    const fetchCities = async () => {
      try {
        setIsCitiesLoading(true)
        const response = await requestApi('/cities/get-all-cities')
        const payload = await response.json()
        if (response.ok && payload?.success) {
          setCities(payload?.data || [])
        }
      } catch (error) {
        console.error('Failed to fetch cities:', error)
      } finally {
        setIsCitiesLoading(false)
      }
    }
    fetchCities()
  }, [requestApi])

  useEffect(() => {
    if (panelMode === 'history' && userToken) {
      void fetchHistoryLeads()
    }
  }, [panelMode, userToken, fetchHistoryLeads])

  useEffect(() => {
    if (panelMode === 'cart' && userToken) {
      void fetchCart()
    }
  }, [panelMode, userToken, fetchCart])

  useEffect(() => {
    if (userToken) {
      void fetchCart()
    } else {
      setCartLeads([])
      setRemovedCartLeads([])
      setCartSummary({ totalItems: 0, totalAmount: 0 })
    }
  }, [userToken, fetchCart])

  useEffect(() => {
    if (!userToken) return

    const handleCartUpdated = () => {
      void fetchCart()
    }

    window.addEventListener('cart:updated', handleCartUpdated)
    return () => {
      window.removeEventListener('cart:updated', handleCartUpdated)
    }
  }, [userToken, fetchCart])

  const handleForgotPasswordRequest = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (!forgotForm.email) {
      setAuthError('Please enter your email ID.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotForm.email }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to send OTP right now.')
      }

      setAuthSuccess(payload?.message ?? 'OTP sent successfully.')
      setPanelMode('forgot-otp')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to send OTP.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleVerifyOtp = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    const otp = forgotForm.otpDigits.join('')
    if (!forgotForm.email || otp.length !== 4) {
      setAuthError('Please enter a valid 4-digit OTP.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotForm.email, otp }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Invalid OTP.')
      }

      setAuthSuccess(payload?.message ?? 'OTP verified successfully.')
      setPanelMode('forgot-reset')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'OTP verification failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleResendOtp = async () => {
    resetAuthMessages()

    if (!forgotForm.email) {
      setAuthError('Please enter your email ID first.')
      setPanelMode('forgot-email')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotForm.email }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to resend OTP.')
      }

      setAuthSuccess(payload?.message ?? 'OTP sent successfully')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to resend OTP.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleResetForgotPassword = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (!forgotForm.newPassword || !forgotForm.confirmPassword) {
      setAuthError('Please fill both password fields.')
      return
    }
    if (forgotForm.newPassword !== forgotForm.confirmPassword) {
      setAuthError('New password and confirm password must match.')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: forgotForm.email,
          otp: forgotForm.otpDigits.join(''),
          newPassword: forgotForm.newPassword,
          confirmPassword: forgotForm.confirmPassword,
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to reset password.')
      }

      setAuthSuccess(payload?.message ?? 'Password updated successfully. Please login.')
      setLoginForm((prev) => ({ ...prev, email: forgotForm.email }))
      setPanelMode('login')
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Password reset failed.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <>
      {userToken && <header className="marketplace-header">
        <MarketplaceHeader loggedIn={Boolean(userToken)} cartCount={cartSummary.totalItems} onLogout={() => { void handleLogout() }} />

        {isMobileMenuOpen ? (
          <div className="max-h-[calc(100dvh-130px)] overflow-y-auto border-t border-stone-200 bg-white px-4 py-3 xl:hidden">
            <nav className="space-y-2">
              <NavLink
                to="/download"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) => `block rounded-xl px-3 py-2 text-sm font-semibold ${isActive ? 'bg-[#0066ff] text-white' : 'text-stone-700 hover:bg-stone-100'}`}
              >
                Download App
              </NavLink>
              <NavLink
                to="/"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `block rounded-xl px-3 py-2 text-sm font-semibold ${
                    isActive ? 'bg-[#0066ff] text-white' : 'text-stone-700 hover:bg-stone-100'
                  }`
                }
              >
                Home
              </NavLink>
              {!userToken ? (
                <NavLink
                  to="/auth/mobile"
                  onClick={() => setIsMobileMenuOpen(false)}
                  className={({ isActive }) =>
                    `block rounded-xl px-3 py-2 text-sm font-semibold ${
                      isActive ? 'bg-[#0066ff] text-white' : 'text-[#0066ff] hover:bg-[#F3EEFF]'
                    }`
                  }
                >
                  Login / Signup
                </NavLink>
              ) : null}
              
              <div className="space-y-1">
                <button
                  type="button"
                  onClick={() => { setIsCategoryDropdownOpen(!isCategoryDropdownOpen); setIsCityDropdownOpen(false) }}
                  className="flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-sm font-semibold text-stone-700 hover:bg-stone-100"
                >
                  <span>Categories</span>
                  <svg viewBox="0 0 24 24" className={`h-4 w-4 transition-transform ${isCategoryDropdownOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {isCategoryDropdownOpen && (
                  <div className="pl-6 space-y-1">
                    {isCategoriesLoading ? (
                      <div className="px-3 py-2 text-sm text-stone-500">Loading...</div>
                    ) : categories.length > 0 ? (
                      categories.map((category) => (
                        <NavLink
                          key={category._id}
                          to={`/?category=${category._id}`}
                          onClick={() => setIsMobileMenuOpen(false)}
                          className={({ isActive }) =>
                            `block rounded-lg px-3 py-2 text-sm font-medium ${
                              isActive ? 'bg-stone-200 text-stone-900' : 'text-stone-600 hover:bg-stone-50'
                            }`
                          }
                        >
                          <div className="flex items-center gap-2">
                            {category.icon && (
                              category.icon.startsWith('http') ? (
                                <img src={category.icon} alt="" className="h-5 w-5 object-contain opacity-80" />
                              ) : (
                                <span className="text-lg">{category.icon}</span>
                              )
                            )}
                            <span>{category.name}</span>
                          </div>
                        </NavLink>
                      ))
                    ) : (
                      <div className="px-3 py-2 text-sm text-stone-500">No categories</div>
                    )}
                  </div>
                )}
              </div>
              <div className="space-y-1">
                <button
                  type="button"
                  onClick={() => { setIsCityDropdownOpen(!isCityDropdownOpen); setIsCategoryDropdownOpen(false) }}
                  className="flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-sm font-semibold text-stone-700 hover:bg-stone-100"
                >
                  <span>Cities</span>
                  <svg
                    viewBox="0 0 24 24"
                    className={`h-4 w-4 transition-transform ${isCityDropdownOpen ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {isCityDropdownOpen ? (
                  <div className="pl-6 space-y-1">
                    {isCitiesLoading ? (
                      <div className="px-3 py-2 text-sm text-stone-500">Loading...</div>
                    ) : cities.length > 0 ? (
                      cities.map((city) => (
                        <NavLink
                          key={city._id}
                          to={`/?city=${encodeURIComponent(city.name)}`}
                          onClick={() => setIsMobileMenuOpen(false)}
                          className={({ isActive }) =>
                            `block rounded-lg px-3 py-2 text-sm font-medium ${
                              isActive ? 'bg-stone-200 text-stone-900' : 'text-stone-600 hover:bg-stone-50'
                            }`
                          }
                        >
                          {city.name}
                        </NavLink>
                      ))
                    ) : (
                      <div className="px-3 py-2 text-sm text-stone-500">No cities</div>
                    )}
                  </div>
                ) : null}
              </div>

              <NavLink
                to="/pricing"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `block rounded-xl px-3 py-2 text-sm font-semibold ${
                    isActive ? 'bg-[#0066ff] text-white' : 'text-stone-700 hover:bg-stone-100'
                  }`
                }
              >
                About Us
              </NavLink>
              <NavLink
                to="/contact"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `block rounded-xl px-3 py-2 text-sm font-semibold ${
                    isActive ? 'bg-[#0066ff] text-white' : 'text-stone-700 hover:bg-stone-100'
                  }`
                }
              >
                Contact Us
              </NavLink>
              <div className="pt-2">
                {userToken ? (
                  <div className="space-y-2">
                    <button
                      type="button"
                      onClick={() => {
                        resetAuthMessages()
                        setPanelMode('cart')
                        setIsMobileMenuOpen(false)
                      }}
                      className="w-full rounded-xl border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-700"
                    >
                      Cart
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        resetAuthMessages()
                        setPanelMode('history')
                        setIsMobileMenuOpen(false)
                      }}
                      className="w-full rounded-xl border border-[#0066ff] bg-white px-4 py-2 text-sm font-semibold text-[#0066ff]"
                    >
                      My Leads
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        void handleLogout()
                        setIsMobileMenuOpen(false)
                      }}
                      className="w-full rounded-xl border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-500"
                    >
                      Log Out
                    </button>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <button
                      type="button"
                      onClick={() => {
                        resetAuthMessages()
                        navigate('/auth/mobile')
                        setIsMobileMenuOpen(false)
                      }}
                      className="w-full rounded-xl border border-[#0066ff] bg-white px-4 py-2 text-sm font-semibold text-[#0066ff]"
                    >
                      Login / Signup
                    </button>
                  </div>
                )}
              </div>
            </nav>
          </div>
        ) : null}
      </header>}

      {isPanelOpen && pageContainer && createPortal(
        <section className={`min-h-[70vh] bg-[#f8fafc] px-4 py-8 sm:py-12 ${panelMode === 'cart' ? 'next-cart-page' : panelMode === 'history' ? 'my-leads-page' : panelMode === 'signup' ? 'next-signup-page' : ''}`}>
        <div className={panelMode === 'cart' || panelMode === 'history' ? 'mx-auto w-full max-w-5xl' : 'mx-auto w-full max-w-lg'}>
          <div className="mb-6 flex justify-start px-4">
            <button
              type="button"
              onClick={() => {
                resetAuthMessages()
                if (window.history.state?.idx > 0) navigate(-1)
                else navigate('/')
              }}
              className="inline-flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-stone-700 transition hover:bg-stone-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-500"
              aria-label="Go back"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="m12 5-7 7 7 7M5 12h14" />
              </svg>
              Back
            </button>
          </div>

          <div className="-mt-2 bg-[#f8fafc] px-4 pb-5 text-center">
            {panelMode === 'history' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">My Leads</h2>
                <p className="mt-1 text-sm text-stone-600">Access your purchased leads and connect with customers.</p>
              </>
            ) : panelMode === 'cart' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">My Cart</h2>
                <p className="mt-1 text-sm text-stone-600">Review selected leads before checkout</p>
              </>
            ) : panelMode === 'forgot-email' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Forget Password</h2>
                <p className="mt-1 text-sm text-stone-600">Enter your Email ID to change the password</p>
              </>
            ) : panelMode === 'forgot-otp' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Verification</h2>
                <p className="mt-1 text-sm text-stone-600">Enter your verification code</p>
              </>
            ) : panelMode === 'forgot-reset' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Change Password</h2>
                <p className="mt-1 text-sm text-stone-600">Set a new password for your account</p>
              </>
            ) : panelMode === 'login' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Welcome Back</h2>
                <p className="mt-1 text-sm text-stone-600">Login to access your account</p>
              </>
            ) : (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Sign Up</h2>
                <p className="mt-1 text-sm text-stone-600">Almost there, just sign up!</p>
              </>
            )}
          </div>

          {authError ? (
            <p className="mx-4 -mt-2 mb-3 rounded-xl border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
              {authError}
            </p>
          ) : null}
          {authSuccess ? (
            <p className="mx-4 -mt-2 mb-3 rounded-xl border border-green-300 bg-green-50 px-3 py-2 text-sm text-green-700">
              {authSuccess}
            </p>
          ) : null}

          {panelMode === 'history' ? (
            <>
            
            <div className="min-h-[58vh] rounded-t-[34px] bg-[#f8fafc] px-4 pt-6 pb-8">
              {!userToken ? (
                <button
                  type="button"
                  onClick={() => setPanelMode('login')}
                  className="w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
                >
                  Continue to Login
                </button>
              ) : isHistoryLoading ? (
                <RowsSkeleton count={5} />
              ) : historyLeads.length === 0 ? (
                <p className="text-center text-sm text-stone-600">No purchased leads yet. Explore available leads to get started.</p>
              ) : (
                <div className="grid gap-4 md:grid-cols-2">
                  {historyLeads.map((lead) => (
                    <article key={lead.id} className="my-lead-card">
                      <div className="my-lead-card-heading"><img src={getLeadPreviewImage(lead.id)} alt="" /><div><h3><button type="button" onClick={() => navigate(`/leads/${lead.id}`)}>{lead.title}</button></h3><p>⌖ {lead.city}</p></div><span className="my-lead-paid">{lead.status}</span></div>
                      <div className="my-lead-customer"><div className="my-lead-customer-title"><span>Customer Details</span><span className="my-lead-unlocked">✓ Unlocked</span></div><h4>{lead.customerName || 'Name not provided'}</h4><p>{lead.address || 'Address not provided'}</p><a className="my-lead-phone" href={lead.phone === 'N/A' ? undefined : `tel:${lead.phone}`}>{lead.phone}</a></div>
                      <div className="my-lead-purchase"><div><span>Purchased for</span><strong>₹{lead.price.toLocaleString('en-IN')}</strong></div><time dateTime={lead.paidAt}>{new Date(lead.paidAt).toLocaleString('en-IN', { dateStyle:'medium', timeStyle:'short', timeZone:'Asia/Kolkata' })} IST</time></div>
                      <div className="my-lead-card-actions"><button type="button" onClick={() => navigate(`/leads/${lead.id}`)}>View Lead Details →</button><button type="button" disabled={lead.isDownloaded} onClick={() => void handleDownloadLead(lead.orderId || lead.id)}>{lead.isDownloaded ? 'Excel downloaded' : 'Download Excel ↓'}</button></div>
                    </article>
                  ))}
                </div>
              )}
            </div>
            </>
          ) : panelMode === 'cart' ? (
            <div className="min-h-[58vh] rounded-t-[34px] bg-[#f8fafc] px-4 pt-6 pb-8">
              {userToken && removedCartLeads.length > 0 ? (
                <div role="status" className="mb-3 rounded-xl border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-700">
                  <p>Unavailable leads were removed. Review the remaining selection before paying.</p>
                  {removedCartLeads.map(lead => <p key={lead._id}>{lead.title}: {lead.reason}</p>)}
                </div>
              ) : null}
              {!userToken ? (
                <button
                  type="button"
                  onClick={() => setPanelMode('login')}
                  className="w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
                >
                  Continue to Login
                </button>
              ) : isCartLoading ? (
                <RowsSkeleton count={3} />
              ) : cartLeads.length === 0 ? (
                <div className="rounded-2xl border border-stone-200 bg-white px-6 py-12 text-center">
                  <p className="text-lg font-semibold text-stone-800">Your cart is empty.</p>
                  <button type="button" onClick={() => navigate('/')} className="mt-5 rounded-xl bg-[#0066ff] px-6 py-3 text-sm font-semibold text-white hover:bg-[#0050cb]">Browse leads</button>
                </div>
              ) : (
                <>
                  <div className="space-y-4">
                    {cartLeads.map((lead) => (
                      <article key={lead._id} className="next-cart-item">
                        <img className="next-cart-image" src={getLeadPreviewImage(lead._id)} alt={lead.title} />
                        <div className="next-cart-item-content">
                          <h3>{lead.title}</h3>
                          <p className="next-cart-meta"><span>⌖ {lead.city}, {lead.state}</span><span>Sharing Leads ({lead.totalSlots - lead.remainingSlots}/{lead.totalSlots})</span></p>
                          <div className="next-cart-quantity" aria-label="Lead quantity"><button type="button" onClick={() => void handleRemoveCartQuantity(lead._id)} disabled={isPaymentProcessing || isLoading} aria-label={`Remove ${lead.title}`}>−</button><span>{lead.quantity}</span><button type="button" onClick={() => void handleAddCartQuantity(lead._id)} disabled title="One purchase per buyer" aria-label="Increase quantity">+</button></div>
                          <div className="next-cart-item-total"><span>₹{lead.price.toLocaleString('en-IN')} × {lead.quantity}</span><strong>₹{(lead.price * lead.quantity).toLocaleString('en-IN')}</strong></div>
                        </div>
                        <button type="button" className="next-cart-delete" disabled={isPaymentProcessing || isLoading} onClick={() => void handleDeleteCartItem(lead._id, lead.quantity)}>Delete</button>
                      </article>
                    ))}
                  </div>

                  <div className="next-cart-checkout mt-5 space-y-3">
                    <div className="rounded-xl border border-stone-300 bg-white px-4 py-3 text-sm font-semibold text-stone-700">
                      <div className="flex items-center justify-between">
                        <span>Total Items</span>
                        <span>{cartSummary.totalItems}</span>
                      </div>
                      <div className="mt-1 flex items-center justify-between text-base font-black text-stone-900">
                        <span>Total Amount</span>
                        <span>₹{cartSummary.totalAmount.toLocaleString()}</span>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        void handleProceedToPay()
                      }}
                      disabled={isPaymentProcessing || isLoading}
                      className="w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb] disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      {isPaymentProcessing ? 'Processing...' : 'Purchase Now →'}
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        void handleClearCart()
                      }}
                      className="w-full rounded-2xl border border-red-300 bg-white py-2.5 text-sm font-semibold text-red-500 transition hover:bg-red-50"
                    >
                      Clear Cart
                    </button>
                  </div>
                </>
              )}
            </div>
          ) : panelMode === 'forgot-email' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#f1f7ff] via-[#e6f0ff] to-[#dce9ff] px-4 pt-6 pb-8"
              onSubmit={handleForgotPasswordRequest}
            >
              <label className="block text-sm font-semibold text-stone-700">
                Email ID
                <input
                  type="email"
                  placeholder="Angad Khanna"
                  value={forgotForm.email}
                  onChange={(event) =>
                    setForgotForm((prev) => ({ ...prev, email: event.target.value }))
                  }
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#0066ff] focus:ring-2 focus:ring-[#0066ff]/40"
                />
              </label>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
              >
                {isLoading ? 'Please wait...' : 'Get OTP'}
              </button>

              <button
                type="button"
                onClick={() => {
                  resetAuthMessages()
                  setPanelMode('login')
                }}
                className="w-full text-center text-sm font-medium text-stone-700 hover:underline"
              >
                Back to login
              </button>

              <div className="flex justify-center pt-3">
                <img src="/trust-team.jpg" alt="" className="h-28 w-36 rounded-2xl object-cover opacity-90" />
              </div>
            </form>
          ) : panelMode === 'forgot-otp' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#f1f7ff] via-[#e6f0ff] to-[#dce9ff] px-4 pt-6 pb-8"
              onSubmit={handleVerifyOtp}
            >
              <p className="text-sm font-semibold text-stone-800">Enter your Verification Code</p>
              <p className="text-xs text-stone-600">Enter the verification code to confirm your identity.</p>

              <div className="mt-2 flex items-center justify-center gap-3">
                {forgotForm.otpDigits.map((digit, index) => (
                  <input
                    key={index}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(event) => {
                      const cleaned = event.target.value.replace(/\D/g, '').slice(-1)
                      setForgotForm((prev) => {
                        const nextDigits = [...prev.otpDigits]
                        nextDigits[index] = cleaned
                        return { ...prev, otpDigits: nextDigits }
                      })
                    }}
                    className="h-12 w-12 rounded-xl border border-stone-300 bg-white text-center text-lg font-semibold text-stone-800 shadow-sm outline-none focus:border-[#0066ff] focus:ring-2 focus:ring-[#0066ff]/35"
                  />
                ))}
              </div>

              <button
                type="button"
                onClick={handleResendOtp}
                className="text-xs font-medium text-[#0050cb] hover:underline"
              >
                I didn&apos;t receive the code? Send again
              </button>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
              >
                {isLoading ? 'Please wait...' : 'Verify'}
              </button>

              <div className="flex justify-center pt-3">
                <img src="/trust-team.jpg" alt="" className="h-28 w-36 rounded-2xl object-cover opacity-90" />
              </div>
            </form>
          ) : panelMode === 'forgot-reset' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#f1f7ff] via-[#e6f0ff] to-[#dce9ff] px-4 pt-6 pb-8"
              onSubmit={handleResetForgotPassword}
            >
              <label className="block text-sm font-semibold text-stone-700">
                New Password
                <input
                  type="password"
                  placeholder="*******"
                  value={forgotForm.newPassword}
                  onChange={(event) =>
                    setForgotForm((prev) => ({ ...prev, newPassword: event.target.value }))
                  }
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#0066ff] focus:ring-2 focus:ring-[#0066ff]/40"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Confirm Password
                <input
                  type="password"
                  placeholder="*******"
                  value={forgotForm.confirmPassword}
                  onChange={(event) =>
                    setForgotForm((prev) => ({ ...prev, confirmPassword: event.target.value }))
                  }
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#0066ff] focus:ring-2 focus:ring-[#0066ff]/40"
                />
              </label>

              <div className="flex justify-center pt-3">
                <img src="/trust-team.jpg" alt="" className="h-36 w-44 rounded-full object-cover opacity-90" />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
              >
                {isLoading ? 'Please wait...' : 'Update'}
              </button>
            </form>
          ) : panelMode === 'login' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#f1f7ff] via-[#e6f0ff] to-[#dce9ff] px-4 pt-6 pb-8"
              onSubmit={handleLoginSubmit}
            >
              <label className="block text-sm font-semibold text-stone-700">
                Email ID
                <input
                  type="email"
                  placeholder="Angad Khanna"
                  value={loginForm.email}
                  onChange={(event) =>
                    setLoginForm((prev) => ({ ...prev, email: event.target.value }))
                  }
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#0066ff] focus:ring-2 focus:ring-[#0066ff]/40"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Password
                <div className="mt-1.5 flex h-13 items-center rounded-2xl border border-stone-300 bg-white shadow-[0_4px_10px_rgba(0,0,0,0.12)]">
                  <input
                    type="password"
                    placeholder="*******"
                    value={loginForm.password}
                    onChange={(event) =>
                      setLoginForm((prev) => ({ ...prev, password: event.target.value }))
                    }
                    className="w-full px-4 text-sm text-stone-800 outline-none"
                  />
                  <span className="px-4 text-stone-500">
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M3 3l18 18" />
                      <path d="M10.6 10.6A2 2 0 0 0 12 14a2 2 0 0 0 1.4-.6" />
                      <path d="M9.9 5.3A10.7 10.7 0 0 1 12 5c5.2 0 9.4 4.4 10 7-.2.8-.8 2-1.8 3.1" />
                      <path d="M6.4 6.4C3.9 8 2.3 10.4 2 12c.6 2.6 4.8 7 10 7 2.1 0 4.1-.7 5.7-1.8" />
                    </svg>
                  </span>
                </div>
              </label>

              <div className="mt-1 flex items-center justify-between text-sm text-stone-700">
                <label className="flex items-center gap-2 text-[13px]">
                  <input
                    type="checkbox"
                    checked={loginForm.rememberMe}
                    onChange={(event) =>
                      setLoginForm((prev) => ({ ...prev, rememberMe: event.target.checked }))
                    }
                    className="h-4 w-4 rounded border-stone-400"
                  />
                  Remember me
                </label>
                <button
                  type="button"
                  onClick={() => {
                    resetAuthMessages()
                    setForgotForm((prev) => ({ ...prev, email: loginForm.email }))
                    setPanelMode('forgot-email')
                  }}
                  className="text-[13px] text-stone-600 hover:underline"
                >
                  Forget password ?
                </button>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-gradient-to-r from-[#ffd925] to-[#efb61a] py-3 text-lg font-bold text-white shadow-[0_6px_14px_rgba(0,0,0,0.18)] transition hover:brightness-105"
              >
                {isLoading ? 'Please wait...' : 'Login'}
              </button>

              <div className="my-3 flex items-center gap-2 text-xs text-stone-600">
                <span className="h-px flex-1 bg-stone-400/50" />
                Or Sign in With
                <span className="h-px flex-1 bg-stone-400/50" />
              </div>

              <div className="flex justify-center">
                <button
                  type="button"
                  onClick={handleGoogleLogin}
                  className="inline-flex items-center gap-2 rounded-full border border-stone-300 bg-white px-5 py-2 text-sm font-medium text-stone-700 shadow-sm transition hover:bg-stone-50"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5" aria-hidden="true">
                    <path
                      fill="#EA4335"
                      d="M12 10.2v3.9h5.4c-.2 1.3-1.5 3.8-5.4 3.8-3.2 0-5.8-2.7-5.8-6s2.6-6 5.8-6c1.8 0 3.1.8 3.8 1.4l2.6-2.5C16.8 3.4 14.6 2.5 12 2.5A9.5 9.5 0 0 0 2.5 12c0 5.2 4.2 9.5 9.5 9.5 5.5 0 9.1-3.9 9.1-9.3 0-.6-.1-1.1-.2-1.6H12Z"
                    />
                    <path
                      fill="#34A853"
                      d="M3.6 7.5 6.8 9.9A5.8 5.8 0 0 1 12 6c1.8 0 3.1.8 3.8 1.4l2.6-2.5A9.4 9.4 0 0 0 12 2.5c-3.6 0-6.8 2-8.4 5Z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M12 21.5c2.5 0 4.7-.8 6.2-2.3l-3-2.4c-.8.6-1.9 1-3.2 1a5.8 5.8 0 0 1-5.5-4l-3.1 2.4A9.5 9.5 0 0 0 12 21.5Z"
                    />
                    <path
                      fill="#4285F4"
                      d="M21.1 12.2c0-.6-.1-1.1-.2-1.6H12v3.9h5.4a4.6 4.6 0 0 1-2.1 2.9l3 2.4c1.8-1.6 2.8-4.1 2.8-7.6Z"
                    />
                  </svg>
                  Google
                </button>
              </div>

              <p className="pt-1 text-center text-sm text-stone-700">
                Don&apos;t have an account?{' '}
                <button
                  type="button"
                  onClick={() => {
                    resetAuthMessages()
                    setPanelMode('signup')
                  }}
                  className="font-semibold text-red-600 hover:underline"
                >
                  Sign Up
                </button>
              </p>
            </form>
          ) : (
            <form
              className="next-signup-form"
              onSubmit={handleSignupSubmit}
            >
              <label className="block text-sm font-semibold text-stone-700">
                First Name
                <input
                  type="text"
                  placeholder="Enter your first name"
                  value={signupForm.firstname}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, firstname: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Last Name
                <input
                  type="text"
                  placeholder="Enter your last name"
                  value={signupForm.lastname}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, lastname: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Phone Number
                <input
                  type="tel"
                  placeholder="98765 43210"
                  value={signupForm.phoneNumber}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, phoneNumber: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Email ID
                <input
                  type="email"
                  placeholder="you@example.com"
                  value={signupForm.email}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, email: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Password
                <div className="mt-1.5 flex items-center rounded-2xl border border-stone-300 bg-white shadow-md">
                  <input
                    type="password"
                    placeholder="*******"
                    value={signupForm.password}
                    onChange={(event) =>
                      setSignupForm((prev) => ({ ...prev, password: event.target.value }))
                    }
                    className="w-full px-4 py-3 text-sm text-stone-800 outline-none"
                  />
                  <span className="px-4 text-stone-500">
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M3 3l18 18" />
                      <path d="M10.6 10.6A2 2 0 0 0 12 14a2 2 0 0 0 1.4-.6" />
                      <path d="M9.9 5.3A10.7 10.7 0 0 1 12 5c5.2 0 9.4 4.4 10 7-.2.8-.8 2-1.8 3.1" />
                      <path d="M6.4 6.4C3.9 8 2.3 10.4 2 12c.6 2.6 4.8 7 10 7 2.1 0 4.1-.7 5.7-1.8" />
                    </svg>
                  </span>
                </div>
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Confirm Password
                <div className="mt-1.5 flex items-center rounded-2xl border border-stone-300 bg-white shadow-md">
                  <input
                    type="password"
                    placeholder="*******"
                    value={signupForm.confirmPassword}
                    onChange={(event) =>
                      setSignupForm((prev) => ({
                        ...prev,
                        confirmPassword: event.target.value,
                      }))
                    }
                    className="w-full px-4 py-3 text-sm text-stone-800 outline-none"
                  />
                  <span className="px-4 text-stone-500">
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M3 3l18 18" />
                      <path d="M10.6 10.6A2 2 0 0 0 12 14a2 2 0 0 0 1.4-.6" />
                      <path d="M9.9 5.3A10.7 10.7 0 0 1 12 5c5.2 0 9.4 4.4 10 7-.2.8-.8 2-1.8 3.1" />
                      <path d="M6.4 6.4C3.9 8 2.3 10.4 2 12c.6 2.6 4.8 7 10 7 2.1 0 4.1-.7 5.7-1.8" />
                    </svg>
                  </span>
                </div>
              </label>

              <label className="mt-1 flex items-center gap-2 text-sm text-stone-700">
                <input
                  type="checkbox"
                  checked={signupForm.rememberMe}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, rememberMe: event.target.checked }))
                  }
                  className="h-4 w-4 rounded border-stone-400"
                />
                Remember me
              </label>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
              >
                {isLoading ? 'Please wait...' : 'Sign Up'}
              </button>

              <p className="pt-1 text-center text-sm text-stone-700">
                Already have an account?{' '}
                <button
                  type="button"
                  onClick={() => {
                    resetAuthMessages()
                    setPanelMode('login')
                  }}
                  className="font-semibold text-[#0066ff] hover:underline"
                >
                  Login
                </button>
              </p>
            </form>
          )}
        </div>
        </section>, pageContainer
      )}
      {isDownloadPopupOpen ? (
        <div className="next-download-window fixed inset-0 z-50 grid place-items-center bg-black/45 p-4">
          <div className="w-full max-w-sm rounded-2xl border border-stone-200 bg-white p-5 text-center shadow-2xl">
            <h3 className="text-3xl font-black text-[#0066ff]">Download</h3>
            <div className="mx-auto mt-3 grid h-20 w-20 place-items-center rounded-full bg-[#edf5ff]">
              <svg viewBox="0 0 24 24" className="h-10 w-10 text-[#0066ff]" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M12 3v11" />
                <path d="m7 10 5 5 5-5" />
                <rect x="4" y="18" width="16" height="3" rx="1.5" />
              </svg>
            </div>
            <p className="mt-3 text-sm text-stone-600">Download the lead file from the option below.</p>
            <button
              type="button"
              onClick={() => {
                void handleDownloadAfterPayment()
              }}
              className="mt-4 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
            >
              Download File
            </button>
            <p className="mt-2 text-xs font-semibold text-red-500">Only one time download available</p>
            <button
              type="button"
              onClick={(event) => animateWindowClose(event.currentTarget.closest('.next-download-window'), () => setIsDownloadPopupOpen(false))}
              className="mt-3 text-sm font-semibold text-stone-500 hover:text-stone-700"
            >
              Close
            </button>
          </div>
        </div>
      ) : null}
    </>
  )
}

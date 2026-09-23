import { useEffect, useState, type FormEvent } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'

const CONFIGURED_API_BASE_URL = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
const API_BASE_URL_CANDIDATES = Array.from(
  new Set(
    [CONFIGURED_API_BASE_URL, `${window.location.protocol}//${window.location.hostname}:5000`].filter(
      (value): value is string => Boolean(value),
    ),
  ),
)

const buildAuthUrl = (apiBaseUrl: string, path: string) =>
  `${apiBaseUrl}/api/v1/auth${path}`
const buildApiUrl = (apiBaseUrl: string, path: string) => `${apiBaseUrl}/api/v1${path}`
const RAZORPAY_KEY_ID =
  import.meta.env.VITE_RAZORPAY_KEY_ID ?? import.meta.env.VITE_RAZORPAY_KEY ?? 'demo_key'

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

const ensureRazorpayLoaded = async () => {
  if (window.Razorpay) return

  await new Promise<void>((resolve, reject) => {
    const script = document.createElement('script')
    script.src = 'https://checkout.razorpay.com/v1/checkout.js'
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Unable to load Razorpay checkout script.'))
    document.body.appendChild(script)
  })
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
  const [panelMode, setPanelMode] = useState<
    | 'account'
    | 'history'
    | 'cart'
    | 'login'
    | 'signup'
    | 'forgot-email'
    | 'forgot-otp'
    | 'forgot-reset'
    | null
  >(null)
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
  const [isProfileLoading, setIsProfileLoading] = useState(false)
  const [accountForm, setAccountForm] = useState({
    firstname: '',
    lastname: '',
    phoneNumber: '',
    email: '',
  })
  const [addressForm, setAddressForm] = useState({
    label: 'HOME',
    street: '',
    landmark: '',
    city: '',
    state: '',
    country: '',
    zipcode: '',
  })
  const [isAddressFormOpen, setIsAddressFormOpen] = useState(false)
  const [isEditingProfile, setIsEditingProfile] = useState(false)
  const [profilePic, setProfilePic] = useState('')
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
  const isPanelOpen = panelMode !== null
  const userToken = localStorage.getItem('user_token')
  const hasSavedAddress = Boolean(
    addressForm.street || addressForm.city || addressForm.state || addressForm.zipcode,
  )
  const primaryAddressParts = [addressForm.street, addressForm.landmark].filter(Boolean)
  const secondaryAddressParts = [
    addressForm.city,
    addressForm.state,
    addressForm.country,
  ].filter(Boolean)
  const addressSummary = `${primaryAddressParts.join(', ')}${
    primaryAddressParts.length > 0 && secondaryAddressParts.length > 0 ? ', ' : ''
  }${secondaryAddressParts.join(', ')}${addressForm.zipcode ? ` - ${addressForm.zipcode}` : ''}`

  const resetAuthMessages = () => {
    setAuthError('')
    setAuthSuccess('')
  }

  const requestAuth = async (path: string, init?: RequestInit) => {
    return requestApi(`/auth${path}`, init)
  }

  const requestApi = async (path: string, init?: RequestInit) => {
    let lastNetworkError: Error | null = null

    for (const baseUrl of API_BASE_URL_CANDIDATES) {
      try {
        return await fetch(buildApiUrl(baseUrl, path), init)
      } catch (error) {
        lastNetworkError =
          error instanceof Error ? error : new Error('Unable to connect to auth server.')
      }
    }

    throw lastNetworkError ?? new Error('Unable to connect to auth server.')
  }

  const storeUserSession = (token: string, user?: unknown) => {
    localStorage.setItem('user_token', token)
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
      setPanelMode('account')
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
    window.location.assign(googleAuthUrl)
  }

  const fetchHistoryLeads = async () => {
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
  }

  const fetchCart = async () => {
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
      setRemovedCartLeads(Array.isArray(data.removedLeads) ? data.removedLeads : [])
      setCartSummary({
        totalItems: Number(data.totalItems) || 0,
        totalAmount: Number(data.totalAmount) || 0,
      })
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to load cart.')
    } finally {
      setIsCartLoading(false)
    }
  }

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
    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    if (cartLeads.length === 0) {
      setAuthError('Your cart is empty.')
      return
    }

    try {
      setIsPaymentProcessing(true)
      resetAuthMessages()

      const createResponse = await requestApi('/payments/create', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const createPayload = await createResponse.json()

      if (!createResponse.ok || !createPayload?.success) {
        throw new Error(createPayload?.message ?? 'Unable to create payment order.')
      }

      const orderData = createPayload?.data ?? {}
      if (!orderData?.razorpayOrderId) {
        throw new Error('Payment order ID missing. Please try again.')
      }
      const internalOrderId =
        typeof orderData?.internalOrderId === 'string' ? orderData.internalOrderId : ''

      await ensureRazorpayLoaded()
      if (!window.Razorpay) {
        throw new Error('Razorpay checkout unavailable right now.')
      }

      const razorpay = new window.Razorpay({
        key: orderData.keyId || RAZORPAY_KEY_ID,
        amount: Number(orderData.amount) * 100,
        currency: orderData.currency ?? 'INR',
        name: 'Leads Solution',
        description: `${orderData.leadsCount ?? cartSummary.totalItems} lead(s) purchase`,
        order_id: orderData.razorpayOrderId,
        modal: {
          ondismiss: () => {
            setAuthError('Payment cancelled.')
            setIsPaymentProcessing(false)
          },
        },
        handler: async (response: {
          razorpay_order_id: string
          razorpay_payment_id: string
          razorpay_signature: string
        }) => {
          try {
            const verifyResponse = await requestApi('/payments/verify', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${userToken}`,
              },
              body: JSON.stringify({
                razorpayOrderId: response.razorpay_order_id,
                razorpayPaymentId: response.razorpay_payment_id,
                razorpaySignature: response.razorpay_signature,
              }),
            })
            const verifyPayload = await verifyResponse.json()

            if (!verifyResponse.ok || !verifyPayload?.success) {
              throw new Error(verifyPayload?.message ?? 'Payment verification failed.')
            }

            setAuthSuccess(verifyPayload?.message ?? 'Payment successful.')
            await fetchCart()
            if (internalOrderId) {
              setDownloadOrderId(internalOrderId)
              setIsDownloadPopupOpen(true)
            } else {
              setPanelMode('history')
              void fetchHistoryLeads()
            }
          } catch (error) {
            setAuthError(error instanceof Error ? error.message : 'Payment verification failed.')
          } finally {
            setIsPaymentProcessing(false)
          }
        },
      })

      razorpay.on('payment.failed', (response: Record<string, unknown>) => {
        const error = response?.error as { description?: string } | undefined
        setAuthError(error?.description || 'Payment Failed')
        setIsPaymentProcessing(false)
      })

      razorpay.open()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to start payment.')
      setIsPaymentProcessing(false)
    }
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

  const fetchProfile = async () => {
    if (!userToken) return

    try {
      setIsProfileLoading(true)
      resetAuthMessages()
      const response = await requestAuth('/profile', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to fetch profile.')
      }

      const data = payload?.data ?? {}
      setAccountForm({
        firstname: data.firstname ?? '',
        lastname: data.lastname ?? '',
        phoneNumber: data.phoneNumber ?? '',
        email: data.email ?? '',
      })
      setProfilePic(data.profilePic ?? '')

      const address = data.address ?? {}
      setAddressForm({
        label: address.label ?? 'HOME',
        street: address.street ?? '',
        landmark: address.landmark ?? '',
        city: address.city ?? '',
        state: address.state ?? '',
        country: address.country ?? '',
        zipcode: address.zipcode ?? '',
      })
      setIsEditingProfile(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to fetch profile.')
    } finally {
      setIsProfileLoading(false)
    }
  }

  const handleProfileUpdate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (!isEditingProfile) {
      setAuthError('Click "Edit Profile" first.')
      return
    }

    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/update-profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({
          firstname: accountForm.firstname,
          lastname: accountForm.lastname,
          phoneNumber: accountForm.phoneNumber,
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to update profile.')
      }

      setAuthSuccess(payload?.message ?? 'Profile updated successfully.')
      setIsEditingProfile(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Profile update failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleAddAddress = async (event?: FormEvent<HTMLFormElement>) => {
    event?.preventDefault()
    resetAuthMessages()

    if (!userToken) {
      setAuthError('Please login first.')
      setPanelMode('login')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/add-address', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({
          ...addressForm,
          label: addressForm.label || 'HOME',
          country: addressForm.country || 'India',
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to save address.')
      }

      setAuthSuccess(payload?.message ?? 'Address saved successfully.')
      setIsAddressFormOpen(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Address save failed.')
    } finally {
      setIsLoading(false)
    }
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

    const token = params.get('token')
    const serializedUser = params.get('user')
    const googleError = params.get('error')

    if (googleError) {
      setAuthError(googleError)
      navigate('/', { replace: true })
      return
    }

    if (token) {
      let parsedUser: unknown = undefined
      if (serializedUser) {
        try {
          parsedUser = JSON.parse(serializedUser)
        } catch {
          parsedUser = undefined
        }
      }
      storeUserSession(token, parsedUser)
      setPanelMode(null)
      setIsMobileMenuOpen(false)
      const profile = (parsedUser ?? {}) as {
        registrationFeePaid?: boolean
      }

      if (!profile.registrationFeePaid) {
        navigate('/auth/mobile?flow=google', { replace: true })
        return
      }

      setAuthSuccess('Logged in successfully using Google.')
    }

    navigate('/', { replace: true })
  }, [navigate])

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
  }, [])

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
  }, [])

  useEffect(() => {
    if (panelMode === 'account' && userToken) {
      fetchProfile()
    }
  }, [panelMode, userToken])

  useEffect(() => {
    if (panelMode === 'history' && userToken) {
      void fetchHistoryLeads()
    }
  }, [panelMode, userToken])

  useEffect(() => {
    if (panelMode === 'cart' && userToken) {
      void fetchCart()
    }
  }, [panelMode, userToken])

  useEffect(() => {
    if (userToken) {
      void fetchCart()
    } else {
      setCartLeads([])
      setRemovedCartLeads([])
      setCartSummary({ totalItems: 0, totalAmount: 0 })
    }
  }, [userToken])

  useEffect(() => {
    if (!userToken) return

    const handleCartUpdated = () => {
      void fetchCart()
    }

    window.addEventListener('cart:updated', handleCartUpdated)
    return () => {
      window.removeEventListener('cart:updated', handleCartUpdated)
    }
  }, [userToken])

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
      <header className="sticky top-0 z-30 border-b border-stone-200 bg-white/95 shadow-sm backdrop-blur">
        <div className="border-b border-stone-100 bg-stone-50">
          <div className="mx-auto flex max-w-7xl items-center justify-between gap-2 px-4 py-2 text-[11px] text-stone-600 sm:px-6 sm:text-xs">
            <p className="min-w-0 truncate">Trusted by interior professionals across India</p>
            <p className="hidden sm:block">Support: +91 62058 78945</p>
          </div>
        </div>

        <div className="mx-auto flex max-w-7xl items-center gap-2 px-4 py-3 sm:gap-4 sm:px-6">
          <NavLink to="/" className="shrink-0">
            <img
              src="/logo.png"
              alt="Logo"
              className="h-14 w-auto sm:h-16"
            />
          </NavLink>

          <nav className="hidden min-w-0 flex-1 items-center justify-center gap-2 rounded-full bg-transparent px-2 py-1 md:flex">
            <NavLink
              to="/"
              className={({ isActive }) =>
                `rounded-full px-4 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-[#F8B020] text-white shadow-sm'
                    : 'text-stone-600 hover:bg-white hover:text-stone-900'
                }`
              }
            >
              Home
            </NavLink>
            <div 
              className="relative"
              onMouseEnter={() => setIsCategoryDropdownOpen(true)}
              onMouseLeave={() => setIsCategoryDropdownOpen(false)}
            >
              <button
                type="button"
                className={`flex items-center gap-1 rounded-full px-4 py-2 text-sm font-semibold transition ${
                  isCategoryDropdownOpen
                    ? 'bg-stone-200 text-stone-900'
                    : 'text-stone-600 hover:bg-white hover:text-stone-900'
                }`}
              >
                Categories
                <svg viewBox="0 0 24 24" className={`h-4 w-4 transition-transform ${isCategoryDropdownOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              
              {isCategoryDropdownOpen && (
                <div className="absolute top-full left-0 mt-2 w-56 rounded-2xl border border-stone-200 bg-white py-2 shadow-xl">
                  {isCategoriesLoading ? (
                    <div className="px-4 py-3 text-sm text-stone-500">Loading categories...</div>
                  ) : categories.length > 0 ? (
                    <div className="max-h-80 overflow-y-auto">
                      {categories.map((category) => (
                        <NavLink
                          key={category._id}
                          to={`/?category=${category._id}`}
                          className="block px-4 py-2 text-sm font-medium text-stone-700 transition hover:bg-stone-50 hover:text-stone-900"
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
                      ))}
                    </div>
                  ) : (
                    <div className="px-4 py-3 text-sm text-stone-500">No categories found</div>
                  )}
                </div>
              )}
            </div>
            <div
              className="relative"
              onMouseEnter={() => setIsCityDropdownOpen(true)}
              onMouseLeave={() => setIsCityDropdownOpen(false)}
            >
              <button
                type="button"
                className={`flex items-center gap-1 rounded-full px-4 py-2 text-sm font-semibold transition ${
                  isCityDropdownOpen
                    ? 'bg-stone-200 text-stone-900'
                    : 'text-stone-600 hover:bg-white hover:text-stone-900'
                }`}
              >
                Cities
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
                <div className="absolute top-full left-0 mt-2 w-52 rounded-2xl border border-stone-200 bg-white py-2 shadow-xl">
                  {isCitiesLoading ? (
                    <div className="px-4 py-3 text-sm text-stone-500">Loading cities...</div>
                  ) : cities.length > 0 ? (
                    <div className="max-h-72 overflow-y-auto">
                      {cities.map((city) => (
                        <NavLink
                          key={city._id}
                          to={`/?city=${encodeURIComponent(city.name)}`}
                          className="block px-4 py-2 text-sm font-medium text-stone-700 transition hover:bg-stone-50 hover:text-stone-900"
                        >
                          {city.name}
                        </NavLink>
                      ))}
                    </div>
                  ) : (
                    <div className="px-4 py-3 text-sm text-stone-500">No cities found</div>
                  )}
                </div>
              ) : null}
            </div>
            <NavLink
              to="/pricing"
              className={({ isActive }) =>
                `rounded-full px-4 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-[#F8B020] text-white shadow-sm'
                    : 'text-stone-600 hover:bg-white hover:text-stone-900'
                }`
              }
            >
              About Us
            </NavLink>
            <NavLink
              to="/contact"
              className={({ isActive }) =>
                `rounded-full px-4 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-[#F8B020] text-white shadow-sm'
                    : 'text-stone-600 hover:bg-white hover:text-stone-900'
                }`
              }
            >
              Contact Us
            </NavLink>
          </nav>

          <div className="ml-auto flex items-center gap-2 sm:gap-3">
            <button
              type="button"
              onClick={() => {
                if (!userToken) {
                  navigate('/auth/mobile')
                  return
                }
                resetAuthMessages()
                setPanelMode('cart')
              }}
              className="relative hidden h-9 w-9 place-items-center rounded-full border border-stone-300 bg-white text-stone-600 transition hover:border-stone-400 hover:text-stone-800 sm:grid"
              aria-label="Cart"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 5h2l2.2 9.2a2 2 0 0 0 1.95 1.53H17a2 2 0 0 0 1.96-1.61L20 8H7" />
                <circle cx="10" cy="20" r="1.5" />
                <circle cx="17" cy="20" r="1.5" />
              </svg>
              {cartSummary.totalItems > 0 ? (
                <span className="absolute -top-1 -right-1 grid h-4 min-w-4 place-items-center rounded-full bg-[#F8B020] px-1 text-[10px] leading-none font-bold text-white">
                  {cartSummary.totalItems}
                </span>
              ) : null}
            </button>
            <button
              type="button"
              onClick={() => {
                if (!userToken) {
                  navigate('/auth/mobile')
                  return
                }
                resetAuthMessages()
                setPanelMode('account')
              }}
              className="grid h-9 w-9 place-items-center rounded-full border border-stone-300 bg-white text-stone-600 transition hover:border-stone-400 hover:text-stone-800"
              aria-label="Profile"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="8" r="4" />
                <path d="M4 20c1.5-3.5 4.6-5 8-5s6.5 1.5 8 5" />
              </svg>
            </button>

            {userToken ? (
              <>
                <button
                  type="button"
                  onClick={() => {
                    resetAuthMessages()
                    setPanelMode('history')
                  }}
                  className="hidden rounded-full border border-[#F8B020] bg-white px-4 py-1.5 text-sm font-semibold text-[#F8B020] shadow-sm transition hover:bg-[#FFF7E8] md:inline-flex"
                >
                  History
                </button>
                <button
                  type="button"
                  onClick={handleLogout}
                  className="hidden rounded-full border border-red-300 bg-white px-4 py-1.5 text-sm font-semibold text-red-500 shadow-sm transition hover:bg-red-50 md:inline-flex"
                >
                  Log Out
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  onClick={() => {
                    resetAuthMessages()
                    navigate('/auth/mobile')
                  }}
                  className="hidden rounded-full border border-[#4B2CF5] bg-white px-4 py-1.5 text-sm font-semibold text-[#4B2CF5] transition hover:bg-[#F3EEFF] sm:inline-flex"
                >
                  Login / Signup
                </button>
              </>
            )}
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen((open) => !open)}
              className="grid h-9 w-9 place-items-center rounded-full border border-stone-300 bg-white text-stone-700 transition hover:border-stone-400 md:hidden"
              aria-label="Toggle mobile menu"
            >
              {isMobileMenuOpen ? (
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              ) : (
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M4 7h16M4 12h16M4 17h16" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {isMobileMenuOpen ? (
          <div className="border-t border-stone-200 bg-white px-4 py-3 md:hidden">
            <nav className="space-y-2">
              <NavLink
                to="/"
                onClick={() => setIsMobileMenuOpen(false)}
                className={({ isActive }) =>
                  `block rounded-xl px-3 py-2 text-sm font-semibold ${
                    isActive ? 'bg-[#F8B020] text-white' : 'text-stone-700 hover:bg-stone-100'
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
                      isActive ? 'bg-[#5A35F0] text-white' : 'text-[#5A35F0] hover:bg-[#F3EEFF]'
                    }`
                  }
                >
                  Login / Signup
                </NavLink>
              ) : null}
              
              <div className="space-y-1">
                <button
                  type="button"
                  onClick={() => setIsCategoryDropdownOpen(!isCategoryDropdownOpen)}
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
                  onClick={() => setIsCityDropdownOpen(!isCityDropdownOpen)}
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
                    isActive ? 'bg-[#F8B020] text-white' : 'text-stone-700 hover:bg-stone-100'
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
                    isActive ? 'bg-[#F8B020] text-white' : 'text-stone-700 hover:bg-stone-100'
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
                      className="w-full rounded-xl border border-[#F8B020] bg-white px-4 py-2 text-sm font-semibold text-[#F8B020]"
                    >
                      History
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
                      className="w-full rounded-xl border border-[#4B2CF5] bg-white px-4 py-2 text-sm font-semibold text-[#4B2CF5]"
                    >
                      Login / Signup
                    </button>
                  </div>
                )}
              </div>
            </nav>
          </div>
        ) : null}
      </header>

      <div
        className={`fixed inset-0 z-40 transition ${
          isPanelOpen ? 'pointer-events-auto bg-black/45' : 'pointer-events-none bg-black/0'
        }`}
        onClick={() => {
          resetAuthMessages()
          setPanelMode(null)
        }}
      >
        <aside
          className={`absolute top-0 right-0 h-full w-full max-w-sm overflow-y-auto bg-[#efefef] shadow-2xl transition-transform duration-300 ease-out ${
            isPanelOpen ? 'translate-x-0' : 'translate-x-full'
          }`}
          onClick={(event) => event.stopPropagation()}
        >
          <div className="sticky top-0 z-10 flex justify-end bg-[#efefef] px-4 pt-4">
            <button
              type="button"
              onClick={() => {
                resetAuthMessages()
                setPanelMode(null)
              }}
              className="rounded-full p-2 text-stone-500 transition hover:bg-stone-200 hover:text-stone-800"
              aria-label="Close auth panel"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M18 6 6 18M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div className="-mt-2 bg-[#efefef] px-4 pb-5 text-center">
            <img src="/logo.png" alt="Interiorwala" className="mx-auto h-16 w-auto" />
            {panelMode === 'account' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">My Account</h2>
                <p className="mt-1 text-sm text-stone-600">Manage your profile and sign-in options</p>
              </>
            ) : panelMode === 'history' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">History</h2>
                <p className="mt-1 text-sm text-stone-600">Your purchased leads</p>
              </>
            ) : panelMode === 'cart' ? (
              <>
                <h2 className="mt-2 text-4xl font-black text-stone-900">Cart</h2>
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
            <div className="min-h-[58vh] rounded-t-[34px] bg-[#efefef] px-4 pt-6 pb-8">
              {!userToken ? (
                <button
                  type="button"
                  onClick={() => setPanelMode('login')}
                  className="w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
                >
                  Continue to Login
                </button>
              ) : isHistoryLoading ? (
                <p className="text-center text-sm font-medium text-stone-600">Loading history...</p>
              ) : historyLeads.length === 0 ? (
                <p className="text-center text-sm text-stone-600">No purchase history found.</p>
              ) : (
                <div className="space-y-4">
                  {historyLeads.map((lead) => (
                    <article
                      key={lead.id}
                      className="rounded-2xl border border-[#B3BA70] bg-white p-3 shadow-sm"
                    >
                      <div className="flex items-start gap-3">
                        <img
                          src={getLeadPreviewImage(lead.id)}
                          alt={lead.title}
                          className="h-10 w-14 rounded-lg object-cover"
                        />
                        <div className="min-w-0 flex-1">
                          <h4 className="truncate text-xl font-black text-stone-900">{lead.title}</h4>
                          <p className="mt-0.5 flex items-center gap-1 text-xs text-stone-500">
                            <span>📍</span>
                            {lead.city}
                          </p>
                        </div>
                      </div>

                      <div className="mt-3 rounded-xl bg-stone-100 p-3 text-sm text-stone-700">
                        <div className="mb-1 flex items-start justify-between gap-3">
                          <p className="font-medium">{lead.customerName}</p>
                          <p className="text-xs text-stone-500">{new Date(lead.paidAt).toLocaleString()}</p>
                        </div>
                        <p>{lead.address}</p>
                        <p>{lead.phone}</p>
                        <div className="mt-2 flex items-center justify-between">
                          <p className="text-xs text-stone-600">
                            {lead.quantity} {lead.quantity > 1 ? 'Sharing Leads' : 'Sharing Lead'}
                          </p>
                          <span className="rounded-full bg-green-500 px-5 py-1 text-xs font-bold tracking-wide text-white">
                            {lead.status}
                          </span>
                        </div>
                      </div>

                      <div className="mt-3">
                        <button
                          type="button"
                          disabled={lead.isDownloaded}
                          onClick={() => {
                            void handleDownloadLead(lead.orderId || lead.id)
                          }}
                          className={`w-full rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                            lead.isDownloaded
                              ? 'cursor-not-allowed border-stone-300 bg-stone-100 text-stone-500'
                              : 'border-[#B3BA70] bg-white text-[#99A13E] hover:bg-[#F8FADF]'
                          }`}
                        >
                          {lead.isDownloaded ? 'Already Downloaded' : 'Download Leads'}
                        </button>
                      </div>
                    </article>
                  ))}
                </div>
              )}
            </div>
          ) : panelMode === 'cart' ? (
            <div className="min-h-[58vh] rounded-t-[34px] bg-[#efefef] px-4 pt-6 pb-8">
              {!userToken ? (
                <button
                  type="button"
                  onClick={() => setPanelMode('login')}
                  className="w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
                >
                  Continue to Login
                </button>
              ) : isCartLoading ? (
                <p className="text-center text-sm font-medium text-stone-600">Loading cart...</p>
              ) : cartLeads.length === 0 ? (
                <p className="text-center text-sm text-stone-600">Your cart is empty.</p>
              ) : (
                <>
                  {removedCartLeads.length > 0 ? (
                    <div className="mb-3 rounded-xl border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-700">
                      Some leads are no longer available and removed from cart.
                    </div>
                  ) : null}
                  <div className="space-y-4">
                    {cartLeads.map((lead) => (
                      <article
                        key={lead._id}
                        className="rounded-2xl border border-[#B3BA70] bg-white p-3 shadow-sm"
                      >
                        <div className="flex items-start gap-3">
                          <img
                            src={getLeadPreviewImage(lead._id)}
                            alt={lead.title}
                            className="h-10 w-14 rounded-lg object-cover"
                          />
                          <div className="min-w-0 flex-1">
                            <h4 className="truncate text-xl font-black text-stone-900">{lead.title}</h4>
                            <p className="mt-0.5 text-xs text-stone-500">{lead.city} City</p>
                          </div>
                        </div>

                        <div className="mt-3 rounded-xl bg-stone-100 p-3 text-sm text-stone-700">
                          <p>
                            {lead.city}, {lead.state}
                          </p>
                          <p className="mt-1 text-xs text-stone-600">
                            Sharing Leads ({lead.totalSlots - lead.remainingSlots}/{lead.totalSlots})
                          </p>
                          <div className="mt-3 flex items-center justify-between gap-2">
                            <div className="inline-flex items-center rounded-full border border-stone-300 bg-white">
                              <button
                                type="button"
                                onClick={() => {
                                  void handleRemoveCartQuantity(lead._id)
                                }}
                                className="h-8 w-8 rounded-l-full text-base font-bold text-stone-700 hover:bg-stone-100"
                                aria-label="Decrease quantity"
                              >
                                -
                              </button>
                              <span className="min-w-8 px-2 text-center text-sm font-semibold">
                                {lead.quantity}
                              </span>
                              <button
                                type="button"
                                onClick={() => {
                                  void handleAddCartQuantity(lead._id)
                                }}
                                className="h-8 w-8 rounded-r-full text-base font-bold text-stone-700 hover:bg-stone-100"
                                aria-label="Increase quantity"
                              >
                                +
                              </button>
                            </div>
                            <button
                              type="button"
                              onClick={() => {
                                void handleDeleteCartItem(lead._id, lead.quantity)
                              }}
                              className="rounded-full border border-red-300 px-3 py-1 text-xs font-semibold text-red-500 hover:bg-red-50"
                            >
                              Delete
                            </button>
                          </div>
                        </div>

                        <div className="mt-3 flex items-center justify-between gap-2">
                          <p className="text-sm font-bold text-stone-800">
                            ₹{lead.price} x {lead.quantity}
                          </p>
                          <p className="text-base font-black text-[#0DA638]">
                            ₹{(lead.price * lead.quantity).toLocaleString()}
                          </p>
                        </div>
                      </article>
                    ))}
                  </div>

                  <div className="mt-5 space-y-3">
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
                      className="w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D] disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      {isPaymentProcessing ? 'Opening Payment...' : 'Proceed to Pay'}
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
          ) : panelMode === 'account' ? (
            <div className="rounded-t-[34px] bg-gradient-to-b from-[#efe7b8] via-[#f2db72] to-[#f4cd2f]">
              <div className="px-4 py-4 text-white">
                <div className="flex items-center gap-2 text-base font-bold">
                  <button
                    type="button"
                    onClick={() => setPanelMode(null)}
                    className="rounded-full p-1.5 text-white/95 hover:bg-white/20"
                    aria-label="Back"
                  >
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="m15 18-6-6 6-6" />
                    </svg>
                  </button>
                  My Account
                </div>
                <p className="mt-3 text-[13px] text-white/90">
                  {userToken
                    ? 'Manage your profile details'
                    : 'Log in or sign up to view your complete profile'}
                </p>
                {!userToken ? (
                  <button
                    type="button"
                    onClick={() => setPanelMode('login')}
                    className="mt-4 w-full rounded-2xl border border-stone-300 bg-white py-3 text-lg font-semibold text-stone-500 shadow-[0_5px_12px_rgba(0,0,0,0.14)] transition hover:bg-stone-50"
                  >
                    Continue to sign in
                  </button>
                ) : null}
              </div>

              {userToken ? (
                <form
                  className="min-h-[58vh] space-y-4 rounded-t-3xl bg-[#efefef] px-4 pt-6 pb-10"
                  onSubmit={handleProfileUpdate}
                >
                  {isProfileLoading ? (
                    <p className="text-center text-sm font-medium text-stone-600">Loading profile...</p>
                  ) : (
                    <>
                      {isAddressFormOpen ? (
                        <div className="space-y-4 rounded-3xl bg-[#efefef]">
                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => setIsAddressFormOpen(false)}
                              className="rounded-full p-1 text-stone-700 hover:bg-stone-200"
                              aria-label="Back to account"
                            >
                              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="m15 18-6-6 6-6" />
                              </svg>
                            </button>
                            <h3 className="text-2xl font-black text-stone-900">Add Address</h3>
                          </div>

                          <label className="block text-sm font-semibold text-stone-700">
                            Flat no. / Street Name
                            <input
                              type="text"
                              placeholder="Flat 203, Sai Residency"
                              value={addressForm.street}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, street: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Landmark
                            <input
                              type="text"
                              placeholder="Near Hospital"
                              value={addressForm.landmark}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, landmark: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            City
                            <select
                              value={addressForm.city}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, city: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                            >
                              <option value="">Select City</option>
                              <option value="Nashik">Nashik</option>
                              <option value="Mumbai">Mumbai</option>
                              <option value="Pune">Pune</option>
                              <option value="Bengaluru">Bengaluru</option>
                              <option value="Delhi">Delhi</option>
                            </select>
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            State
                            <input
                              type="text"
                              placeholder="Maharashtra"
                              value={addressForm.state}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, state: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Zipcode
                            <input
                              type="text"
                              placeholder="411 853"
                              value={addressForm.zipcode}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, zipcode: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                            />
                          </label>

                          <div>
                            <p className="text-sm font-semibold text-stone-600">Save address as</p>
                            <div className="mt-2 flex items-center gap-2">
                              <button
                                type="button"
                                onClick={() =>
                                  setAddressForm((prev) => ({ ...prev, label: 'HOME' }))
                                }
                                className={`rounded-lg border px-4 py-1.5 text-xs font-semibold ${
                                  addressForm.label === 'HOME'
                                    ? 'border-[#F8B020] bg-[#F8B020] text-white'
                                    : 'border-stone-300 bg-white text-stone-600'
                                }`}
                              >
                                Home
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  setAddressForm((prev) => ({ ...prev, label: 'OFFICE' }))
                                }
                                className={`rounded-lg border px-4 py-1.5 text-xs font-semibold ${
                                  addressForm.label === 'OFFICE'
                                    ? 'border-[#F8B020] bg-[#F8B020] text-white'
                                    : 'border-stone-300 bg-white text-stone-600'
                                }`}
                              >
                                Office
                              </button>
                            </div>
                          </div>

                          <button
                            type="button"
                            disabled={isLoading}
                            onClick={() => {
                              void handleAddAddress()
                            }}
                            className="mt-3 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
                          >
                            {isLoading ? 'Please wait...' : 'Save'}
                          </button>
                        </div>
                      ) : (
                        <>
                          <div className="flex justify-center">
                            <div className="h-20 w-20 overflow-hidden rounded-full border-2 border-[#F8B020] bg-white">
                              <img
                                src={profilePic || '/logo.png'}
                                alt="Profile"
                                className="h-full w-full object-cover"
                              />
                            </div>
                          </div>

                          <div className="grid grid-cols-2 gap-3">
                            <label className="block text-sm font-semibold text-stone-700">
                              First Name
                              <input
                                type="text"
                                value={accountForm.firstname}
                                readOnly={!isEditingProfile}
                                onChange={(event) =>
                                  setAccountForm((prev) => ({ ...prev, firstname: event.target.value }))
                                }
                                className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                  isEditingProfile
                                    ? 'text-stone-800 focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]'
                                    : 'text-stone-500'
                                }`}
                              />
                            </label>
                            <label className="block text-sm font-semibold text-stone-700">
                              Last Name
                              <input
                                type="text"
                                value={accountForm.lastname}
                                readOnly={!isEditingProfile}
                                onChange={(event) =>
                                  setAccountForm((prev) => ({ ...prev, lastname: event.target.value }))
                                }
                                className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                  isEditingProfile
                                    ? 'text-stone-800 focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]'
                                    : 'text-stone-500'
                                }`}
                              />
                            </label>
                          </div>

                          <label className="block text-sm font-semibold text-stone-700">
                            Mobile Number
                            <input
                              type="tel"
                              value={accountForm.phoneNumber}
                              readOnly={!isEditingProfile}
                              onChange={(event) =>
                                setAccountForm((prev) => ({ ...prev, phoneNumber: event.target.value }))
                              }
                              className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                isEditingProfile
                                  ? 'text-stone-800 focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]'
                                  : 'text-stone-500'
                              }`}
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Email ID
                            <input
                              type="email"
                              value={accountForm.email}
                              readOnly
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-500 shadow-md outline-none"
                            />
                          </label>

                          <div className="rounded-2xl border border-stone-300 bg-white px-3 py-2 shadow-md">
                            <p className="text-sm font-semibold text-stone-700">Password</p>
                            <div className="mt-1 flex items-center justify-between">
                              <p className="text-sm text-stone-500">********</p>
                            </div>
                          </div>

                          <button
                            type="button"
                            onClick={() => setIsAddressFormOpen(true)}
                            className="flex w-full items-center justify-between rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm font-semibold text-stone-700 shadow-md"
                          >
                            {hasSavedAddress ? 'Edit Address' : 'Add Address'}
                            <span>›</span>
                          </button>

                          {hasSavedAddress ? (
                            <div className="rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-700 shadow-sm">
                              <p className="font-semibold text-stone-800">
                                {addressForm.label || 'HOME'} Address
                              </p>
                              <p className="mt-1 text-xs leading-relaxed text-stone-600">
                                {addressSummary}
                              </p>
                            </div>
                          ) : null}

                          <button
                        type="button"
                        onClick={() => {
                          resetAuthMessages()
                          setIsEditingProfile(true)
                        }}
                        className="w-full rounded-2xl border border-[#F8B020] bg-white py-3 text-base font-semibold text-[#F8B020] shadow-sm transition hover:bg-[#FFF7E8]"
                      >
                        Edit Profile
                      </button>

                      <button
                            type="submit"
                        disabled={isLoading || isProfileLoading || !isEditingProfile}
                            className="mt-2 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
                          >
                        {isLoading ? 'Please wait...' : 'Update Profile'}
                          </button>

                          <button
                            type="button"
                            onClick={handleLogout}
                            className="w-full rounded-2xl border border-red-300 bg-white py-3 text-base font-semibold text-red-500 shadow-sm"
                          >
                            Log Out
                          </button>
                        </>
                      )}
                    </>
                  )}
                </form>
              ) : (
                <div className="min-h-[58vh] rounded-t-3xl bg-[#efefef] px-4 pt-6 pb-10">
                  <div className="mt-4 flex justify-center">
                    <img
                      src="/trust-team.jpg"
                      alt=""
                      className="h-44 w-52 rounded-2xl object-cover opacity-95"
                    />
                  </div>
                </div>
              )}
            </div>
          ) : panelMode === 'forgot-email' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#efe7b8] via-[#f2db72] to-[#f4cd2f] px-4 pt-6 pb-8"
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
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#F8B020] focus:ring-2 focus:ring-[#F8B020]/40"
                />
              </label>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
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
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#efe7b8] via-[#f2db72] to-[#f4cd2f] px-4 pt-6 pb-8"
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
                    className="h-12 w-12 rounded-xl border border-stone-300 bg-white text-center text-lg font-semibold text-stone-800 shadow-sm outline-none focus:border-[#F8B020] focus:ring-2 focus:ring-[#F8B020]/35"
                  />
                ))}
              </div>

              <button
                type="button"
                onClick={handleResendOtp}
                className="text-xs font-medium text-[#E2A11D] hover:underline"
              >
                I didn&apos;t receive the code? Send again
              </button>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
              >
                {isLoading ? 'Please wait...' : 'Verify'}
              </button>

              <div className="flex justify-center pt-3">
                <img src="/trust-team.jpg" alt="" className="h-28 w-36 rounded-2xl object-cover opacity-90" />
              </div>
            </form>
          ) : panelMode === 'forgot-reset' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#efe7b8] via-[#f2db72] to-[#f4cd2f] px-4 pt-6 pb-8"
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
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#F8B020] focus:ring-2 focus:ring-[#F8B020]/40"
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
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#F8B020] focus:ring-2 focus:ring-[#F8B020]/40"
                />
              </label>

              <div className="flex justify-center pt-3">
                <img src="/trust-team.jpg" alt="" className="h-36 w-44 rounded-full object-cover opacity-90" />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
              >
                {isLoading ? 'Please wait...' : 'Update'}
              </button>
            </form>
          ) : panelMode === 'login' ? (
            <form
              className="space-y-4 rounded-t-[34px] bg-gradient-to-b from-[#efe7b8] via-[#f2db72] to-[#f4cd2f] px-4 pt-6 pb-8"
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
                  className="mt-1.5 h-13 w-full rounded-2xl border border-stone-300 bg-white px-4 text-sm text-stone-800 shadow-[0_4px_10px_rgba(0,0,0,0.12)] outline-none transition focus:border-[#F8B020] focus:ring-2 focus:ring-[#F8B020]/40"
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
              className="space-y-3 rounded-t-3xl bg-gradient-to-b from-[#efe5ad] to-[#f3cf45] px-4 py-5"
              onSubmit={handleSignupSubmit}
            >
              <label className="block text-sm font-semibold text-stone-700">
                First Name
                <input
                  type="text"
                  placeholder="Anada"
                  value={signupForm.firstname}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, firstname: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Last Name
                <input
                  type="text"
                  placeholder="Khanna"
                  value={signupForm.lastname}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, lastname: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
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
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
                />
              </label>

              <label className="block text-sm font-semibold text-stone-700">
                Email ID
                <input
                  type="email"
                  placeholder="angad@example.com"
                  value={signupForm.email}
                  onChange={(event) =>
                    setSignupForm((prev) => ({ ...prev, email: event.target.value }))
                  }
                  className="mt-1.5 w-full rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#F8B020] focus:ring-1 focus:ring-[#F8B020]"
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
                className="mt-2 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
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
                  className="font-semibold text-red-600 hover:underline"
                >
                  Login
                </button>
              </p>
            </form>
          )}
        </aside>
      </div>
      {isDownloadPopupOpen ? (
        <div className="fixed inset-0 z-50 grid place-items-center bg-black/45 p-4">
          <div className="w-full max-w-sm rounded-2xl border border-stone-200 bg-white p-5 text-center shadow-2xl">
            <h3 className="text-3xl font-black text-[#F8B020]">Download</h3>
            <div className="mx-auto mt-3 grid h-20 w-20 place-items-center rounded-full bg-[#FFF7E8]">
              <svg viewBox="0 0 24 24" className="h-10 w-10 text-[#F8B020]" fill="none" stroke="currentColor" strokeWidth="2">
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
              className="mt-4 w-full rounded-2xl bg-[#F8B020] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#E2A11D]"
            >
              Download File
            </button>
            <p className="mt-2 text-xs font-semibold text-red-500">Only one time download available</p>
            <button
              type="button"
              onClick={() => setIsDownloadPopupOpen(false)}
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

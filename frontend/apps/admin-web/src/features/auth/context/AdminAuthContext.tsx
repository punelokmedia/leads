import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

const AUTH_STORAGE_KEY = 'admin_auth_session'
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') ?? 'http://localhost:5000'
const ADMIN_AUTH_BASE = `${API_BASE_URL}/api/v1/admin`

type AdminSession = {
  email: string
  token: string
}

type AdminAuthContextValue = {
  isAuthenticated: boolean
  userEmail: string
  pendingEmail: string
  sendOtp: (email: string) => Promise<void>
  verifyOtp: (otp: string) => Promise<boolean>
  resetOtpFlow: () => void
  logout: () => void
}

const AdminAuthContext = createContext<AdminAuthContextValue | null>(null)

type ApiResponse<T = unknown> = {
  success?: boolean
  message?: string
  token?: string
  data?: T
}

type VerifyOtpResponseData = {
  email?: string
}

async function parseApiResponse<T>(
  response: Response,
): Promise<{ ok: boolean; payload: ApiResponse<T> }> {
  let payload: ApiResponse<T> = {}

  try {
    payload = (await response.json()) as ApiResponse<T>
  } catch {
    payload = {}
  }

  return { ok: response.ok, payload }
}

function readStoredSession(): AdminSession | null {
  if (typeof window === 'undefined') {
    return null
  }

  const raw = window.localStorage.getItem(AUTH_STORAGE_KEY)
  if (!raw) {
    return null
  }

  try {
    const parsed = JSON.parse(raw) as AdminSession
    if (parsed.email && parsed.token) {
      return parsed
    }
  } catch {
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
  }

  return null
}

export function AdminAuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<AdminSession | null>(() =>
    readStoredSession(),
  )
  const [pendingEmail, setPendingEmail] = useState('')

  const sendOtp = useCallback(async (email: string) => {
    const response = await fetch(`${ADMIN_AUTH_BASE}/send-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    })
    const { ok, payload } = await parseApiResponse(response)

    if (!ok || !payload.success) {
      throw new Error(payload.message ?? 'Failed to send OTP.')
    }

    setPendingEmail(email)
  }, [])

  const verifyOtp = useCallback(
    async (otp: string) => {
      if (!pendingEmail) {
        return false
      }

      const response = await fetch(`${ADMIN_AUTH_BASE}/verify-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email: pendingEmail, otp }),
      })
      const { ok, payload } = await parseApiResponse<VerifyOtpResponseData>(response)

      if (!ok || !payload.success || !payload.token) {
        throw new Error(payload.message ?? 'OTP verification failed.')
      }

      const nextSession = {
        email: payload.data?.email ?? pendingEmail,
        token: payload.token,
      }
      setSession(nextSession)
      setPendingEmail('')
      window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(nextSession))

      return true
    },
    [pendingEmail],
  )

  const resetOtpFlow = useCallback(() => {
    setPendingEmail('')
  }, [])

  const logout = useCallback(() => {
    setSession(null)
    setPendingEmail('')
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
  }, [])

  const value = useMemo<AdminAuthContextValue>(
    () => ({
      isAuthenticated: Boolean(session),
      userEmail: session?.email ?? '',
      pendingEmail,
      sendOtp,
      verifyOtp,
      resetOtpFlow,
      logout,
    }),
    [logout, pendingEmail, sendOtp, session, verifyOtp, resetOtpFlow],
  )

  return (
    <AdminAuthContext.Provider value={value}>
      {children}
    </AdminAuthContext.Provider>
  )
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAdminAuth() {
  const context = useContext(AdminAuthContext)
  if (!context) {
    throw new Error('useAdminAuth must be used inside AdminAuthProvider')
  }
  return context
}

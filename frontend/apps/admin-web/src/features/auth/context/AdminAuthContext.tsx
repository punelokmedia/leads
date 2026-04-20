import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

const AUTH_STORAGE_KEY = 'admin_auth_session'

type AdminSession = {
  email: string
}

type AdminAuthContextValue = {
  isAuthenticated: boolean
  userEmail: string
  pendingEmail: string
  demoOtp: string
  sendOtp: (email: string) => Promise<void>
  verifyOtp: (otp: string) => Promise<boolean>
  resetOtpFlow: () => void
  logout: () => void
}

const AdminAuthContext = createContext<AdminAuthContextValue | null>(null)

function createOtpCode() {
  return String(Math.floor(100000 + Math.random() * 900000))
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
    if (parsed.email) {
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
  const [demoOtp, setDemoOtp] = useState('')

  const sendOtp = useCallback(async (email: string) => {
    await new Promise((resolve) => setTimeout(resolve, 500))

    setPendingEmail(email)
    setDemoOtp(createOtpCode())
  }, [])

  const verifyOtp = useCallback(
    async (otp: string) => {
      await new Promise((resolve) => setTimeout(resolve, 400))

      if (!pendingEmail || otp !== demoOtp) {
        return false
      }

      const nextSession = { email: pendingEmail }
      setSession(nextSession)
      setPendingEmail('')
      setDemoOtp('')
      window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(nextSession))

      return true
    },
    [demoOtp, pendingEmail],
  )

  const resetOtpFlow = useCallback(() => {
    setPendingEmail('')
    setDemoOtp('')
  }, [])

  const logout = useCallback(() => {
    setSession(null)
    setPendingEmail('')
    setDemoOtp('')
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
  }, [])

  const value = useMemo<AdminAuthContextValue>(
    () => ({
      isAuthenticated: Boolean(session),
      userEmail: session?.email ?? '',
      pendingEmail,
      demoOtp,
      sendOtp,
      verifyOtp,
      resetOtpFlow,
      logout,
    }),
    [demoOtp, logout, pendingEmail, sendOtp, session, verifyOtp, resetOtpFlow],
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

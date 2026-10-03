const configuredBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim().replace(/\/+$/, '')

export const API_BASE_URL = configuredBaseUrl || (
  import.meta.env.DEV ? 'http://localhost:5000' : 'https://leads-qa6h.vercel.app'
)

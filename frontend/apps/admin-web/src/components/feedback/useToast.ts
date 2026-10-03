import { createContext, useContext } from 'react'

export type ToastVariant = 'success' | 'error' | 'info'

export type ToastInput = {
  title: string
  description?: string
  durationMs?: number
}

export type ToastApi = {
  show: (input: ToastInput & { variant?: ToastVariant }) => void
  success: (input: ToastInput | string) => void
  error: (input: ToastInput | string) => void
  info: (input: ToastInput | string) => void
}

export const ToastContext = createContext<ToastApi | null>(null)

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within ToastProvider')
  }
  return context
}

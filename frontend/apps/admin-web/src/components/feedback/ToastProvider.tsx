import {
  useCallback,
  useMemo,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react'

import { ToastContext, type ToastApi, type ToastInput, type ToastVariant } from './useToast'

type ToastItem = {
  id: string
  title: string
  description?: string
  variant: ToastVariant
}

const variantStyles: Record<ToastVariant, { chip: string; dot: string }> = {
  success: {
    chip: 'border-emerald-200 bg-emerald-50 text-emerald-800',
    dot: 'bg-emerald-500',
  },
  error: {
    chip: 'border-rose-200 bg-rose-50 text-rose-800',
    dot: 'bg-rose-500',
  },
  info: {
    chip: 'border-violet-200 bg-violet-50 text-violet-800',
    dot: 'bg-violet-500',
  },
}

function normalizeInput(input: ToastInput | string): ToastInput {
  return typeof input === 'string' ? { title: input } : input
}

export function ToastProvider({ children }: PropsWithChildren) {
  const [toasts, setToasts] = useState<ToastItem[]>([])
  const timeoutMapRef = useRef<Record<string, number>>({})

  const removeToast = useCallback((id: string) => {
    setToasts((previous) => previous.filter((item) => item.id !== id))
    const timerId = timeoutMapRef.current[id]
    if (timerId) {
      window.clearTimeout(timerId)
      delete timeoutMapRef.current[id]
    }
  }, [])

  const show = useCallback(
    ({ variant = 'info', title, description, durationMs = 3200 }: ToastInput & { variant?: ToastVariant }) => {
      const id =
        typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
          ? crypto.randomUUID()
          : `${Date.now()}-${Math.random().toString(16).slice(2)}`

      setToasts((previous) => [...previous, { id, variant, title, description }])
      timeoutMapRef.current[id] = window.setTimeout(() => removeToast(id), durationMs)
    },
    [removeToast],
  )

  const api = useMemo<ToastApi>(
    () => ({
      show,
      success: (input) => {
        const normalized = normalizeInput(input)
        show({ ...normalized, variant: 'success' })
      },
      error: (input) => {
        const normalized = normalizeInput(input)
        show({ ...normalized, variant: 'error' })
      },
      info: (input) => {
        const normalized = normalizeInput(input)
        show({ ...normalized, variant: 'info' })
      },
    }),
    [show],
  )

  return (
    <ToastContext.Provider value={api}>
      {children}
      <div className="pointer-events-none fixed right-4 top-4 z-[120] flex w-[min(92vw,380px)] flex-col gap-2">
        {toasts.map((toast) => {
          const style = variantStyles[toast.variant]
          return (
            <div
              key={toast.id}
              className={`toast-enter pointer-events-auto rounded-xl border p-3 shadow-lg backdrop-blur-xl transition-all duration-200 ${style.chip}`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="flex items-center gap-2 text-sm font-semibold">
                    <span className={`h-2 w-2 rounded-full ${style.dot}`} />
                    {toast.title}
                  </p>
                  {toast.description ? (
                    <p className="mt-1 text-xs opacity-85">{toast.description}</p>
                  ) : null}
                </div>
                <button
                  type="button"
                  onClick={() => removeToast(toast.id)}
                  className="rounded-md border border-current/25 px-2 py-0.5 text-[11px] font-medium opacity-80 transition hover:opacity-100"
                >
                  Close
                </button>
              </div>
            </div>
          )
        })}
      </div>
    </ToastContext.Provider>
  )
}

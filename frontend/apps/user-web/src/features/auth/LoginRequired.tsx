import { useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import './login-required.css'
import { animateWindowClose } from '@/components/layout/motion'
export function LoginRequired({ returnTo }: { returnTo: string }) {
  const dialog = useRef<HTMLDialogElement>(null)
  const navigate = useNavigate()
  useEffect(() => {
    const element = dialog.current
    element?.showModal()
    return () => element?.close()
  }, [])
  const close = () => animateWindowClose(dialog.current, () => navigate('/'))
  return <div className="login-required-page"><dialog ref={dialog} className="login-required-dialog" aria-labelledby="login-required-title" aria-describedby="login-required-description" onCancel={event => { event.preventDefault(); close() }}><button type="button" className="login-required-close" aria-label="Close and return home" onClick={close}>×</button><span className="login-required-icon" aria-hidden="true">♙</span><h1 id="login-required-title">Sign in to continue</h1><p id="login-required-description">Log in to explore all categories, browse leads and access your NextLead account.</p><button type="button" className="login-required-primary" onClick={() => { sessionStorage.setItem('login_return_to', returnTo); animateWindowClose(dialog.current, () => navigate('/login')) }}>Login / Sign up →</button><button type="button" className="login-required-home" onClick={close}>Back to Home</button></dialog></div>
}

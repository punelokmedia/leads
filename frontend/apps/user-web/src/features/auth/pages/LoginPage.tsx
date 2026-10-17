import { useState } from 'react'
import { Link } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import { startGoogleLogin } from '../googleHandoff'
import './login.css'

export function LoginPage() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const continueWithGoogle = async () => {
    if (isLoading) return
    setIsLoading(true)
    setError('')
    try {
      await startGoogleLogin(`${API_BASE_URL}/api/v1/auth/google`)
    } catch {
      setError('Unable to start Google login. Please try again.')
      setIsLoading(false)
    }
  }

  return (
    <main className="login-page">
      <div className="login-card">
        <aside className="login-brand-panel">
          <Link to="/" className="login-brand" aria-label="NextLead home">
            <img src="/New nextlead logo/NextLead Ribbon Growth Logo.png" alt="NextLead" />
          </Link>
          <h1>Your next big project<br />starts here.</h1>
          <img className="login-brand-arrow" src="/NextLead Arrow only.png" alt="" aria-hidden="true" />
          <p>Discover relevant leads, connect with potential customers and grow your business.</p>
        </aside>

        <section className="login-content" aria-labelledby="login-title">
          <Link to="/" className="login-close">Close</Link>
          <div className="login-form-content">
            <h2 id="login-title">Welcome back!</h2>
            <p className="login-subtitle">Login to continue.</p>
            <div className="login-options">
              <button className="login-google" type="button" disabled={isLoading} onClick={() => void continueWithGoogle()}>
                <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
                  <path fill="#4285F4" d="M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.61 4.61 0 0 1-1.99 3.02v2.51h3.23c1.89-1.74 2.98-4.3 2.98-7.36Z" />
                  <path fill="#34A853" d="M12 22c2.7 0 4.96-.9 6.62-2.41l-3.23-2.51c-.9.6-2.04.96-3.39.96-2.6 0-4.81-1.76-5.6-4.12H3.06v2.59A10 10 0 0 0 12 22Z" />
                  <path fill="#FBBC05" d="M6.4 13.92A6 6 0 0 1 6.09 12c0-.67.11-1.32.31-1.92V7.49H3.06A10 10 0 0 0 2 12c0 1.61.39 3.14 1.06 4.51l3.34-2.59Z" />
                  <path fill="#EA4335" d="M12 5.96c1.47 0 2.79.5 3.82 1.49l2.87-2.87A9.6 9.6 0 0 0 12 2a10 10 0 0 0-8.94 5.49l3.34 2.59A5.99 5.99 0 0 1 12 5.96Z" />
                </svg>
                {isLoading ? 'Connecting...' : 'Continue With Google'}
              </button>
              <span className="login-or">OR</span>
              <Link className="login-phone" to="/auth/mobile?method=phone">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true"><rect x="7" y="2" width="10" height="20" rx="2" /><path d="M10 5h4M11 19h2" /></svg>
                Continue With Phone
              </Link>
            </div>
            <p className="login-security">Secure access to your vendor account.</p>
            {error && <p className="login-error" role="alert">{error}</p>}
            <div className="login-legal"><Link to="/terms-service">Terms of Service.</Link> <Link to="/privacy-policy">Privacy Policy</Link></div>
          </div>
        </section>
      </div>
    </main>
  )
}

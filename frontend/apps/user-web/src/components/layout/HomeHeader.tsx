import { useState } from 'react'
import { Link } from 'react-router-dom'

export function HomeHeader() {
  const [menuOpen, setMenuOpen] = useState(false)
  const closeMenu = () => setMenuOpen(false)

  return (
    <header className="home-site-header">
      <div className="home-header-inner">
        <Link to="/" className="home-header-logo" aria-label="NextLead home" onClick={closeMenu}>
          <span className="home-header-mark"><img src="/New nextlead logo/NextLead Ribbon Growth Logo.png" alt="" /></span>
          <span>Next<span>Lead</span></span>
        </Link>
        <button type="button" className="home-menu-toggle" aria-label={menuOpen ? 'Close navigation' : 'Open navigation'} aria-expanded={menuOpen} aria-controls="home-header-navigation" onClick={() => setMenuOpen(!menuOpen)}>
          <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d={menuOpen ? 'M6 6l12 12M6 18L18 6' : 'M3 6h18M3 12h18M3 18h18'} /></svg>
        </button>
        <nav id="home-header-navigation" className={`home-header-navigation${menuOpen ? ' is-open' : ''}`} aria-label="Main navigation">
          <div className="home-header-links">
            <Link to="/" className="is-active" aria-current="page" onClick={closeMenu}>Home</Link>
            <a href="/#categories" onClick={closeMenu}>Categories</a>
            <a href="/#how-it-works" onClick={closeMenu}>How It Works</a>
            <a href="/#about-us" onClick={closeMenu}>About Us</a>
          </div>
          <div className="home-header-actions">
            <Link className="header-download" to="/download" onClick={closeMenu}>Download App</Link>
            <Link className="header-login" to="/login" onClick={closeMenu}>Login/Signup</Link>
          </div>
        </nav>
      </div>
    </header>
  )
}


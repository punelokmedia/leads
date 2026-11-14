import { Link, useLocation } from 'react-router-dom'
import { MobileNavigation } from './MobileNavigation'
import './home-icon.css'

export function HomeHeader() {
  const location = useLocation()

  return (
    <header className="home-site-header">
      <div className="home-header-inner">
        <Link to="/" className="home-header-logo" aria-label="NextLead home">
          <img className="home-header-logo-image" src="/optimized/home/logo.webp" alt="NextLead" width={2170} height={725} />
        </Link>
        <nav id="home-header-navigation" className="home-header-navigation" aria-label="Main navigation">
          <div className="home-header-links">
            <Link to="/" className="is-active navbar-home-link" aria-current={location.pathname === '/' ? 'page' : undefined}><img className="navbar-home-icon" src="/home-icon.svg" width={20} height={20} alt="" />Home</Link>
            <Link to="/categories">Categories</Link>
            <a href="/#how-it-works">How It Works</a>
            <a href="/#about-us">About Us</a>
          </div>
          <div className="home-header-actions">
            <Link className="header-download" to="/download">Download App</Link>
            <Link className="header-login" to="/login">Login/Signup</Link>
          </div>
        </nav>
        <MobileNavigation key={location.key}>
          <Link to="/" className="navbar-home-link"><img className="navbar-home-icon" src="/home-icon.svg" width={20} height={20} alt="" />Home</Link><Link to="/categories">Categories</Link>
          <a href="/#how-it-works">How It Works</a><a href="/#about-us">About Us</a>
          <Link to="/download">Download App</Link><Link to="/login">Login/Signup</Link>
        </MobileNavigation>
      </div>
    </header>
  )
}


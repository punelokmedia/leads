import { Link, useLocation } from 'react-router-dom'
import { MobileNavigation } from './MobileNavigation'

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
            <Link to="/" className="is-active" aria-current="page">Home</Link>
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
          <Link to="/">Home</Link><Link to="/categories">Categories</Link>
          <a href="/#how-it-works">How It Works</a><a href="/#about-us">About Us</a>
          <Link to="/download">Download App</Link><Link to="/login">Login/Signup</Link>
        </MobileNavigation>
      </div>
    </header>
  )
}


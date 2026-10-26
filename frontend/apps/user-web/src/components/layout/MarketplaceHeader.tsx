import { useState, type ReactNode } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import './marketplace-header.css'

function Icon({ children }: { children: ReactNode }) {
  return <svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{children}</svg>
}

export function MarketplaceHeader({ loggedIn, cartCount, onLogout }: {
  loggedIn: boolean
  cartCount: number
  onLogout: () => void
}) {
  const [search, setSearch] = useState('')
  const navigate = useNavigate()
  return <div className="marketplace-header-inner">
    <Link to="/" className="marketplace-logo" aria-label="NextLead home">
      <img src="/New nextlead logo/NextLead Ribbon Arrow Logo.png" alt="NextLead" />
    </Link>
    <form className="marketplace-search" role="search" onSubmit={event => {
      event.preventDefault()
      navigate(`/?browse=1&search=${encodeURIComponent(search.trim())}`)
    }}>
      <Icon><circle cx="10.5" cy="10.5" r="6.5" /><path d="m16 16 4 4" /></Icon>
      <input aria-label="Search leads by category, city or keyword" placeholder="Search leads by category, city or keyword" value={search} onChange={event => setSearch(event.target.value)} />
      <button type="submit" aria-label="Search leads"><Icon><circle cx="10.5" cy="10.5" r="6" /><path d="m15 15 4 4" /></Icon></button>
    </form>
    <nav className="marketplace-actions" aria-label="Main navigation">
      <Link to="/pricing" className="membership"><Icon><path d="m3 6 5 4 4-6 4 6 5-4-2 13H5L3 6Z" /><path d="M5 16h14" /></Icon><span>Membership</span></Link>
      <Link to="/wallet" className="wallet"><Icon><rect x="3" y="5" width="18" height="15" rx="3" /><path d="M3 9h18m-6 5h3" /></Icon><span>Wallet</span></Link>
      <Link to="/referrals" className="referral"><Icon><rect x="3" y="8" width="18" height="4" rx="1" /><path d="M5 12v9h14v-9M12 8v13M12 8H8a3 3 0 1 1 3-3l1 3Zm0 0h4a3 3 0 1 0-3-3l-1 3Z" /></Icon><span>Referral</span></Link>
      <Link to={loggedIn ? '/profile' : '/auth/mobile'}><Icon><circle cx="12" cy="7" r="3.5" /><path d="M5 21v-3a7 7 0 0 1 14 0v3" /></Icon><span>Profile</span></Link>
      <Link to={loggedIn ? '/cart' : '/auth/mobile'} className="marketplace-cart"><Icon><path d="M2 3h3l3 13h11l3-10H6" /><circle cx="9" cy="21" r="1" /><circle cx="18" cy="21" r="1" /></Icon>{cartCount > 0 && <b aria-label={`${cartCount} cart items`}>{cartCount}</b>}<span>Cart</span></Link>
      <button type="button" className="marketplace-session" onClick={loggedIn ? onLogout : () => navigate('/auth/mobile')}><Icon><path d="M10 3H4v18h6m4-14 5 5-5 5m-6-5h11" /></Icon><span>{loggedIn ? 'Logout' : 'Login'}</span></button>
    </nav>
  </div>
}

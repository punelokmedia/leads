import { useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { CategoryLink } from './CategoryLink'
import { categories } from './category-catalog'
import './categories.css'

const details = [
  ['Painting', 'Find professional painters near you.', 'roller'],
  ['Interior Design', 'Turn your space into your dream space.', 'sofa'],
  ['Plumbing', 'Get expert plumbers instantly.', 'tap'],
  ['AC Service & Repair', 'Keep your cool all year round.', 'snow'],
  ['Water Proofing', 'Protect your property from water damage.', 'drop'],
  ['Civil Work', 'Build better with trusted contractors.', 'helmet'],
  ['Aluminium & Windows', 'Add style and strength to your space.', 'window'],
  ['Electrical Work', 'Reliable electrical services at your doorstep.', 'bolt'],
  ['POP & False Ceiling Work', 'Give your space a beautiful finishing touch.', 'window'],
  ['CCTV Installation', 'Discover opportunities to secure homes and businesses.', 'camera'],
  ['Real Estate', 'Discover your next property opportunity.', 'home'],
]
function CategoryIcon({ kind }: { kind: string }) {
  const paths: Record<string, ReactNode> = {
    roller: <><rect x="3" y="3" width="15" height="7" rx="2" /><path d="M18 6h3v8H11v7M8 21h6" /></>,
    sofa: <><path d="M5 12V7a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v5M3 18v3m18-3v3" /><rect x="2" y="11" width="20" height="7" rx="2" /><path d="M7 11v4h10v-4" /></>,
    tap: <><path d="M4 10h11a4 4 0 0 1 4 4v2h-5v-2H8v6H3v-7M10 10V4m-4 0h8M19 19v2" /></>,
    snow: <path d="M12 2v20M3 7l18 10M3 17 21 7M9 3l3 3 3-3M9 21l3-3 3 3M3 10l4-1-1-4m15 9-4 1 1 4M3 14l4 1-1 4m15-9-4-1 1-4" />,
    drop: <path d="M12 2S4 11 4 16a8 8 0 0 0 16 0c0-5-8-14-8-14ZM8 15c-1 3 1 4 2 4" />,
    helmet: <path d="M3 17v-4a9 9 0 0 1 18 0v4M9 4v8m6-8v8M2 17h20v4H2Z" />,
    window: <><rect x="4" y="2" width="16" height="20" rx="1" /><path d="M12 2v20M4 12h16" /></>,
    bolt: <path d="m13 2-9 12h7l-1 8 10-13h-8Z" />,
    camera: <path d="m3 4 17 5-3 9L1 12ZM17 17l4 3h2M8 15l-2 6" />,
    home: <path d="m2 11 10-9 10 9M5 9v13h14V9M10 22v-8h4v8" />,
  }
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[kind]}</svg>
}
export function CategoriesPage() {
  const [query, setQuery] = useState('')
  const visible = details.filter(([name, description]) => `${name} ${description}`.toLowerCase().includes(query.toLowerCase().trim()))
  return <div className="category-directory"><section className="category-directory-inner" aria-labelledby="categories-title">
    <header className="directory-heading"><span>FIND YOUR NEXT OPPORTUNITY</span><h1 id="categories-title">Explore Leads by Category</h1><p>The right leads. The right category. Your next big opportunity.</p></header>
    <form className="directory-search" role="search" onSubmit={event => event.preventDefault()}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true"><circle cx="10" cy="10" r="7" /><path d="m15 15 6 6" /></svg>
      <label className="directory-sr-only" htmlFor="category-search">Search categories</label><input id="category-search" type="search" placeholder="Search categories..." value={query} onChange={event => setQuery(event.target.value)} /><button type="submit">Search</button>
    </form>
    <div className="directory-grid">{visible.map(([name, description, icon]) => <CategoryLink key={name} name={name} className="directory-card">
      <div className="directory-photo"><img src={encodeURI(categories.find(category => category.name === name)?.image || '/lead-room-1.jpg')} alt="" loading="lazy" width="220" height="160" /></div>
      <span className={`directory-icon directory-icon-${icon}`}><CategoryIcon kind={icon} /></span>
      <div className="directory-copy"><h2>{name}</h2><p>{description}</p><span className="directory-availability"><svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="9" cy="6" r="3" /><circle cx="18" cy="8" r="2.5" /><path d="M2 19v-3a7 7 0 0 1 14 0v3Zm15 0v-3a9 9 0 0 0-1-4 5 5 0 0 1 7 4v3Z" /></svg>Explore available leads</span></div>
      <span className="directory-explore">Explore Leads <img className="directory-arrow" src="/Icons/icons8-right-24.png" alt="" width="24" height="24" /></span>
    </CategoryLink>)}</div>
    {visible.length === 0 && <div className="directory-empty" role="status"><h2>No categories found</h2><p>Try another service or category name.</p><button onClick={() => setQuery('')}>Show all categories</button></div>}
    <aside className="directory-business"><img className="directory-growth" src="/categories%20Images/gwroth-removebg-preview.png" alt="" width="140" height="120" /><div><h2>Want to Add Your Business?</h2><p>Get discovered by potential customers on NextLead.</p></div><Link to="/signup">Add Your Business <img className="directory-arrow" src="/Icons/icons8-right-24.png" alt="" width="24" height="24" /></Link></aside>
  </section></div>
}


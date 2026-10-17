import { Link, useSearchParams } from 'react-router-dom'
import { LeadsMarketplacePage } from './LeadsMarketplacePage'
import { CategoryGrid } from './CategoryGrid'
import './home.css'
import { VendorSection } from './VendorSection'
import { TestimonialsSection } from './TestimonialsSection'

export function HomePage() {
  const [params] = useSearchParams()
  if (params.has('category') || params.has('city') || params.has('browse')) return <LeadsMarketplacePage />
  return <div className="next-home">
    <section className="home-hero">
      <div className="home-ribbon" aria-hidden="true" />
      <div className="home-container hero-inner">
        <div className="hero-copy"><h1>Premium Vendors Network<br /><span>Get Real Leads.</span></h1><p>No spam, no cold outreach. Just qualified leads.</p>
          <div className="hero-actions"><Link className="home-button" to="/?browse=1">Explore Leads</Link><a className="watch-link" href="#how-it-works"><img src="/Icons/Play Button.svg" alt="" /><span><strong>Watch Video</strong><small>See How It Works</small></span></a></div>
        </div>
        <img className="hero-art" src="/NextLead Vendor App Promotion.png" alt="A vendor discovering business opportunities on the NextLead app" fetchPriority="high" />
        <div className="hero-badges">
          <span><img src="/Icons/Background.svg" alt="" width={25} height={25} /><b>More Leads</b></span>
          <span><img src="/Icons/Background (1).svg" alt="" width={25} height={25} /><b>Verified Vendors</b></span>
          <span><img src="/Icons/Background (2).svg" alt="" width={25} height={25} /><b>Real Connections</b></span>
        </div>
      </div>
    </section>
    <section id="categories" className="home-categories home-container">
      <div className="section-heading"><div><p className="home-eyebrow">Browse Categories</p><h2>Explore Leads by Category</h2><p>Find the right leads for your business needs from multiple industries.</p></div><Link to="/?browse=1" className="home-text-link">View All Categories &rarr;</Link></div>
      <CategoryGrid />
    </section>
    <section className="home-steps" id="how-it-works"><div className="steps-ribbon" aria-hidden="true" /><div className="home-container steps-inner"><div className="steps-copy"><p className="home-eyebrow">How It Works</p><h2>Get Qualified Leads in 3 Simple Steps</h2><p>Start driving higher quality enquiries with a simple process.</p><div className="steps-grid">{[
      ['Apply & Get Onboarded', 'Create your business profile and complete our quick verification process.'],
      ['Receive Match Alerts', 'Get instant notifications of verified leads matching your services and location.'],
      ['Quote & Grow', 'Connect with clients, win more projects, and grow your business.'],
    ].map(([title, copy], index) => <div className="step" key={title}><span>{index + 1}</span><div><h3>{title}</h3><p>{copy}</p></div></div>)}</div><Link to="/signup" className="home-button">Get Started &rarr;</Link></div><img className="steps-art" src="/Confident South Asian Businesswoman Pointing Up.png" alt="Business professional explaining the three simple steps" loading="lazy" /></div></section>
    <VendorSection />
    <TestimonialsSection />
    <section className="home-download home-container"><div className="download-banner"><div><h2>Ready to Grow Your Business?</h2><p>Join thousands of businesses already using NextLead to find verified vendors and get real leads.</p><Link to="/download" className="home-button">Download App</Link></div><img src="/NextLead App Growth Dashboard.png" alt="NextLead app and business growth dashboard" loading="lazy" /></div></section>
  </div>
}

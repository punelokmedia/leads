import { Link } from 'react-router-dom'
export function PublicFooter() {
  return <footer className="next-footer"><div className="home-container"><div className="footer-grid">
    <div className="footer-brand"><img src="/New nextlead logo/NextLead_Ribbon_Arrow_Logo-removebg-preview.png" alt="NextLead" /><p>Find the leads.<br />Build Real Business.</p><div className="footer-socials">{['Facebook Icon.svg', 'Linkedine icon.svg', 'Youtube Icon.svg'].map(file => <img key={file} src={`/Icons/${file}`} alt={file.split(' ')[0]} />)}</div></div>
    <div><h3>Quick Links</h3><Link to="/">Home</Link><Link to="/contact">Contact Us</Link><Link to="/pricing">Plans & Pricing</Link><Link to="/download">Download App</Link></div>
    <div><h3>Categories</h3>{['POP & False Ceiling Work', 'Interior Design', 'Painting', 'Plumbing', 'Electrical Work'].map(name => <Link key={name} to={`/?browse=1&search=${encodeURIComponent(name)}`}>{name}</Link>)}<Link to="/?browse=1" className="footer-more">View More ?</Link></div>
    <div><h3>Support</h3><Link to="/contact-support">Help Center</Link><Link to="/contact">Contact Us</Link><Link to="/privacy-policy">Privacy Policy</Link><Link to="/terms-service">Terms & Conditions</Link></div>
    <div className="footer-stores"><h3>Download Our App</h3><Link to="/download"><img src="/Icons/Link - App Store Badge.svg" alt="Download on the App Store" /></Link><Link to="/download"><img src="/Icons/Link - Google Play Badge.svg" alt="Get it on Google Play" /></Link></div>
  </div><p className="footer-copyright">© {new Date().getFullYear()} NextLead. All rights reserved.</p></div></footer>
}

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import './download-app.css'

const apkUrl = import.meta.env.VITE_ANDROID_APK_URL || '/downloads/nextleads.apk'
const benefits = [
  { icon: '✓', title: 'Verified enquiries', text: 'Find customer enquiries and explore projects that fit your business.' },
  { icon: '02', title: 'Only two vendors', text: 'Each lead is shared with a maximum of two vendors. More room to make your pitch.' },
  { icon: '↗', title: 'Projects across India', text: 'Browse by city and category to find your next business opportunity.' },
]
const steps = [
  ['Download the APK', 'Open this page on your Android phone and tap the download button.'],
  ['Open the downloaded file', 'Find the NextLeads APK in your browser’s downloads or your Files app.'],
  ['Install and get started', 'If prompted, allow your browser to install this app. Open NextLeads and sign in.'],
]

function DownloadIcon() {
  return <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5" strokeLinecap="round" strokeLinejoin="round" /></svg>
}

export function DownloadAppPage() {
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  useEffect(() => {
    const previous = document.title
    document.title = 'Download the NextLeads Android App | NextLeads'
    return () => { document.title = previous }
  }, [])

  async function downloadApp() {
    if (busy) return
    setBusy(true)
    setMessage('')
    try {
      const response = await fetch(apkUrl, { method: 'HEAD', cache: 'no-store', signal: AbortSignal.timeout(15000) })
      const type = response.headers.get('content-type')?.toLowerCase() || ''
      // A SPA host can return index.html with status 200 for an absent APK.
      if (!response.ok || !['application/vnd.android.package-archive', 'application/octet-stream', 'application/zip'].some(value => type.includes(value))) {
        throw new Error('The Android download is not available yet. Please check back soon.')
      }
      const link = document.createElement('a')
      link.href = apkUrl
      link.download = 'nextleads.apk'
      document.body.appendChild(link)
      link.click()
      link.remove()
      setMessage('Your download has started. Once it finishes, open the APK to install NextLeads.')
    } catch (error) {
      setMessage(error instanceof Error && error.message.includes('not available') ? error.message : 'We couldn’t start the download. Please try again or contact support.')
    } finally {
      setBusy(false)
    }
  }

  const downloadButton = (label = 'Download Android app') => <button type="button" className="app-download-button" onClick={() => { void downloadApp() }} disabled={busy}><DownloadIcon />{busy ? 'Preparing download…' : label}<span aria-hidden="true">↗</span></button>

  return <div className="app-download-page">
    <section className="app-download-hero app-download-container" aria-labelledby="download-title">
      <div className="app-download-copy">
        <span className="app-download-eyebrow"><span /> YOUR BUSINESS. ON THE GO.</span>
        <h1 id="download-title">Your next customer.<br /><em>One tap away.</em></h1>
        <p className="app-download-intro">Good opportunities don’t wait. Find customer enquiries, explore high-value projects, and connect with your next client — right from your phone.</p>
        <div className="app-download-actions">{downloadButton()}<a href="#app-install" className="app-install-link">How to install <span aria-hidden="true">↓</span></a></div>
        <p className="app-download-note">Direct APK download <span>·</span> For Android</p>
        <p className="app-download-status" role="status" aria-live="polite">{message}</p>
        <div className="app-download-proof"><span><b>✓</b> Verified leads</span><span><b>✓</b> Only 2 vendors</span><span><b>✓</b> Across India</span></div>
      </div>
      <figure className="app-download-visual">
        <div className="app-phone-orbit" aria-hidden="true" />
        <span className="app-visual-caption">A LITTLE SCREEN.<br /><strong>BIG OPPORTUNITIES.</strong></span>
        <img src="/images/nextleads-single-phone.png" alt="Illustrative NextLeads home screen with project enquiries and two-vendor lead limits, shown on a single phone" width="1024" height="1536" fetchPriority="high" />
        <figcaption>NextLeads app preview · Illustrative projects</figcaption>
      </figure>
    </section>
    <section className="app-download-features" aria-labelledby="app-features-title">
      <div className="app-download-container">
        <div className="app-features-heading"><span className="app-download-eyebrow">LESS SEARCHING. MORE CONNECTING.</span><h2 id="app-features-title">A better way to find<br />your next project.</h2><p>Everything you need to explore opportunities,<br />wherever your work takes you.</p></div>
        <div className="app-feature-grid">{benefits.map(item => <article key={item.title}><span className="app-feature-icon" aria-hidden="true">{item.icon}</span><h3>{item.title}</h3><p>{item.text}</p></article>)}</div>
      </div>
    </section>
    <section id="app-install" className="app-download-container app-install-section" aria-labelledby="app-install-title">
      <div><span className="app-download-eyebrow">FROM DOWNLOAD TO YOUR NEXT LEAD</span><h2 id="app-install-title">Ready in a<br /><em>few simple steps.</em></h2><p className="app-install-description">No app store account needed.<br />Just your Android phone and a fresh start.</p><Link to="/contact-support" className="app-install-link">Need a hand? Contact support <span aria-hidden="true">↗</span></Link></div>
      <div className="app-install-steps">{steps.map(([title, text], index) => <article key={title}><span className="app-step-number">0{index + 1}</span><div><h3>{title}</h3><p>{text}</p></div></article>)}<p className="app-install-footnote">After installation, you can turn off your browser’s “Install unknown apps” permission. This download is for Android; an iPhone version is not included.</p></div>
    </section>
    <section className="app-download-final"><div className="app-download-container"><span className="app-download-eyebrow">TAKE THE NEXT STEP</span><h2>More opportunities.<br /><em>Right in your pocket.</em></h2>{downloadButton('Get NextLeads for Android')}<p role="status">{message || 'Your next project starts with a connection.'}</p></div></section>
  </div>
}

import { useCallback, useEffect, useRef, useState } from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import './vendors.css'

// Presentation data from the supplied design; not live vendor statistics.
const AUTO_ROLL_INTERVAL_MS = 4000

const vendors = [
  { name: 'Rahul Interiors', since: '2025', location: 'Thergaon, Pune', image: 'Interior Design.jpg', tags: ['Interior Designer', 'Home Interiors'], rating: '4.8', reviews: 864, leads: 1, revenue: '5,00,000' },
  { name: 'Ajay Painting', since: '2026', location: 'Baner, Pune', image: 'Painting.png', tags: ['Wall Painting', 'Home Design'], rating: '3.8', reviews: 164, leads: 2, revenue: '10,00,000' },
  { name: 'Priya POP Work', since: '2025', location: 'Kondhwa, Pune', image: 'POP.jfif', tags: ['POP Design', 'Home Decor'], rating: '4.8', reviews: 962, leads: 2, revenue: '20,00,000' },
  { name: 'Amit Electrical', since: '2025', location: 'Wakad, Pune', image: 'Electrical Work.jpg', tags: ['Electrical Work', 'Home Wiring'], rating: '4.7', reviews: 238, leads: 3, revenue: '8,00,000' },
  { name: 'Pune AC Services', since: '2024', location: 'Aundh, Pune', image: 'AC Service & Repair.jpg', tags: ['AC Service', 'AC Repair'], rating: '4.9', reviews: 412, leads: 4, revenue: '6,00,000' },
]

export function VendorSection() {
  const carouselRef = useRef<HTMLDivElement>(null)
  const touchStartX = useRef<number | null>(null)
  const [activeIndex, setActiveIndex] = useState(0)
  const reduceMotion = useReducedMotion()

  const moveCards = useCallback((direction: -1 | 1) => {
    setActiveIndex(index => (index + direction + vendors.length) % vendors.length)
  }, [])

  useEffect(() => {
    const carousel = carouselRef.current
    if (!carousel) return

    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)')
    let isVisible = false
    let isTouching = false

    const observer = new IntersectionObserver(([entry]) => {
      isVisible = entry.isIntersecting
    }, { threshold: 0.25 })
    observer.observe(carousel)

    const pauseTouch = () => { isTouching = true }
    const resumeTouch = () => { isTouching = false }
    carousel.addEventListener('touchstart', pauseTouch, { passive: true })
    carousel.addEventListener('touchend', resumeTouch)
    carousel.addEventListener('touchcancel', resumeTouch)

    // Reuse the arrow-button movement, including wraparound at the ends.
    const timer = window.setInterval(() => {
      const isInteracting = isTouching || carousel.matches(':hover') ||
        carousel.contains(document.activeElement)

      if (isVisible && !document.hidden && !reducedMotion.matches && !isInteracting) {
        moveCards(1)
      }
    }, AUTO_ROLL_INTERVAL_MS)

    return () => {
      window.clearInterval(timer)
      observer.disconnect()
      carousel.removeEventListener('touchstart', pauseTouch)
      carousel.removeEventListener('touchend', resumeTouch)
      carousel.removeEventListener('touchcancel', resumeTouch)
    }
  }, [moveCards])

  return (
    <section className="home-vendors" aria-labelledby="vendor-heading">
      <div className="home-container" ref={carouselRef}>
        <div className="section-heading">
          <div>
            <p className="home-eyebrow">Featured Vendors</p>
            <h2 id="vendor-heading">Top Rated Vendors</h2>
            <p>Work with verified and trusted vendors who are ready to help you grow.</p>
          </div>
        </div>
        <div className="featured-vendor-carousel" role="region" aria-label="Featured vendors carousel" aria-roledescription="carousel">
          <button type="button" className="featured-vendor-arrow featured-vendor-arrow-left" aria-label="Previous vendor" aria-controls="featured-vendor-track" onClick={() => moveCards(-1)}>
            <img src="/Icons/Option Arrow.svg" alt="" />
          </button>
          <div
            className="featured-vendor-grid"
            id="featured-vendor-track"
            tabIndex={0}
            onTouchStart={event => { touchStartX.current = event.touches[0].clientX }}
            onTouchEnd={event => {
              if (touchStartX.current === null) return
              const distance = touchStartX.current - event.changedTouches[0].clientX
              if (Math.abs(distance) > 40) moveCards(distance > 0 ? 1 : -1)
              touchStartX.current = null
            }}
            aria-label="Vendor cards. Use left and right arrow keys to scroll."
            onKeyDown={event => {
              if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
                event.preventDefault()
                moveCards(event.key === 'ArrowRight' ? 1 : -1)
              }
            }}
          >
          {vendors.map((vendor, index) => {
            // Circular offsets keep rotation continuous between the last and first cards.
            let offset = (index - activeIndex + vendors.length) % vendors.length
            if (offset > vendors.length / 2) offset -= vendors.length
            const isActive = offset === 0
            const isVisible = Math.abs(offset) <= 1

            return (
            <motion.article
              className="featured-vendor"
              key={vendor.name}
              initial={false}
              animate={{
                x: (offset * 85 - 50) + '%',
                scale: isActive ? 1 : 0.78,
                rotateY: reduceMotion ? 0 : offset * -22,
                opacity: isVisible ? (isActive ? 1 : 0.68) : 0,
              }}
              transition={{ duration: reduceMotion ? 0 : 0.7, ease: [0.22, 1, 0.36, 1] }}
              style={{ zIndex: 3 - Math.abs(offset), pointerEvents: isVisible ? 'auto' : 'none' }}
              aria-hidden={!isVisible}
              aria-label={vendor.name + ', card ' + (index + 1) + ' of ' + vendors.length}
              onClick={() => { if (!isActive) setActiveIndex(index) }}
            >
              <div className="featured-vendor-header">
                <div className="featured-vendor-avatar">
                  <img src={encodeURI(`/categories Images/${vendor.image}`)} alt={vendor.name} width={58} height={58} loading="lazy" />
                  <span className="featured-vendor-avatar-check"><img src="/Icons/Right check.svg" alt="Verified" /></span>
                </div>
                <div className="featured-vendor-identity">
                  <h3>{vendor.name}</h3>
                  <p>Since {vendor.since}<span>{vendor.location}</span></p>
                  <div className="featured-vendor-tags">{vendor.tags.map(tag => <span key={tag}>{tag}</span>)}</div>
                </div>
                <div className="featured-vendor-reputation">
                  <span className="featured-vendor-verified"><span><img src="/Icons/Right check.svg" alt="" /></span>Verified Vendor</span>
                  <p className="featured-vendor-rating"><img src="/Icons/Start Rating.svg" alt="Rating" /><strong>{vendor.rating}</strong><span>({vendor.reviews} reviews)</span></p>
                </div>
              </div>
              <div className="featured-vendor-metrics">
                <div className="featured-vendor-leads">
                  <span className="featured-vendor-metric-icon"><img src="/Icons/shopping_cart_.svg" alt="" /></span>
                  <h4>Lead Purchased</h4>
                  <strong>{vendor.leads}</strong>
                  <small>Leads</small>
                </div>
                <div className="featured-vendor-revenue">
                  <span className="featured-vendor-metric-icon"><img src="/Icons/Rs . Icon.svg" alt="" /></span>
                  <h4>Revenue Generated</h4>
                  <strong>&#8377;{vendor.revenue}</strong>
                  <small>Total Earnings</small>
                </div>
              </div>
            </motion.article>
            )
          })}
          </div>
          <button type="button" className="featured-vendor-arrow featured-vendor-arrow-right" aria-label="Next vendor" aria-controls="featured-vendor-track" onClick={() => moveCards(1)}>
            <img src="/Icons/Option Arrow.svg" alt="" />
          </button>
        </div>
        <div className="featured-vendor-dots" aria-label="Choose a vendor">
          {vendors.map((vendor, index) => (
            <button
              type="button"
              key={vendor.name}
              aria-label={'Show ' + vendor.name}
              aria-current={index === activeIndex ? 'true' : undefined}
              className={index === activeIndex ? 'is-active' : ''}
              onClick={() => setActiveIndex(index)}
            />
          ))}
        </div>
      </div>
    </section>
  )
}

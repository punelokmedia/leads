import { useState } from 'react'

// Sample presentation values; replace with live metrics when available.
const testimonials = [
  {
    quote: 'Next Lead has made vendor discovery so easy. We found the right partners and got quality leads within days!',
    name: 'Amit Sharma',
    business: 'Interior Design Firm',
    vendors: '10K+',
    leads: '50K+',
    rating: '4.8',
  },
  {
    quote: 'The leads are relevant and the process is simple. A great way to connect with clients and grow our business.',
    name: 'Rahul Verma',
    business: 'Painting Contractor',
    vendors: '11K+',
    leads: '52K+',
    rating: '4.9',
  },
  {
    quote: 'Finding verified professionals is so much easier now. Everything we need is in one place.',
    name: 'Priya Singh',
    business: 'Business Owner',
    vendors: '12K+',
    leads: '55K+',
    rating: '4.7',
  },
]

export function TestimonialsSection() {
  const [index, setIndex] = useState(0)
  const testimonial = testimonials[index]

  const changeReview = (direction: -1 | 1) => {
    setIndex(current => (current + direction + testimonials.length) % testimonials.length)
  }

  return (
    <section className="home-trust" id="about-us">
      <div className="home-container">
        <p className="home-eyebrow">What Our Users Say</p>
        <h2>Trusted by Thousands of Businesses</h2>
        <p>See what our partners have to say about their experience with NextLead.</p>
        <div className="trust-row">
          <div className="review-controls">
            <button aria-label="Previous review" onClick={() => changeReview(-1)}>&lsaquo;</button>
            <button aria-label="Next review" onClick={() => changeReview(1)}>&rsaquo;</button>
          </div>
          <div className="review-card" aria-live="polite" aria-atomic="true">
            <img src="/trust-team.jpg" alt="Business partners" loading="lazy" />
            <div>
              <blockquote>&ldquo;{testimonial.quote}&rdquo;</blockquote>
              <p><strong>{testimonial.name}</strong><span> / {testimonial.business}</span></p>
            </div>
            <button aria-label="Next testimonial" onClick={() => changeReview(1)}>&rsaquo;</button>
          </div>
          <div className="trust-stats" aria-live="polite" aria-atomic="true">
            <div>
              <strong>{testimonial.vendors}</strong>
              <small>Verified Vendors</small>
            </div>
            <div>
              <strong>{testimonial.leads}</strong>
              <small>Leads Generated</small>
            </div>
            <div>
              <strong className="trust-rating">
                {testimonial.rating}
                <img src="/Icons/Start Rating.svg" alt="stars out of 5" width={17} height={16} />
              </strong>
              <small>User Rating</small>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

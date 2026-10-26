import { Link } from 'react-router-dom'
import { CategoryGrid } from './CategoryGrid'
import './home.css'
import './categories.css'

export function CategoriesPage() {
  return (
    <div className="next-home categories-page">
      <section className="home-container" aria-labelledby="categories-title">
        <div className="categories-close"><Link to="/" aria-label="Close categories and return home">Close</Link></div>
        <div className="categories-heading">
          <h1 id="categories-title">Explore Leads by Category</h1>
          <p>Find the right leads for your business needs from multiple industries.</p>
        </div>
        <CategoryGrid showAll />
      </section>
    </div>
  )
}

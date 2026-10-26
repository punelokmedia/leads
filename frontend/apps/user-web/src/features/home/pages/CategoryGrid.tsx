import { categories } from './category-catalog'
import './category-cards.css'
import { CategoryLink } from './CategoryLink'

export function CategoryGrid({ showAll = false }: { showAll?: boolean }) {
  const items = showAll
    ? [...categories, { name: 'Real Estate', image: '/lead-room-1.jpg' }]
    : categories
  return (
    <div className="category-grid">
      {items.map(({ name, image }) => (
        <CategoryLink
          key={name}
          name={name}
          className="category-tile"
        >
          <img
            className="category-image"
            src={encodeURI(image.startsWith('/') ? image : `/categories Images/${image}`)}
            alt={name}
            width={80}
            height={72}
          />
<div className="category-card-label">
          <h3>{name}</h3>
          <small>Explore leads</small></div>
        </CategoryLink>
      ))}
    </div>
  )
}


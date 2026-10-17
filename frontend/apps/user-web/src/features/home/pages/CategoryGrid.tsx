import { Link } from 'react-router-dom'

const categories = [
  { name: 'POP & False Ceiling Work', image: 'POP.jfif' },
  { name: 'Interior Design', image: 'Interior Design.jpg' },
  { name: 'Painting', image: 'Painting.png' },
  { name: 'Plumbing', image: 'Plumbing.jfif' },
  { name: 'Electrical Work', image: 'Electrical Work.jpg' },
  { name: 'AC Service & Repair', image: 'AC Service & Repair.jpg' },
  { name: 'Water Proofing', image: 'waterproofing-services.png' },
  { name: 'Civil Work', image: 'Civil Work.jpg' },
  { name: 'Aluminium & Windows', image: 'Aluminium & Windows.jfif' },
  { name: 'CCTV Installation', image: 'CCTV Installation.jpg' },
]

export function CategoryGrid() {
  return (
    <div className="category-grid">
      {categories.map(({ name, image }) => (
        <Link
          key={name}
          to={`/?browse=1&search=${encodeURIComponent(name)}`}
          className="category-tile"
        >
          <img
            className="category-image"
            src={encodeURI(`/categories Images/${image}`)}
            alt={name}
            width={80}
            height={72}
          />
          <span className="category-arrow" aria-hidden="true">&rsaquo;</span>
          <h3>{name}</h3>
          <small>Explore leads</small>
        </Link>
      ))}
    </div>
  )
}


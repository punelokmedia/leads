import { Link } from 'react-router-dom'
import type { ComponentProps } from 'react'
import { useCategoryCatalog } from './useCategoryCatalog'
import { resolveCategory, categoryLeadUrl } from './category-resolution'
export function CategoryLink({ name, children, ...props }: { name: string } & Omit<ComponentProps<typeof Link>, 'to'>) {
  const { items, loading, error } = useCategoryCatalog()
  const category = resolveCategory(name, items)
  if (!category) return <span className={props.className} aria-disabled="true" title={loading ? 'Loading category…' : error || 'This category is currently unavailable.'}>{children || name}</span>
  return <Link {...props} to={categoryLeadUrl(category._id)}>{children || name}</Link>
}

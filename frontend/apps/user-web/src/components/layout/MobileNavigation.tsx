import { useCallback, useEffect, useId, useRef, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import './mobile-navigation.css'

export function MobileNavigation({ children, cartCount = 0, searchable = true }: {
  children: ReactNode; cartCount?: number; searchable?: boolean
}) {
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState('')
  const dialog = useRef<HTMLDialogElement>(null)
  const trigger = useRef<HTMLButtonElement>(null)
  const searchInput = useRef<HTMLInputElement>(null)
  const focusSearch = useRef(false)
  const navigate = useNavigate()
  const id = useId()
  const close = useCallback(() => setOpen(false), [])

  useEffect(() => {
    const element = dialog.current
    if (!open || !element) return
    const previousOverflow = document.body.style.overflow
    const opener = trigger.current
    document.body.style.overflow = 'hidden'
    element.showModal()
    if (focusSearch.current) searchInput.current?.focus({ preventScroll: true })
    const desktop = window.matchMedia('(min-width: 1025px)')
    const resize = () => { if (desktop.matches) close() }
    desktop.addEventListener('change', resize)
    return () => {
      desktop.removeEventListener('change', resize)
      element.close()
      document.body.style.overflow = previousOverflow
      opener?.focus({ preventScroll: true })
    }
  }, [open, close])

  return <div className="mobile-nav-controls">
    {searchable && <button className="mobile-nav-search-toggle" type="button" aria-label="Open search" onClick={() => { focusSearch.current = true; setOpen(true) }}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/></svg></button>}
    <button ref={trigger} className="mobile-nav-toggle" type="button" aria-label="Open navigation" aria-haspopup="dialog" aria-expanded={open} aria-controls={id} onClick={() => { focusSearch.current = false; setOpen(true) }}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"/></svg>{cartCount > 0 && <span className="mobile-nav-count" aria-label={`${cartCount} cart items`}>{cartCount > 99 ? '99+' : cartCount}</span>}</button>
    <dialog ref={dialog} id={id} className="mobile-nav-dialog" aria-labelledby={`${id}-title`} onCancel={close} onClose={close} onKeyDown={event => {
      if (event.key !== 'Tab') return
      const controls = [...event.currentTarget.querySelectorAll<HTMLElement>('a[href],button:not(:disabled),input:not(:disabled)')]
      const first = controls[0]
      const last = controls[controls.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last?.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first?.focus()
      }
    }} onClick={event => {
      if (event.target !== event.currentTarget) return
      const box = event.currentTarget.getBoundingClientRect()
      if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) close()
    }}>
      <div className="mobile-nav-heading"><h2 id={`${id}-title`}>Menu</h2><button type="button" autoFocus aria-label="Close navigation" onClick={close}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></div>
      {searchable && <form className="mobile-nav-search" role="search" onSubmit={event => { event.preventDefault(); close(); navigate(`/?browse=1&search=${encodeURIComponent(search.trim())}`) }}><input ref={searchInput} type="search" aria-label="Search leads" placeholder="Search leads or city" value={search} onChange={event => setSearch(event.target.value)} /><button type="submit" aria-label="Submit search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/></svg></button></form>}
      <nav className="mobile-nav-links" aria-label="Mobile navigation" onClick={event => { if (event.target instanceof Element && event.target.closest('a,button')) close() }}>{children}</nav>
    </dialog>
  </div>
}

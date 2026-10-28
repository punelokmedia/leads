import { useEffect, useState, type CSSProperties } from 'react'
import './loading.css'

export function Skeleton({ className = '', style }: { className?: string; style?: CSSProperties }) {
  return <span aria-hidden="true" className={`skeleton ${className}`} style={style} />
}

export function CardSkeletons({ count = 6 }: { count?: number }) {
  return <div className="lead-results-grid" role="status" aria-label="Loading leads" aria-busy="true">
    {Array.from({ length: count }, (_, index) => <div className="market-lead-card skeleton-card" aria-hidden="true" key={index}>
      <Skeleton className="skeleton-card-image" />
      <div className="market-lead-body"><Skeleton style={{ width: '75%', height: 20 }} /><Skeleton style={{ width: '40%' }} /><Skeleton /><Skeleton style={{ width: '65%' }} /><Skeleton style={{ width: '55%' }} /><div className="skeleton-actions"><Skeleton /><Skeleton /><Skeleton /></div></div>
    </div>)}
  </div>
}

export function RowsSkeleton({ count = 4 }: { count?: number }) {
  return <div className="skeleton-rows" role="status" aria-label="Loading activity" aria-busy="true">{Array.from({ length: count }, (_, index) => <div className="skeleton-row" key={index}><Skeleton /><Skeleton /><Skeleton /></div>)}</div>
}

export function PageSkeleton({ home = false }: { home?: boolean }) {
  const path = window.location.pathname
  if (!home && path !== '/' && path !== '/categories') return <section className="page-skeleton skeleton-account" role="status" aria-label="Loading page" aria-busy="true">
    <Skeleton className="skeleton-heading" />
    {path === '/referrals' ? <><div className="skeleton-hero"><div className="skeleton-copy"><Skeleton className="skeleton-heading" /><Skeleton /><Skeleton style={{ height: 100 }} /></div><Skeleton className="skeleton-art" /></div><div className="skeleton-stat-grid">{[0, 1, 2].map(i => <Skeleton key={i} style={{ height: 100 }} />)}</div><RowsSkeleton /></>
      : path === '/wallet' ? <><Skeleton className="skeleton-balance" /><RowsSkeleton count={5} /></>
      : <div className="skeleton-account-grid"><div className="skeleton-account-panel"><Skeleton style={{ height: 100 }} /><RowsSkeleton count={3} /></div><div className="skeleton-account-panel"><RowsSkeleton count={6} /><Skeleton style={{ width: 150, height: 42 }} /></div></div>}
  </section>
  if (!home && path === '/') return <section className="page-skeleton skeleton-marketplace" role="status" aria-label="Loading leads" aria-busy="true"><div className="skeleton-filter-panel"><RowsSkeleton count={8} /></div><div><Skeleton style={{ height: 120, marginBottom: 28 }} /><Skeleton className="skeleton-heading" /><CardSkeletons /></div></section>
  return <div className={`page-skeleton ${home ? 'page-skeleton-home' : ''}`} role="status" aria-label="Loading page" aria-busy="true">
    <div className="skeleton-hero"><div className="skeleton-copy"><Skeleton className="skeleton-heading" /><Skeleton className="skeleton-heading" /><Skeleton style={{ width: '80%' }} /><Skeleton style={{ width: '60%' }} /><div className="skeleton-actions"><Skeleton /><Skeleton /></div></div><Skeleton className="skeleton-art" /></div>
    <div className="skeleton-section"><div className="skeleton-section-heading"><Skeleton style={{ width: 110, height: 12 }} /><Skeleton style={{ width: 'min(420px, 90%)', height: 40 }} /><Skeleton style={{ width: 'min(540px, 95%)', height: 18 }} /></div><div className="skeleton-tiles">{Array.from({ length: 10 }, (_, i) => <Skeleton key={i} />)}</div></div>
  </div>
}

export function InitialLoading() {
  const [slow, setSlow] = useState(false)
  useEffect(() => { const timer = setTimeout(() => setSlow(true), 20000); return () => clearTimeout(timer) }, [])
  return <><div className="skeleton-navbar" aria-hidden="true"><Skeleton style={{ width: 170, height: 44 }} /><div className="skeleton-actions"><Skeleton /><Skeleton /><Skeleton /></div></div>{slow ? <section className="loading-error" role="alert"><p>Taking longer than expected. Check your connection and try again.</p><button onClick={() => window.location.reload()}>Retry</button></section> : <PageSkeleton home={window.location.pathname === '/' && !window.location.search} />}</>
}

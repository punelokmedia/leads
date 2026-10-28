import { useEffect, useRef, useState, type ImgHTMLAttributes } from 'react'
import './loading.css'

type Props = ImgHTMLAttributes<HTMLImageElement>

// Key the inner component so a changed URL never reveals the previous image.
export function LoadingImage(props: Props) {
  return <ImageContent key={props.src} {...props} />
}

function ImageContent({ className = '', style, alt = '', width, height, onLoad, onError, ...props }: Props) {
  const image = useRef<HTMLImageElement>(null)
  const [state, setState] = useState<'loading' | 'ready' | 'error'>('loading')
  useEffect(() => {
    const element = image.current
    if (!element) return
    let cancelled = false
    let timer: ReturnType<typeof setTimeout> | undefined
    const ready = () => {
      void (element.decode?.() ?? Promise.resolve()).catch(() => {}).then(() => {
        if (!cancelled) { clearTimeout(timer); setState(element.naturalWidth ? 'ready' : 'error') }
      })
    }
    const start = () => { if (!element.complete) timer ??= setTimeout(() => { if (!cancelled) setState('error') }, 45000) }
    element.addEventListener('load', ready)
    if (element.complete && element.naturalWidth) ready()
    // Lazy images only start their failure timeout when near the viewport.
    const observer = props.loading === 'lazy' && typeof IntersectionObserver !== 'undefined'
      ? new IntersectionObserver(entries => { if (entries.some(entry => entry.isIntersecting)) { start(); observer?.disconnect() } }, { rootMargin: '300px' }) : null
    if (observer) observer.observe(element)
    else start()
    return () => { cancelled = true; clearTimeout(timer); observer?.disconnect(); element.removeEventListener('load', ready) }
  }, [props.loading])
  return <span className={`loading-image ${className}`} data-state={state} style={{ aspectRatio: width && height ? `${width}/${height}` : undefined, ...style }}>
    <img {...props} ref={image} alt={state === 'error' ? '' : alt} width={width} height={height} decoding="async" onLoad={onLoad} onError={event => { setState('error'); onError?.(event) }} />
    {state === 'error' && <span className="loading-image-fallback" role={alt ? 'img' : undefined} aria-label={alt || undefined}>{alt ? 'Image unavailable' : ''}</span>}
  </span>
}

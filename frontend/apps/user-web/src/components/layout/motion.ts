// Keep transitions brief, and leave browser/payment navigation unblocked.
export function animateWindowClose(element: HTMLElement | null, onClosed: () => void) {
  if (!element?.animate || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    onClosed()
    return
  }
  if (element.dataset.closing === 'true') return
  element.dataset.closing = 'true'
  const animation = element.animate(
    [{ opacity: 1, transform: 'translateY(0) scale(1)' }, { opacity: 0, transform: 'translateY(5px) scale(.985)' }],
    { duration: 220, easing: 'ease-in', fill: 'forwards' },
  )
  void animation.finished.then(onClosed, onClosed)
}

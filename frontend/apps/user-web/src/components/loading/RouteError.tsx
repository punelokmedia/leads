import { isRouteErrorResponse, useRouteError } from 'react-router-dom'

export function RouteError() {
  const error = useRouteError()
  const missing = isRouteErrorResponse(error) && error.status === 404
  return <RouteLoadFailure missing={missing} />
}

export function RouteLoadFailure({ missing = false }: { missing?: boolean }) {
  return <section className="loading-error" role="alert"><h1>{missing ? 'Page not found' : 'Unable to load this page'}</h1><p>{missing ? 'Check the address or return home.' : 'Check your connection and try again.'}</p><button onClick={() => window.location.reload()}>Retry</button><a href="/">Back to home</a></section>
}

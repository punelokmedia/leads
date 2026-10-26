export function requiresLogin(pathname: string, search: string) {
  if (pathname === '/') {
    const params = new URLSearchParams(search)
    return ['browse','category','city','search'].some(key => params.has(key))
  }
  return ['/categories','/profile','/wallet','/referrals','/cart','/my-leads','/history','/membership','/leads'].some(path => pathname === path || pathname.startsWith(path + '/'))
}
export function safeReturnPath(value: string | null) {
  if (!value || !value.startsWith('/') || value.startsWith('//') || value.includes('\\') || Array.from(value).some(character => character.charCodeAt(0) <= 32)) return null
  const url = new URL(value, 'https://nextlead.invalid')
  return url.origin === 'https://nextlead.invalid' && requiresLogin(url.pathname, url.search) ? url.pathname + url.search : null
}

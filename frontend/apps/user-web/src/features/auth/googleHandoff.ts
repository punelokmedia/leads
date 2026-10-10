export async function startGoogleLogin(url: string) {
  const bytes = crypto.getRandomValues(new Uint8Array(32))
  const verifier = Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('')
  sessionStorage.setItem('google_verifier', verifier)
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier))
  const challenge = btoa(String.fromCharCode(...new Uint8Array(digest))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const target = new URL(url)
  target.searchParams.set('challenge', challenge)
  window.location.href = target.toString()
}

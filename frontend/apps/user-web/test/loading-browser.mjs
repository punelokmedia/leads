// Run against a production preview and headless Chrome with remote debugging enabled.
// node test/loading-browser.mjs desktop fast (or mobile, tablet / 4g, slow)
import assert from 'node:assert/strict'
import { mkdir, writeFile } from 'node:fs/promises'

const device = process.argv[2] || 'desktop'
const speed = process.argv[3] || 'fast'
const base = process.env.LOADING_TEST_URL || 'http://localhost:3000'
const debug = process.env.CHROME_DEBUG_URL || 'http://localhost:9223'
// This dedicated browser profile must not retain earlier fixture tabs.
const previousTabs = await (await fetch(`${debug}/json/list`)).json()
for (const previous of previousTabs.filter(tab => tab.url.startsWith(base))) await fetch(`${debug}/json/close/${previous.id}`)
const tab = await (await fetch(`${debug}/json/new?about:blank`, { method: 'PUT' })).json()
const socket = new WebSocket(tab.webSocketDebuggerUrl)
await new Promise(resolve => socket.addEventListener('open', resolve, { once: true }))
let id = 0
const pending = new Map()
const events = new Map()
socket.addEventListener('message', event => {
  const message = JSON.parse(event.data)
  if (message.id) {
    const entry = pending.get(message.id)
    if (!entry) return
    pending.delete(message.id)
    if (message.error) entry.reject(new Error(message.error.message))
    else entry.resolve(message.result)
  } else for (const listener of events.get(message.method) || []) listener(message.params)
})
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const key = ++id; pending.set(key, { resolve, reject }); socket.send(JSON.stringify({ id: key, method, params })) })
}
function on(event, listener) { events.set(event, [...(events.get(event) || []), listener]) }
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text)
  return result.result.value
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))
async function until(expression, timeout = 60000) {
  const start = Date.now()
  while (Date.now() - start < timeout) { if (await evaluate(expression)) return; await pause(100) }
  throw new Error(`Timed out: ${expression}`)
}
const exceptions = []
on('Runtime.exceptionThrown', value => exceptions.push(value.exceptionDetails.text))
let holdEntry = true
let holdRoute = false
let failImages = false
let failLeads = false
let authenticatedFixtures = false
let failRoute = false
let failEntry = false
const apiCounts = new Map()
on('Fetch.requestPaused', async ({ requestId, request }) => {
  try {
    if ((holdEntry && /\/assets\/index-.*\.js/.test(request.url)) || (holdRoute && /\/assets\/CategoriesPage-.*\.js/.test(request.url))) await pause(1800)
    if ((failImages && /optimized\/home\/hero|NextLead%20Vendor%20App%20Promotion|optimized\/categories/.test(request.url)) || (failLeads && request.url.includes('/leads/get-all-leads')) || (failRoute && /\/assets\/ContactPage-.*\.js/.test(request.url)) || (failEntry && /\/assets\/index-.*\.js/.test(request.url))) {
      await send('Fetch.failRequest', { requestId, errorReason: 'Failed' })
    } else if (request.url.includes('/api/v1/') && (authenticatedFixtures || /\/categories\/|\/cities\//.test(request.url))) {
      const path = new URL(request.url).pathname
      if (request.method === 'GET') apiCounts.set(path, (apiCounts.get(path) || 0) + 1)
      if (request.method === 'GET' && /\/referrals\/|\/wallet$|\/auth\/profile/.test(path)) await pause(path.endsWith('/history') ? 1800 : 900)
      let payload = request.url.includes('/leads/get-all-leads')
        ? { success: true, data: [{ _id: 'loading-test-lead', title: 'Test project', city: 'Pune', state: 'Maharashtra', price: 50, buyersCount: 0, maxBuyers: 2, createdAt: '2026-01-01T00:00:00Z', status: 'ACTIVE' }], pagination: { page: 1, totalPages: 1 } }
        : { success: true, data: [], summary: { totalItems: 0, totalAmount: 0 } }
      if (path.endsWith('/wallet')) payload = { success: true, data: { balancePaise: 10000, referralCreditPaise: 5000, entries: [], nextCursor: null } }
      if (path.endsWith('/referrals/me')) payload = { success: true, data: { referralCode: 'TEST1234', referralLink: 'https://example.com/?ref=TEST1234', invited: 1, qualified: 1, pending: 0 } }
      if (path.endsWith('/referrals/history')) payload = { success: true, data: [], pagination: { total: 0 } }
      if (path.endsWith('/auth/profile')) payload = { success: true, data: { firstname: 'Test', lastname: 'User', phoneNumber: '', email: '', address: {} } }
      if (path.endsWith('/leads/filter-options')) payload = { success: true, data: { projectTypes: [], propertyTypes: [] } }
      if (path.endsWith('/categories/get-all-categories')) payload = { success: true, data: ['POP & False Ceiling Work','Interior Design','Painting','Plumbing','AC Service & Repair','Water Proofing','Civil Work','Aluminium & Windows','Electrical Work','CCTV Installation'].map((name, index) => ({ _id: String(index + 1).padStart(24, '0'), name })) }
      if (path.endsWith('/cities/get-all-cities')) payload = { success: true, data: [{ _id: '1', name: 'Pune' }] }
      await send('Fetch.fulfillRequest', { requestId, responseCode: 200, responseHeaders: [{ name: 'Content-Type', value: 'application/json' }, { name: 'Access-Control-Allow-Origin', value: base }, { name: 'Access-Control-Allow-Headers', value: 'authorization,x-web-session,content-type' }, { name: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS' }], body: Buffer.from(JSON.stringify(payload)).toString('base64') })
    } else await send('Fetch.continueRequest', { requestId })
  } catch { /* Target may close with noncritical requests in flight. */ }
})
try {
  await send('Page.enable')
  await send('Runtime.enable')
  await send('Network.enable')
  await send('Network.setCacheDisabled', { cacheDisabled: true })
  await send('Storage.clearDataForOrigin', { origin: base, storageTypes: 'local_storage' })
  await send('Emulation.setDeviceMetricsOverride', { width: device === 'mobile' ? 390 : device === 'tablet' ? 820 : 1440, height: device === 'mobile' ? 844 : device === 'tablet' ? 1180 : 1000, deviceScaleFactor: 1, mobile: device !== 'desktop' })
  const rates = speed === 'slow' ? { latency: 400, downloadThroughput: 100000, uploadThroughput: 50000 } : speed === '4g' ? { latency: 150, downloadThroughput: 500000, uploadThroughput: 200000 } : { latency: 0, downloadThroughput: -1, uploadThroughput: -1 }
  await send('Network.emulateNetworkConditions', { offline: false, ...rates })
  await send('Fetch.enable', { patterns: [{ urlPattern: '*' }] })
  await send('Page.addScriptToEvaluateOnNewDocument', { source: `window.loadingCLS = 0; new PerformanceObserver(list => { for (const entry of list.getEntries()) if (!entry.hadRecentInput) window.loadingCLS += entry.value }).observe({type:'layout-shift', buffered:true});` })
  await send('Page.navigate', { url: base })
  await until(`!!document.querySelector('.boot-shell')`)
  assert(await evaluate(`document.querySelector('.boot-hero').getBoundingClientRect().height > 300`), 'HTML shell must paint before JS')
  await until(`!!document.querySelector('.home-site-header')`)
  holdEntry = false
  await until(`document.querySelector('.hero-art')?.dataset.state === 'ready' || document.querySelector('.hero-art')?.dataset.state === 'error'`)
  const imageState = await evaluate(`document.querySelector('.hero-art').dataset.state`)
  assert.equal(imageState, 'ready', 'Hero image should decode on the selected connection')
  assert(await evaluate(`!document.querySelector('.next-home').hidden && !document.querySelector('.hero-art.loading-image') && !document.querySelector('.page-skeleton-home')`), 'Homepage must reveal with a decoded hero and no image cover')
  assert(await evaluate(`Math.abs(document.querySelector('.hero-art').getBoundingClientRect().bottom - document.querySelector('.hero-inner').getBoundingClientRect().bottom) < 1`), 'Hero artwork must stay anchored to the bottom of the banner')
  assert(await evaluate(`document.documentElement.scrollWidth <= innerWidth + 1`), 'No horizontal overflow')
  assert(await evaluate(`Array.from(document.querySelectorAll('.category-grid > .category-tile')).every(tile => tile.getBoundingClientRect().right <= tile.parentElement.getBoundingClientRect().right + 1)`), 'Cards must fit within their grid, including on tablets')
  assert.equal(await evaluate(`!!document.querySelector('.boot-shell')`), false)
  await until(`document.querySelectorAll('a.category-tile').length >= 9`)
  await mkdir('.tmp/loading-checks', { recursive: true })
  const screenshot = await send('Page.captureScreenshot', { format: 'png' })
  await writeFile(`.tmp/loading-checks/${device}-${speed}.png`, Buffer.from(screenshot.data, 'base64'))
  const cls = await evaluate('window.loadingCLS')
  assert(cls < 0.05, `Loading layout shift must stay small (observed ${cls})`)
  holdRoute = true
  await evaluate(`window.savedHeader = document.querySelector('.home-site-header'); document.querySelector('a[href="/categories"]').click()`)
  await until(`!!document.querySelector('.navigation-progress')`)
  assert(await evaluate(`window.savedHeader === document.querySelector('.home-site-header') && !!document.querySelector('.home-hero')`), 'Navigation must retain the current page and navbar')
  await until(`location.pathname === '/categories' && !document.querySelector('.navigation-progress')`)
  holdRoute = false
  assert(await evaluate(`window.savedHeader === document.querySelector('.home-site-header')`), 'Navbar must not remount')
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] })
  assert.equal(await evaluate(`(() => { const el=document.createElement('span'); el.className='skeleton'; document.body.append(el); const value=getComputedStyle(el,'::after').animationName; el.remove(); return value })()`), 'none')
  // Failure tests run unthrottled to isolate fallback behavior from transfer time.
  await send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 })
  failImages = true
  await send('Page.navigate', { url: base })
  await until(`document.querySelector('.hero-art')?.dataset.state === 'error'`)
  assert(await evaluate(`!!document.querySelector('.hero-image-retry') && !document.querySelector('.next-home').hidden && !document.querySelector('.hero-art.loading-image')`), 'Image failures must retain usable content without a grey cover')
  failLeads = true
  authenticatedFixtures = true
  await evaluate(`localStorage.setItem('user_token', 'loading-browser-fixture')`)
  await send('Page.navigate', { url: `${base}/?browse=1` })
  await until(`Array.from(document.querySelectorAll('button')).some(el => el.textContent === 'Retry')`)
  assert.equal(await evaluate(`document.querySelectorAll('.skeleton-card').length`), 0, 'Failed API must leave its skeleton')
  failLeads = false
  await evaluate(`Array.from(document.querySelectorAll('button')).find(el => el.textContent === 'Retry').click()`)
  await until(`!document.querySelector('.skeleton-card') && !Array.from(document.querySelectorAll('button')).some(el => el.textContent === 'Retry')`)
  await until(`!!document.querySelector('.market-lead-card:not(.skeleton-card)')`)
  await send('Page.navigate', { url: `${base}/referrals` })
  await until(`!!document.querySelector('.referral-history .skeleton-rows')`)
  await until(`document.querySelector('#referral-code')?.value === 'TEST1234' && !document.querySelector('.referral-history .skeleton-rows')`)
  const summaryRequests = apiCounts.get('/api/v1/referrals/me')
  await evaluate(`Array.from(document.querySelectorAll('.referral-tabs button')).find(el => el.textContent === 'Pending').click()`)
  await until(`!!document.querySelector('.referral-history .skeleton-rows')`)
  assert.equal(await evaluate(`document.querySelector('#referral-code').value`), 'TEST1234', 'History filters must retain the summary')
  await until(`!document.querySelector('.referral-history .skeleton-rows')`)
  assert.equal(apiCounts.get('/api/v1/referrals/me'), summaryRequests, 'History filters must not reload the summary')
  await send('Page.navigate', { url: `${base}/wallet` })
  await until(`!!document.querySelector('.wallet-balance .skeleton')`)
  await until(`!!document.querySelector('.wallet-balance .content-reveal') && !document.querySelector('.wallet-page .skeleton-rows')`)
  assert.deepEqual(exceptions, [], 'No runtime exceptions')
  failRoute = true
  await evaluate(`window.savedHeader = document.querySelector('.marketplace-header'); document.querySelector('a[href="/contact"]').click()`)
  await until(`!!document.querySelector('main .loading-error')`)
  assert(await evaluate(`window.savedHeader === document.querySelector('.marketplace-header')`), 'Route errors must keep the navbar')
  failEntry = true
  await send('Page.navigate', { url: base })
  await until(`!!document.querySelector('.boot-failed .boot-help:not([hidden])')`)
  assert.equal(await evaluate(`document.querySelector('.boot-shell').getAttribute('aria-busy')`), 'false', 'Entry failure must provide a usable fallback')
  console.log(JSON.stringify({ device, speed, cls, checks: ['initial HTML shell', 'decoded hero', 'responsive layout', 'retained navigation', 'reduced motion', 'image fallback', 'API failure and retry', 'independent referral loading', 'wallet loading'], screenshot: `.tmp/loading-checks/${device}-${speed}.png` }))
} finally {
  await evaluate(`localStorage.removeItem('user_token'); localStorage.removeItem('has_signed_in')`).catch(() => {})
  await send('Page.close').catch(() => {})
  socket.close()
}

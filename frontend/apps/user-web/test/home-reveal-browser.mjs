// Use the dedicated headless Chrome profile described in LOADING.md.
import assert from 'node:assert/strict'
import { mkdir, writeFile } from 'node:fs/promises'

const base = process.env.LOADING_TEST_URL || 'http://localhost:5174'
const debug = process.env.CHROME_DEBUG_URL || 'http://localhost:9223'
const tab = await (await fetch(`${debug}/json/new?about:blank`, { method: 'PUT' })).json()
const socket = new WebSocket(tab.webSocketDebuggerUrl)
await new Promise(resolve => socket.addEventListener('open', resolve, { once: true }))
let sequence = 0
const pending = new Map()
let mode = 'hold'
let held = []
socket.addEventListener('message', async event => {
  const message = JSON.parse(event.data)
  if (message.id) {
    const callbacks = pending.get(message.id)
    pending.delete(message.id)
    if (message.error) callbacks.reject(new Error(message.error.message))
    else callbacks.resolve(message.result)
  } else if (message.method === 'Fetch.requestPaused') {
    const { requestId, request } = message.params
    const optimized = request.url.includes('/optimized/home/hero.webp')
    const hero = optimized || request.url.includes('NextLead%20Vendor%20App%20Promotion.png')
    try {
      if (hero && mode === 'hold') held.push(requestId)
      else if (hero && (mode === 'fail-all' || (mode === 'fail-webp' && optimized))) await send('Fetch.failRequest', { requestId, errorReason: 'Failed' })
      else await send('Fetch.continueRequest', { requestId })
    } catch { /* Requests may be cancelled when the test navigates. */ }
  }
})
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const id = ++sequence; pending.set(id, { resolve, reject }); socket.send(JSON.stringify({ id, method, params })) })
}
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text)
  return result.result.value
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))
async function until(expression) {
  for (let i = 0; i < 200; i++) { if (await evaluate(expression)) return; await pause(100) }
  throw new Error(`Timed out: ${expression}`)
}
const ready = `document.querySelector('.hero-art')?.dataset.state === 'ready' && !document.querySelector('.next-home').hidden`
try {
  await send('Page.enable')
  await send('Network.enable')
  await send('Network.setCacheDisabled', { cacheDisabled: true })
  await send('Storage.clearDataForOrigin', { origin: base, storageTypes: 'local_storage' })
  await send('Fetch.enable', { patterns: [{ urlPattern: '*' }] })
  for (const width of [1458, 390]) {
    mode = 'hold'
    held = []
    await send('Emulation.setDeviceMetricsOverride', { width, height: 1000, deviceScaleFactor: 1, mobile: width < 700 })
    await send('Page.navigate', { url: base })
    await until(`document.querySelector('.next-home')?.hidden && !!document.querySelector('.page-skeleton-home')`)
    await pause(250)
    assert(await evaluate(`document.querySelector('.next-home').hidden`), 'Keep the page skeleton while the hero request is held')
    assert(await evaluate(`!document.querySelector('.hero-art.loading-image')`), 'Never put a grey loading cover on the hero')
    assert(held.length > 0, 'Hero request must actually be held')
    mode = 'pass'
    for (const requestId of held) await send('Fetch.continueRequest', { requestId })
    await until(ready)
    assert(await evaluate(`!document.querySelector('.page-skeleton-home') && document.querySelector('.hero-art').naturalWidth > 0`), 'Reveal only the decoded image and remove the page skeleton')
    assert(await evaluate(`Math.abs(document.querySelector('.hero-art').getBoundingClientRect().bottom - document.querySelector('.hero-inner').getBoundingClientRect().bottom) < 1`), 'Keep artwork bottom-aligned')
    await pause(350)
    await mkdir('.tmp/home-reveal', { recursive: true })
    const screenshot = await send('Page.captureScreenshot', { format: 'png' })
    await writeFile(`.tmp/home-reveal/${width}.png`, Buffer.from(screenshot.data, 'base64'))
    console.log(`PASS ${width}px: skeleton remains until hero decode, then homepage appears without a cover`)
  }
  mode = 'fail-webp'
  await send('Page.navigate', { url: base })
  await until(ready)
  assert(await evaluate(`document.querySelector('.hero-art').getAttribute('src') === '/NextLead Vendor App Promotion.png'`), 'Use original artwork if optimized asset fails')
  mode = 'fail-all'
  await send('Page.navigate', { url: base })
  await until(`!!document.querySelector('.hero-image-retry') && !document.querySelector('.next-home').hidden`)
  assert(await evaluate(`!document.querySelector('.page-skeleton-home') && getComputedStyle(document.querySelector('.hero-art')).visibility === 'hidden'`), 'Failed images must not leave a skeleton or broken image icon')
  mode = 'pass'
  await evaluate(`document.querySelector('.hero-image-retry').click()`)
  await until(ready)
  console.log('PASS image failure: original artwork fallback, usable homepage, and retry recovery')
} finally {
  await send('Page.close')
  socket.close()
}

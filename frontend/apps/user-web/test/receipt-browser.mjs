// Dedicated headless Chrome only; see test/LOADING.md. All API traffic is intercepted.
import assert from 'node:assert/strict'
import { mkdir } from 'node:fs/promises'
import { resolve } from 'node:path'
import { renderReceipt } from '../../../../backend/src/Services/payment-receipt.js'

const base = process.env.RECEIPT_TEST_URL || 'http://127.0.0.1:5175'
const debug = process.env.CHROME_DEBUG_URL || 'http://127.0.0.1:9223'
const id = '6afc2ed89f753e5508ff76b2'
const pdf = await renderReceipt({ receiptNumber: `NL-${id}`, orderId: id, amount: 499, paidAt: '2026-11-17T10:39:21.762Z', paymentMethod: 'NextLead Wallet', items: [{ title: 'Service enquiry', category: 'Service category', location: 'Pune', price: 499, quantity: 1 }] })
const tab = await (await fetch(`${debug}/json/new?about:blank`, { method: 'PUT' })).json()
const socket = new WebSocket(tab.webSocketDebuggerUrl)
await new Promise(resolve => socket.addEventListener('open', resolve, { once: true }))
let sequence = 0, status = 'PAID', receiptFails = false
const pending = new Map(), downloads = [], completed = new Set(), receiptRequests = []
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const id = ++sequence; pending.set(id, { resolve, reject }); socket.send(JSON.stringify({ id, method, params })) })
}
socket.addEventListener('message', async event => {
  const message = JSON.parse(event.data)
  if (message.id) {
    const callback = pending.get(message.id); pending.delete(message.id)
    if (message.error) callback.reject(new Error(message.error.message)); else callback.resolve(message.result)
  } else if (message.method === 'Browser.downloadWillBegin') downloads.push(message.params)
  else if (message.method === 'Browser.downloadProgress' && message.params.state === 'completed') completed.add(message.params.guid)
  else if (message.method === 'Fetch.requestPaused') {
    const { requestId, request } = message.params
    const headers = [{ name: 'Access-Control-Allow-Origin', value: base }, { name: 'Access-Control-Allow-Headers', value: '*' }, { name: 'Access-Control-Allow-Methods', value: '*' }]
    const path = new URL(request.url).pathname
    let data = {}, code = 200, isPdf = false
    if (request.method !== 'OPTIONS') {
      if (path.includes('/receipt/')) {
        receiptRequests.push(request)
        isPdf = !receiptFails
        if (receiptFails) { code = 409; data = { success: false, message: 'Payment not confirmed. Please retry.' } }
      } else if (path.endsWith('/history')) data = { success: true, data: [{ orderId: id, status, paidAt: '2026-11-17T10:39:21.762Z', totalAmount: 499, paymentMethod: 'NextLead Wallet', items: [{ leadId: id, title: 'Service enquiry', city: 'Pune', price: 499, quantity: 1, total: 499 }] }] }
      else if (path.endsWith('/profile')) data = { success: true, data: { firstname: 'Test', registrationFeePaid: true } }
      else data = { success: true, data: [], pagination: { totalPages: 0 } }
    }
    headers.push({ name: 'Content-Type', value: isPdf ? 'application/pdf' : 'application/json' })
    await send('Fetch.fulfillRequest', { requestId, responseCode: code, responseHeaders: headers, body: (isPdf ? pdf : Buffer.from(JSON.stringify(data))).toString('base64') }).catch(error => {
      if (!error.message.includes('Invalid InterceptionId')) throw error
    })
  }
})
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails))
  return result.result.value
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))
async function until(check) { for (let i = 0; i < 150; i++) { if (await check()) return; await pause(100) } throw new Error('Browser assertion timed out') }
const clickReceipt = `Array.from(document.querySelectorAll('button')).find(el=>el.textContent==='Download Receipt')?.click()`
try {
  await send('Page.enable'); await send('Runtime.enable')
  await send('Fetch.enable', { patterns: [{ urlPattern: '*/api/v1/*' }] })
  await mkdir(resolve('.tmp/receipt-downloads'), { recursive: true })
  await send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: resolve('.tmp/receipt-downloads'), eventsEnabled: true })
  await send('Page.addScriptToEvaluateOnNewDocument', { source: "localStorage.setItem('user_token','receipt-browser-fixture'); localStorage.setItem('has_signed_in','1')" })
  for (const width of [1440, 390]) {
    await send('Emulation.setDeviceMetricsOverride', { width, height: 900, deviceScaleFactor: 1, mobile: width < 500 })
    await send('Page.navigate', { url: `${base}/payment/success/${id}` })
    await until(() => evaluate(`document.body.innerText.includes('Payment successful') && [...document.querySelectorAll('button')].some(el=>el.textContent==='Download Receipt')`))
    assert.equal(await evaluate('document.documentElement.scrollWidth <= innerWidth + 1'), true)
    await evaluate(clickReceipt)
    await until(() => Promise.resolve(downloads.length === (width === 1440 ? 1 : 2) && completed.size === downloads.length))
    assert.equal(downloads.at(-1).suggestedFilename, `NextLead_Receipt_${id}.pdf`)
    assert.equal(Object.entries(receiptRequests.at(-1).headers).find(([name]) => name.toLowerCase() === 'authorization')?.[1], 'Bearer receipt-browser-fixture')
    console.log(`${width}px: authenticated PDF download completed`)
  }
  receiptFails = true
  await until(() => evaluate(`[...document.querySelectorAll('button')].some(el=>el.textContent==='Download Receipt' && !el.disabled)`))
  await evaluate(clickReceipt)
  await until(() => evaluate(`document.body.innerText.includes('Payment not confirmed. Please retry.')`))
  assert.equal(downloads.length, 2)
  status = 'FAILED'
  await send('Page.navigate', { url: `${base}/orders/${id}` })
  await until(() => evaluate(`document.body.innerText.includes('Status: FAILED')`))
  assert.equal(await evaluate(`[...document.querySelectorAll('button')].some(el=>el.textContent==='Download Receipt')`), false)
  console.log('Failed download shows retry message; unpaid order hides receipt button')
} finally {
  await send('Fetch.disable').catch(() => {})
  await fetch(`${debug}/json/close/${tab.id}`).catch(() => {})
  socket.close()
}

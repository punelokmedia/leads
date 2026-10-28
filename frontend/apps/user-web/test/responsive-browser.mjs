// Production preview + dedicated Chrome debugging profile (see RESPONSIVE.md).
import assert from 'node:assert/strict'
import { mkdir, writeFile } from 'node:fs/promises'

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
const lead = { _id: '123456789012345678901234', title: 'Complete apartment painting and waterproofing', city: 'Pune', state: 'Maharashtra', price: 50, originalPrice: 100, buyersCount: 0, maxBuyers: 2, createdAt: '2026-01-01T00:00:00Z', status: 'ACTIVE', category: { name: 'Painting' }, customerName: 'Test Customer', quantity: 1, budgetRange: '₹50,000 – ₹1,00,000', description: 'Interior painting and waterproofing for a residential apartment.', primaryPhone: '9999999999', propertyType: 'Residential', timeline: 'Within a month' }
on('Fetch.requestPaused', async ({requestId, request}) => {
  try {
    if (!request.url.includes('/api/v1/')) { await send('Fetch.continueRequest', {requestId}); return }
    const path = new URL(request.url).pathname
    let data = []
    if (path.endsWith('/auth/profile')) data = { firstname:'Test', lastname:'User', email:'test@example.com', phoneNumber:'9999999999', address:{city:'Pune'}, registrationFeePaid:true, registrationFeePaidAt:'2026-01-01T00:00:00Z', businessName:'Test Business' }
    if (path.endsWith('/get-all-categories')) data = ['Painting','Civil Work','Water Proofing','POP','Interior Design','Plumbing'].map((name,i)=>({_id:String(i+1).padStart(24,'0'),name,displayName:name}))
    if (path.endsWith('/get-all-cities')) data = [{_id:'1',name:'Pune'}]
    if (path.endsWith('/get-all-leads')) data = [lead, {...lead,_id:'223456789012345678901234'}]
    if (path.includes('/get-lead/')) data = lead
    if (path.endsWith('/filter-options')) data = {projectTypes:[],propertyTypes:[]}
    if (path.endsWith('/get-cart')) data = {leads:[lead],removedLeads:[],totalItems:1,totalAmount:50}
    if (path.endsWith('/leads/history')) data = [{orderId:'123456789012345678901234',status:'PAID',isDownloaded:false,paidAt:'2026-01-01T00:00:00Z',items:[{...lead,leadId:lead._id}]}]
    if (path.endsWith('/wallet')) data = {balancePaise:10000,referralCreditPaise:5000,entries:[{_id:'1',kind:'TOPUP',amountPaise:10000,createdAt:'2026-01-01T00:00:00Z'}],nextCursor:null}
    if (path.includes('/wallet/topups/')) data = {topup:{_id:'1',status:'PAID',amountPaise:10000,paymentId:'pay_test123456789012345678901234',paidAt:'2026-01-01T00:00:00Z'},balancePaise:10000}
    if (path.endsWith('/referrals/me')) data = {referralCode:'TEST1234',referralLink:'https://example.com/?ref=TEST1234',invited:2,qualified:1,pending:1}
    if (path.endsWith('/referrals/history')) data = [{_id:'123456789012345678901234',status:'QUALIFIED',createdAt:'2026-01-01T00:00:00Z'}]
    await send('Fetch.fulfillRequest',{requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:'application/json'},{name:'Access-Control-Allow-Origin',value:base},{name:'Access-Control-Allow-Headers',value:'authorization,x-web-session,content-type'},{name:'Access-Control-Allow-Methods',value:'GET,OPTIONS'}],body:Buffer.from(JSON.stringify({success:true,data,pagination:{page:1,totalPages:1,total:1}})).toString('base64')})
  } catch { /* Navigation cancels obsolete requests. */ }
})
const findings = []
try {
  await send('Page.enable'); await send('Runtime.enable'); await send('Network.enable')
  await send('Fetch.enable',{patterns:[{urlPattern:'*'}]})
  await send('Page.addScriptToEvaluateOnNewDocument',{source:`localStorage.setItem('user_token','responsive-fixture')`})
  await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]})
  const routes = ['/', '/categories', '/?browse=1', `/leads/${lead._id}`, '/cart', '/my-leads', '/wallet', '/referrals', '/profile', '/pricing', '/contact', '/download', '/privacy-policy', '/terms-service', '/cookie-policy', '/contact-support', '/account-deletion', '/wallet/success/1', '/membership/success', '/signup', '/forgot-password', '/login', '/auth/mobile']
  await mkdir('.tmp/responsive-checks',{recursive:true})
  for (const width of [320,360,375,390,412,430,768,1024,1440]) {
    await send('Emulation.setDeviceMetricsOverride',{width,height:900,deviceScaleFactor:1,mobile:width<768})
    for (const route of routes) {
      await send('Page.navigate',{url:base+route})
      await until(`document.readyState === 'complete' && !!document.querySelector('#root')?.children.length && !document.querySelector('.boot-shell,.page-skeleton,.skeleton-card,.skeleton-rows')`)
      await pause(100)
      const result = await evaluate(`(() => {
        const elements = [...document.querySelectorAll('h1,h2,h3,p,button,input,select,textarea,a,article,form,dl')];
        return elements.filter(el=> {
          if (!el.checkVisibility() || el.closest('dialog:not([open]),.featured-vendor-grid,.referral-table-scroll,.lead-detail-tabs')) return false;
          const r=el.getBoundingClientRect(); return r.width>0 && (r.left < -1 || r.right > innerWidth+1);
        }).slice(0,12).map(el=>({tag:el.tagName,cls:el.className,text:el.textContent.slice(0,60),left:Math.round(el.getBoundingClientRect().left),right:Math.round(el.getBoundingClientRect().right)}));
      })()`)
      if(result.length) findings.push({width,route,overflow:result})
      if(route==='/' && [320,390,768,1440].includes(width)) {
        await evaluate(`document.querySelectorAll('img[loading=lazy]').forEach(img=>img.loading='eager')`)
        await until(`[...document.querySelectorAll('.steps-art,.download-banner>img')].every(img=>img.complete && img.naturalWidth)`)
        await writeFile(`.tmp/responsive-checks/home-${width}.png`,Buffer.from((await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:true})).data,'base64'))
        if(width<1025) {
          await evaluate(`document.querySelector('.mobile-nav-toggle').click()`)
          assert(await evaluate(`!!document.querySelector('dialog[open]') && document.body.style.overflow === 'hidden'`),'Drawer must open and lock scroll')
          assert.equal(await evaluate(`document.querySelectorAll('.mobile-nav-links>a,.mobile-nav-links>button').length`),6)
          for(let i=0;i<12;i++) {
            await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Tab',code:'Tab',windowsVirtualKeyCode:9})
            assert(await evaluate(`!!document.activeElement.closest('dialog')`),'Keyboard focus stays inside the menu')
          }
          if(width===390) await writeFile('.tmp/responsive-checks/menu-390.png',Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'))
          await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27})
          await until(`!document.querySelector('dialog[open]')`)
          assert(await evaluate(`document.body.style.overflow !== 'hidden'`),'Drawer restores scroll')
          assert(await evaluate(`document.activeElement === document.querySelector('.mobile-nav-toggle')`),'Focus returns to menu toggle')
          await evaluate(`document.querySelector('.mobile-nav-toggle').click()`)
          await send('Input.dispatchMouseEvent',{type:'mousePressed',x:4,y:100,button:'left',clickCount:1})
          await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:4,y:100,button:'left',clickCount:1})
          await until(`!document.querySelector('dialog[open]')`)
          await evaluate(`document.querySelector('.mobile-nav-toggle').click();document.querySelector('.mobile-nav-links>a[href="/wallet"]').click()`)
          await until(`location.pathname==='/wallet' && !document.querySelector('dialog[open]')`)
        } else {
          assert(await evaluate(`document.querySelector('.marketplace-actions').checkVisibility() && !document.querySelector('.mobile-nav-controls').checkVisibility()`),'Desktop keeps its navigation')
        }
      }
      if(route==='/wallet' && width===320) {
        await evaluate(`document.querySelector('.wallet-add-button').click()`)
        await until(`!!document.querySelector('.payment-review')`)
        assert(await evaluate(`[...document.querySelectorAll('.payment-review button,.payment-review input,.payment-review h1')].every(el=>el.getBoundingClientRect().right<=innerWidth+1)`),'Payment review controls fit narrow screens')
      }
    }
    console.log(`Checked ${routes.length} routes at ${width}px`)
  }
  await writeFile('.tmp/responsive-checks/results.json',JSON.stringify({findings,exceptions},null,2))
  console.log(JSON.stringify({findings,exceptions}))
  assert.deepEqual(findings,[],'All routes fit the viewport')
  assert.deepEqual(exceptions,[],'No runtime exceptions')
} finally { await send('Page.close').catch(()=>{}); socket.close() }

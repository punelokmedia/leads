import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import vm from 'node:vm'
import ts from 'typescript'
import { renderToStaticMarkup } from 'react-dom/server'

// Exercise the actual existing component handlers/JSX with isolated API/state
// boundaries. This is not a browser E2E test and makes no network requests.
const require = createRequire(import.meta.url)
const source = readFileSync(new URL('../src/components/layout/PublicHeader.tsx', import.meta.url), 'utf8')
const tree = ts.createSourceFile('PublicHeader.tsx', source, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX)
function find(predicate) {
  let found
  function visit(node) { if (predicate(node)) { found = node; return } ts.forEachChild(node, visit) }
  visit(tree)
  assert.ok(found, 'component test target exists')
  return found
}
function evaluate(code, bindings) {
  const exports = {}
  const compiled = ts.transpileModule(code, { compilerOptions: { module: ts.ModuleKind.CommonJS, jsx: ts.JsxEmit.ReactJSX } }).outputText
  const context = { exports, require, ...bindings }
  vm.runInNewContext(compiled, context)
  return { ...exports, context }
}
const handler = name => find(node => ts.isVariableDeclaration(node) && node.name.getText(tree) === name).initializer.getText(tree)
const available = [{ _id: 'shown-a', title: 'Available lead', price: 12.5, quantity: 1, remainingSlots: 1, totalSlots: 2 }]
function checkout({ leads = available, response = { success: true, data: { orderId: 'order-a' } }, ok = true } = {}) {
  const requests = [], errors = [], events = []
  const app = evaluate(`exports.submit = ${handler('handleProceedToPay')}`, {
    isPaymentProcessing: false, userToken: 'synthetic', cartLeads: leads,
    setIsPaymentProcessing: value => events.push(['processing', value]), resetAuthMessages() {},
    setAuthError: value => errors.push(value), setAuthSuccess() {}, setPanelMode: value => events.push(['panel', value]), navigate() {},
    setDownloadOrderId() {}, fetchHistoryLeads: async () => {}, fetchCart: async () => events.push(['refresh']),
    requestApi: async (path, init) => { requests.push({ path, init }); return { ok, json: async () => response } },
  })
  return { ...app, requests, errors, events }
}
test('React cart purchases exactly the displayed IDs and confirmed total', async () => {
  const app = checkout()
  await app.submit()
  assert.equal(app.requests.length, 1)
  assert.equal(app.requests[0].path, '/wallet/purchase')
  assert.deepEqual(JSON.parse(app.requests[0].init.body), { leadIds: ['shown-a'], expectedTotalPaise: 1250 })
  assert.equal(app.requests[0].init.headers['Content-Type'], 'application/json')
})
test('React unavailable checkout refreshes, shows server reason and never automatically purchases a reduced selection', async () => {
  const app = checkout({ ok: false, response: { success: false, code: 'SOLD_OUT', message: 'This lead is sold out. Review your cart.' } })
  await app.submit()
  assert.equal(app.requests.length, 1)
  assert.deepEqual(app.events.filter(event => event[0] === 'refresh'), [['refresh']])
  assert.equal(app.errors.at(-1), 'This lead is sold out. Review your cart.')
  assert.equal(app.events.some(event => event[0] === 'panel' && event[1] === 'history'), false)
})
test('React empty cart and in-flight duplicate clicks do not submit checkout', async () => {
  const empty = checkout({ leads: [] })
  await empty.submit()
  assert.equal(empty.requests.length, 0)
  const pending = checkout()
  pending.context.isPaymentProcessing = true
  await pending.submit()
  assert.equal(pending.requests.length, 0)
})
test('React price-change failure requests review without retrying payment', async () => {
  const app = checkout({ ok: false, response: { success: false, code: 'PRICE_CHANGED', message: 'The cart price has changed. Review your cart.' } })
  await app.submit()
  assert.equal(app.requests.length, 1)
  assert.match(app.errors.at(-1), /price has changed/)
})
const cartView = find(node => ts.isConditionalExpression(node) && node.condition.getText(tree) === "panelMode === 'cart'").whenTrue.getText(tree)
function renderCart(leads, removed) {
  const app = evaluate(`exports.render = () => (${cartView})`, {
    userToken: 'synthetic', isCartLoading: false, cartLeads: leads, removedCartLeads: removed,
    cartSummary: { totalItems: leads.length, totalAmount: leads.reduce((sum, item) => sum + item.price, 0) },
    isLoading: false, isPaymentProcessing: false, getLeadPreviewImage: () => '/synthetic.jpg',
  })
  return renderToStaticMarkup(app.render())
}
test('React shows unavailable reasons even when every cart item was removed', () => {
  const html = renderCart([], [{ _id: 'sold', title: 'Old lead', reason: 'This lead is sold out.' }])
  assert.match(html, /role="status"/)
  assert.match(html, /This lead is sold out/)
  assert.match(html, /Your cart is empty/)
})
test('React mixed cart renders remaining selection and clear removed-item reasons', () => {
  const html = renderCart(available, [{ _id: 'expired', title: 'Expired lead', reason: 'This lead has expired.' }])
  assert.match(html, /Review the remaining selection/)
  assert.match(html, /This lead has expired/)
  assert.match(html, /Available lead/)
  assert.equal((html.match(/<article/g) || []).length, 1)
})
test('React cart refresh retains the first removal notice across overlapping refresh responses', async () => {
  let removed = []
  const payloads = [
    { data: { leads: available, removedLeads: [{ _id: 'sold', title: 'Sold', reason: 'Sold out' }], totalItems: 1, totalAmount: 12.5 }, success: true },
    { data: { leads: available, removedLeads: [], totalItems: 1, totalAmount: 12.5 }, success: true },
  ]
  // fetchCart is useCallback(arrow, deps): select the actual arrow node.
  const declaration = find(node => ts.isVariableDeclaration(node) && node.name.getText(tree) === 'fetchCart')
  const arrow = declaration.initializer.arguments[0].getText(tree)
  const app = evaluate(`exports.refresh = ${arrow}`, {
    userToken: 'synthetic', resetAuthMessages() {}, setIsCartLoading() {}, setCartLeads() {}, setCartSummary() {}, setAuthError() {},
    setRemovedCartLeads: update => { removed = typeof update === 'function' ? update(removed) : update },
    requestApi: async () => ({ ok: true, json: async () => payloads.shift() }),
  })
  await app.refresh()
  await app.refresh()
  assert.equal(removed.length, 1)
  assert.equal(removed[0]._id, 'sold')
})

import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'
import ts from 'typescript'

const source = readFileSync(new URL('../src/features/auth/session.ts', import.meta.url), 'utf8')
const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText
function browser(fetch) {
  const values = new Map([['user_token', 'original'], ['user_profile', '{}']])
  const notices = new Map()
  let events = 0
  const storage = map => ({ getItem: key => map.get(key) ?? null, setItem: (key, value) => map.set(key, value), removeItem: key => map.delete(key) })
  const exports = {}
  vm.runInNewContext(compiled, {
    exports, URL, Request, Headers, fetch,
    window: { location: { origin: 'https://website.example' } },
    localStorage: storage(values), sessionStorage: storage(notices),
    require: name => name.includes('config/api') ? { API_BASE_URL: 'https://api.example' } : { notifyUserSessionChanged: () => events++ },
  })
  return { ...exports, values, notices, events: () => events }
}
const authenticated = { headers: { Authorization: 'Bearer original' } }
const endpoint = 'https://api.example/api/v1/auth/profile'

test('renewal is persisted and subsequent requests use the current token', async () => {
  const sent = []
  const app = browser(async (_url, init) => {
    sent.push(init.headers.get('Authorization'))
    assert.equal(init.headers.get('X-Web-Session'), '1')
    return new Response('{}', { headers: { 'X-Session-Token': 'renewed' } })
  })
  await app.apiFetch(endpoint, authenticated)
  await app.apiFetch(endpoint, authenticated)
  assert.deepEqual(sent, ['Bearer original', 'Bearer renewed'])
  assert.equal(app.values.get('user_token'), 'renewed')
})
test('confirmed expiry clears session and triggers the visible notice', async () => {
  const app = browser(async () => Response.json({ code: 'SESSION_EXPIRED' }, { status: 401 }))
  await app.apiFetch(endpoint, authenticated)
  assert.equal(app.values.has('user_token'), false)
  assert.equal(app.values.has('user_profile'), false)
  assert.equal(app.notices.get('session_expired'), '1')
  assert.equal(app.events(), 1)
})
test('server failures and incorrect login passwords preserve the session', async () => {
  for (const [status, code] of [[503, 'AUTH_UNAVAILABLE'], [401, 'INVALID_PASSWORD']]) {
    const app = browser(async () => Response.json({ code }, { status }))
    await app.apiFetch(endpoint, authenticated)
    assert.equal(app.values.get('user_token'), 'original')
    assert.equal(app.events(), 0)
  }
})
test('a delayed expired response cannot clear a newer login', async () => {
  let finish
  const app = browser(() => new Promise(resolve => { finish = resolve }))
  const pending = app.apiFetch(endpoint, authenticated)
  app.values.set('user_token', 'new-login')
  finish(Response.json({ code: 'SESSION_EXPIRED' }, { status: 401 }))
  await pending
  assert.equal(app.values.get('user_token'), 'new-login')
  assert.equal(app.events(), 0)
})
test('a delayed renewal cannot restore a logged out session', async () => {
  let finish
  const app = browser(() => new Promise(resolve => { finish = resolve }))
  const pending = app.apiFetch(endpoint, authenticated)
  app.values.delete('user_token')
  finish(new Response('{}', { headers: { 'X-Session-Token': 'renewed' } }))
  await pending
  assert.equal(app.values.has('user_token'), false)
})
test('external downloads do not receive web session headers', async () => {
  const app = browser(async (_url, init) => {
    assert.equal(init?.headers, undefined)
    return new Response('download')
  })
  await app.apiFetch('https://downloads.example/app.apk')
})

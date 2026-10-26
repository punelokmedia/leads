import test from 'node:test'
import assert from 'node:assert/strict'
import {readFileSync} from 'node:fs'
import vm from 'node:vm'
import ts from 'typescript'
const exports={}
const source=readFileSync(new URL('../src/features/auth/access-policy.ts',import.meta.url),'utf8')
vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports,URL,URLSearchParams})
test('browsing categories, leads and account pages requires login',()=>{
 for(const path of ['/categories','/leads/123','/profile','/wallet','/wallet/success/123','/cart','/referrals','/my-leads'])assert.equal(exports.requiresLogin(path,''),true)
 assert.equal(exports.requiresLogin('/','?category=123'),true)
 assert.equal(exports.requiresLogin('/','?browse=1'),true)
 for(const path of ['/','/login','/auth/mobile','/pricing','/download','/contact','/terms-service'])assert.equal(exports.requiresLogin(path,''),false)
})
test('post-login return destinations stay inside protected local pages',()=>{
 assert.equal(exports.safeReturnPath('/?category=123'),'/?category=123')
 assert.equal(exports.safeReturnPath('/wallet'),'/wallet')
 for(const path of ['https://evil.example','//evil.example','/\\evil.example','/login','/auth/mobile',null])assert.equal(exports.safeReturnPath(path),null)
})

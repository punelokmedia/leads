import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'
import ts from 'typescript'
const source = readFileSync(new URL('../src/features/home/pages/category-resolution.ts', import.meta.url),'utf8')
const exports = {}
vm.runInNewContext(ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText,{exports})
const {resolveCategory,categoryLeadUrl}=exports
const catalog=[{_id:'painting-id',name:'painting'},{_id:'pop-id',name:'false ceiling (pop)'},{_id:'civil-id',name:'home renovation / civil work'},{_id:'water-id',name:'waterproofing'}]
test('category navigation uses a database ID without a title-search parameter',()=>{
 const match=resolveCategory('Painting',catalog)
 const url=new URL(categoryLeadUrl(match._id),'https://example.com')
 assert.equal(url.searchParams.get('category'),'painting-id')
 assert.equal(url.searchParams.has('search'),false)
})
test('category aliases resolve exact catalog entries without broad substring matching',()=>{
 assert.equal(resolveCategory('POP & False Ceiling Work',catalog)._id,'pop-id')
 assert.equal(resolveCategory('Civil Work',catalog)._id,'civil-id')
 assert.equal(resolveCategory('Water Proofing',catalog)._id,'water-id')
 assert.equal(resolveCategory('Real Estate',catalog),undefined)
 assert.equal(resolveCategory('Painting',[{_id:'bad',name:'Painting supplies'}]),undefined)
})

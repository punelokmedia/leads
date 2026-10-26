import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { submitContact } from '../src/Controllers/contact.controller.js';
import { ContactMessage } from '../src/Models/contact.model.js';
const body = () => ({ requestId: crypto.randomUUID(), name:' Test Vendor ', phone:'+91 98765 43210', email:'VENDOR@EXAMPLE.INVALID', city:' Pune ', message:' Need painting leads. ', status:'RESOLVED', userId:'foreign' });
const response = () => ({ code:200, status(code) { this.code=code;return this; }, json(data){ this.body=data;return this; } });
test('contact validation rejects missing fields, objects and invalid phones before persistence', async t => {
  t.mock.method(ContactMessage,'findOne',()=>assert.fail('must validate before database'));
  for(const patch of [{name:''},{phone:'123'},{email:'invalid'},{message:''},{city:{$ne:''}},{requestId:'invalid'},{message:'x'.repeat(5001)}]) {
    const res=response();await submitContact({body:{...body(),...patch}},res);assert.equal(res.code,400);
  }
});
test('database errors do not claim success or expose details', async t => {
  t.mock.method(ContactMessage,'findOne',async()=>{throw new Error('secret connection string')});
  const res=response(); await submitContact({body:body()},res);assert.equal(res.code,503);assert.equal(res.body.success,false);assert.ok(!res.body.message.includes('secret'));
});
test('contact HTTP endpoint stores enquiries, normalizes data, ignores privileged fields and deduplicates retries',async()=>{
  const { MongoMemoryServer }=await import('mongodb-memory-server');
  const mongoose=(await import('mongoose')).default;
  const express=(await import('express')).default;
  const {contactRouter}=await import('../src/Routes/contact.routes.js');
  const mongo=await MongoMemoryServer.create({binary:{version:'7.0.24'}});
  let server;
  try {
    await mongoose.connect(mongo.getUri()); await ContactMessage.init();
    const app=express();app.use(express.json());app.use('/contact',contactRouter);
    server=app.listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));
    const url=`http://127.0.0.1:${server.address().port}/contact`;
    const payload=body();
    const send=()=>fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});
    const first=await send();assert.equal(first.status,201);const receipt=await first.json();assert.equal(receipt.success,true);
    assert.equal((await send()).status,200);assert.equal(await ContactMessage.countDocuments(),1);
    const saved=await ContactMessage.findOne();assert.equal(saved.name,'Test Vendor');assert.equal(saved.email,'vendor@example.invalid');assert.equal(saved.phone,'9876543210');assert.equal(saved.status,'NEW');assert.equal(saved.city,'Pune');assert.equal(saved.message,'Need painting leads.');assert.equal(saved.userId,undefined);
    assert.equal((await fetch(url)).status,401);
    const changed=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...payload,message:'different request'})});assert.equal(changed.status,409);
    await send();await send();assert.equal((await send()).status,429);
  } finally { if(server) await new Promise(resolve=>server.close(resolve));await mongoose.disconnect();await mongo.stop(); }
});

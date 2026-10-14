import { test, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';
import { User } from '../src/Models/user.model.js';
import { updateDevicePermissions, uploadProfilePicture } from '../src/Controllers/device.controller.js';
import { parseCoordinates } from '../src/Utils/location.js';
import { Lead } from '../src/Models/leads.model.js';
import { getAllLeads } from '../src/Controllers/Admin/leads.controller.js';

afterEach(() => mock.restoreAll());
const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
test('coordinates reject missing, boolean, nonfinite and out of range values', () => {
  for (const pair of [[null, 1], ['', 1], [true, 1], [91, 1], [0, 181], [Infinity, 1]]) assert.throws(() => parseCoordinates(...pair));
  assert.deepEqual(parseCoordinates(0, '72.5').coordinates, [72.5, 0]);
});
test('consented coordinates are stored in longitude latitude order', async () => {
  mock.method(User, 'findByIdAndUpdate', (id, update) => {
    assert.equal(id, 'user-1');
    assert.deepEqual(update.$set.currentLocation.coordinates, [73.8, 18.5]);
    return { select: async () => ({ devicePermissions: { location: 'granted' } }) };
  });
  const res = response();
  await updateDevicePermissions({ user: { id: 'user-1' }, body: { location: 'granted', latitude: 18.5, longitude: 73.8 } }, res);
  assert.equal(res.statusCode, 200);
});
test('revoking location deletes stored coordinates', async () => {
  mock.method(User, 'findByIdAndUpdate', (id, update) => {
    assert.deepEqual(update.$unset, { currentLocation: '', locationUpdatedAt: '' });
    return { select: async () => ({}) };
  });
  const res = response();
  await updateDevicePermissions({ user: { id: 'user-1' }, body: { location: 'denied' } }, res);
  assert.equal(res.statusCode, 200);
});
test('unconsented coordinates never reach database', async () => {
  mock.method(User, 'findByIdAndUpdate', () => assert.fail('must not store coordinates'));
  const res = response();
  await updateDevicePermissions({ body: { files: 'granted', latitude: 18, longitude: 73 } }, res);
  assert.equal(res.statusCode, 400);
});
test('profile upload rejects a forged image MIME type', async () => {
  const res = response();
  await uploadProfilePicture({ file: { mimetype: 'image/png', buffer: Buffer.from('<script>') } }, res);
  assert.equal(res.statusCode, 400);
});
test('nearby search requires authentication and location consent', async () => {
  let res = response();
  await getAllLeads({ query: { nearby: 'true' } }, res);
  assert.equal(res.statusCode, 401);
  mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({ devicePermissions: { location: 'denied' } }) }) }));
  res = response();
  await getAllLeads({ user: { id: 'user-1' }, query: { nearby: 'true' } }, res);
  assert.equal(res.statusCode, 400);
});
test('nearby count uses the saved coordinates and requested radius', async () => {
  mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({ devicePermissions: { location: 'granted' }, currentLocation: { coordinates: [73, 18] } }) }) }));
  mock.method(Lead, 'countDocuments', async (query) => {
    assert.deepEqual(query.location.$geoWithin.$centerSphere, [[73, 18], 10 / 6371.0088]);
    return 0;
  });
  // Stop after verifying the database predicate, before purchase lookup.
  mock.method(Lead, 'find', () => ({ populate() { return this; }, sort() { return this; }, limit() { return this; }, skip() { throw new Error('verified query'); } }));
  await getAllLeads({ user: { id: 'user-1' }, query: { nearby: 'true', radiusKm: '10' } }, response());
});

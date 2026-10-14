import { writeFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';

const website = 'https://www.trynextlead.com';
const api = 'https://leads-qa6h.vercel.app';
const reportPath = new URL('../Project-Docs/browsing-load-test.json', import.meta.url);
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const endpoints = [{ name: 'website', url: website },
  { name: 'categories', url: `${api}/api/v1/categories/get-all-categories`, json: true },
  { name: 'cities', url: `${api}/api/v1/cities/get-all-cities`, json: true }];
const htmlResponse = await fetch(website, { signal: AbortSignal.timeout(10000) });
if (!htmlResponse.ok) throw new Error(`Website preflight failed: ${htmlResponse.status}`);
const html = await htmlResponse.text();
for (const [name, pattern] of [['javascript', /src="([^" ]+\.js)"/], ['stylesheet', /href="([^" ]+\.css)"/]]) {
  const match = html.match(pattern);
  if (match) endpoints.push({ name, url: new URL(match[1], website).href });
}
async function request(endpoint) {
  const start = performance.now();
  try {
    const response = await fetch(endpoint.url, { signal: AbortSignal.timeout(10000) });
    const bytes = await response.arrayBuffer();
    let valid = response.status === 200;
    if (endpoint.json && valid) {
      try { valid = JSON.parse(new TextDecoder().decode(bytes)).success === true; } catch { valid = false; }
    }
    return { endpoint: endpoint.name, status: response.status, ok: valid, ms: performance.now() - start, bytes: bytes.byteLength, cache: response.headers.get('x-vercel-cache') };
  } catch (error) { return { endpoint: endpoint.name, status: 0, ok: false, ms: performance.now() - start, error: error.name }; }
}
const preflight = [];
for (const endpoint of endpoints) {
  const result = await request(endpoint);
  preflight.push(result);
  console.log(`Preflight ${endpoint.name}: ${result.status}, ${Math.round(result.ms)}ms`);
}
if (preflight.some(result => !result.ok)) {
  writeFileSync(reportPath, JSON.stringify({ timestamp: new Date().toISOString(), preflight, aborted: 'Preflight failed; no load applied' }, null, 2));
  throw new Error('Preflight failed; load test aborted.');
}
function summary(rows) {
  const sorted = rows.map(row => row.ms).sort((a, b) => a - b);
  const percentile = value => Math.round(sorted[Math.max(0, Math.ceil(sorted.length * value) - 1)] || 0);
  const statuses = {}; const caches = {};
  for (const row of rows) { statuses[row.status] = (statuses[row.status] || 0) + 1; if (row.cache) caches[row.cache] = (caches[row.cache] || 0) + 1; }
  return { requests: rows.length, failures: rows.filter(row => !row.ok).length, medianMs: percentile(.5), p95Ms: percentile(.95), maxMs: percentile(1), statuses, caches };
}
const stages = [];
for (const workers of [2, 5, 10]) {
  const rows = []; let stop = false; let index = 0;
  const start = performance.now(); const deadline = start + 10000;
  await Promise.all(Array.from({ length: workers }, async () => {
    while (!stop && performance.now() < deadline) {
      const tick = performance.now();
      const result = await request(endpoints[index++ % endpoints.length]);
      rows.push(result);
      if (!result.ok || result.ms > 5000) stop = true;
      // At most one request per worker per second; no unbounded traffic.
      await sleep(Math.max(0, 1000 - (performance.now() - tick)));
    }
  }));
  const elapsedSeconds = (performance.now() - start) / 1000;
  const stage = { workers, elapsedSeconds: +elapsedSeconds.toFixed(2), requestsPerSecond: +(rows.length / elapsedSeconds).toFixed(2), ...summary(rows), stoppedEarly: stop,
    endpoints: Object.fromEntries(endpoints.map(endpoint => [endpoint.name, summary(rows.filter(row => row.endpoint === endpoint.name))])) };
  stages.push(stage);
  console.log(JSON.stringify(stage));
  if (stop) break;
  await sleep(2000);
}
writeFileSync(reportPath, JSON.stringify({ timestamp: new Date().toISOString(), website, api, scope: 'HTTP browsing only, 2/5/10 workers, 10 seconds per stage, one request per worker per second. No authentication, lead listing, writes or payments. Stops on failure or latency over 5 seconds. Not a browser render or capacity benchmark.', preflight, stages }, null, 2));
console.log(`Report saved: ${reportPath.pathname}`);

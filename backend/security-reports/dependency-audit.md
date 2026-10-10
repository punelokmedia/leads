# Dependency audit

Date: 2026-10-10. Scope: local source, installed dependencies, loopback HTTP, disposable MongoDB 7.0.24 replica sets, synthetic users and mocked Razorpay. No production database queries/writes, real payments, deployment or application fixes were performed. This is a targeted local verification, not a certification or exhaustive penetration test.

Backend result: 99 tests, 93 pass, 6 fail. Failing security expectations remain enabled to make the findings reproducible. Evidence: [complete backend output](evidence/backend-tests.txt).

| Test | Method | Expected | Actual | Status | Severity | Recommended fix | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Backend full audit | npm audit --json and npm audit | No unresolved findings | {"info":0,"low":0,"moderate":0,"high":0,"critical":0,"total":0} | PASS | None reported | Continue auditing locked installs | [JSON](evidence/backend-audit.json); [text](evidence/backend-audit.txt) |
| Backend production audit | npm audit --omit=dev --json | No applicable critical/high findings | {"info":0,"low":0,"moderate":0,"high":0,"critical":0,"total":0} | PASS | None reported | Deploy lockfile with npm ci | [production JSON](evidence/backend-production-audit.json) |
| Dependency tree integrity | npm ls --all and --json | No missing/invalid dependency errors | Exit 0; installed tree captured | PASS | None | None | [tree](evidence/backend-tree.txt); [JSON](evidence/backend-tree.json) |
| Web full audit | frontend workspace npm audit --json | No unresolved high/critical findings | {"info":0,"low":1,"moderate":2,"high":9,"critical":0,"total":12} | FAIL | High | Review advisories, upgrade compatible frontend parents and rerun build/lint/tests; no fixes made in this pass | [JSON](evidence/frontend-audit.json) |
| Web production audit | frontend workspace npm audit --omit=dev --json | No unresolved production findings | {"info":0,"low":0,"moderate":0,"high":2,"critical":0,"total":2} | FAIL | High registry severity; deployment reachability needs review | Upgrade react-router-dom and verify routes/redirects | [JSON](evidence/frontend-production-audit.json) |

## All 22 historical backend entries

These are package entries, not 22 independent exploits. All installed versions below are from the current lockfile and tree. The fresh audit has no unresolved backend advisory, so no remaining backend moderate/low findings require exceptions. Removed packages have no current installed production path. Parent upgrades can resolve vulnerabilities without changing the parent's own version.

| Package | Installed version/path | Current finding | Status | Patch disposition | Production use |
| --- | --- | --- | --- | --- | --- |
| express | node_modules/express: 5.3.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| proxy-addr | node_modules/proxy-addr: 2.0.8 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| axios | node_modules/axios: 1.20.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| brace-expansion | node_modules/brace-expansion: 1.1.21; node_modules/readdir-glob/node_modules/brace-expansion: 2.1.7 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| braces | Absent / removed | None in current audit | PASS | Removed dependency path; no patch needed | No current backend production use |
| chokidar | Absent / removed | None in current audit | PASS | Removed dependency path; no patch needed | No current backend production use |
| exceljs | node_modules/exceljs: 4.4.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| form-data | node_modules/form-data: 4.0.6 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| multer | node_modules/multer: 2.4.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| nodemailer | node_modules/nodemailer: 10.1.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| nodemon | Absent / removed | None in current audit | PASS | Removed dependency path; no patch needed | No current backend production use |
| razorpay | node_modules/razorpay: 2.9.8 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| tmp | node_modules/tmp: 0.2.7 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Transitive ExcelJS streaming reader; application uses in-memory XLSX, not streaming temp files |
| xlsx | Absent / removed | None in current audit | PASS | Removed dependency path; no patch needed | No current backend production use |
| body-parser | node_modules/body-parser: 2.3.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| follow-redirects | node_modules/follow-redirects: 1.16.1 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| minimatch | node_modules/minimatch: 3.1.5; node_modules/readdir-glob/node_modules/minimatch: 5.1.9 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| mongoose | node_modules/mongoose: 9.11.1 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| qs | node_modules/qs: 6.16.0 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| resend | node_modules/resend: 6.32.1 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | Installed production dependency or transitive production chain; advisory-specific reachability differs |
| svix | Absent / removed | None in current audit | PASS | Removed dependency path; no patch needed | No current backend production use |
| uuid | node_modules/uuid: 11.1.1 | None in current audit | PASS | Installed version not flagged; resolved through patched dependency tree | ExcelJS conditional formatting v4; tested scoped CommonJS-compatible override |

## Frontend findings (outside the earlier backend-only fix)

| Package | Installed version/path | Registry severity | Fix availability | Affected path |
| --- | --- | --- | --- | --- |
| @babel/core | node_modules/@babel/core: 7.29.0 | low | Available per registry audit | node_modules/@babel/core |
| @humanfs/node | node_modules/@humanfs/node: 0.16.7 | moderate | Available per registry audit | node_modules/@humanfs/node |
| baseline-browser-mapping | node_modules/baseline-browser-mapping: 2.10.17 | moderate | Available per registry audit | node_modules/baseline-browser-mapping |
| brace-expansion | node_modules/@typescript-eslint/typescript-estree/node_modules/brace-expansion: 5.0.5; node_modules/brace-expansion: 1.1.13 | high | Available per registry audit | node_modules/@typescript-eslint/typescript-estree/node_modules/brace-expansion; node_modules/brace-expansion |
| browserslist | node_modules/browserslist: 4.28.2 | high | Available per registry audit | node_modules/browserslist |
| js-yaml | node_modules/js-yaml: 4.1.1 | high | Available per registry audit | node_modules/js-yaml |
| nanoid | node_modules/nanoid: 3.3.11 | high | Available per registry audit | node_modules/nanoid |
| postcss | node_modules/postcss: 8.5.9 | high | Available per registry audit | node_modules/postcss |
| react-router | node_modules/react-router: 7.14.0 | high | Available per registry audit | node_modules/react-router |
| react-router-dom | node_modules/react-router-dom: 7.14.0 | high | Available per registry audit | node_modules/react-router-dom |
| source-map-js | node_modules/source-map-js: 1.2.1 | high | Available per registry audit | node_modules/source-map-js |
| vite | node_modules/vite: 8.0.8 | high | Available per registry audit | node_modules/vite |

Production react-router-dom inherits react-router findings; do not count them as separate attacks. The application uses createBrowserRouter with static Vite builds. Server/RSC/SSR-specific advisories were not reproduced and may not apply to that deployment mode. Browser redirect/route handling still needs review; the audit cannot prove exploitability or dismissal. Toolchain findings concern development/build infrastructure and should not be treated as deployed API exploits.

## Historical backend advisories and affected ranges

Taken from the saved pre-remediation full audit. These are historical findings, not current failures.

### express

Historical dependency paths: node_modules/express.

- Inherited from body-parser; this is not another independent exploit.
- Inherited from proxy-addr; this is not another independent exploit.
- Inherited from qs; this is not another independent exploit.

### proxy-addr

Historical dependency paths: node_modules/proxy-addr.

- [proxy-addr vulnerable to IP spoofing via IPv4-mapped IPv6 trust subnet](https://github.com/advisories/GHSA-jqcg-44mw-7w3h); historical affected range: `>=1.1.0 <2.0.8`; severity: critical.

### axios

Historical dependency paths: node_modules/axios.

- [Axios: Authentication Bypass via Prototype Pollution Gadget in `validateStatus` Merge Strategy](https://github.com/advisories/GHSA-w9j2-pvgh-6h63); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios: Incomplete Fix for CVE-2025-62718 — NO_PROXY Protection Bypassed via RFC 1122 Loopback Subnet (127.0.0.0/8) in Axios 1.15.0](https://github.com/advisories/GHSA-pmwg-cvhr-8vh7); historical affected range: `>=1.0.0 <1.15.1`; severity: high.
- [Axios: Invisible JSON Response Tampering via Prototype Pollution Gadget in `parseReviver`](https://github.com/advisories/GHSA-3w6x-2g7m-8v23); historical affected range: `>=1.0.0 <1.15.2`; severity: moderate.
- [Axios: Null Byte Injection via Reverse-Encoding in AxiosURLSearchParams](https://github.com/advisories/GHSA-xhjh-pmcv-23jw); historical affected range: `>=1.0.0 <1.15.1`; severity: low.
- [Axios: CRLF Injection in multipart/form-data body via unsanitized blob.type in formDataToStream](https://github.com/advisories/GHSA-445q-vr5w-6q77); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios: no_proxy bypass via IP alias allows SSRF](https://github.com/advisories/GHSA-m7pr-hjqh-92cm); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios' HTTP adapter-streamed uploads bypass maxBodyLength when maxRedirects: 0](https://github.com/advisories/GHSA-5c9x-8gcm-mpgx); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios: HTTP adapter streamed responses bypass maxContentLength](https://github.com/advisories/GHSA-vf2m-468p-8v99); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios: Prototype Pollution Gadgets - Response Tampering, Data Exfiltration, and Request Hijacking](https://github.com/advisories/GHSA-pf86-5x62-jrwf); historical affected range: `>=1.0.0 <1.15.1`; severity: high.
- [Axios: Header Injection via Prototype Pollution](https://github.com/advisories/GHSA-6chq-wfr3-2hj9); historical affected range: `>=1.0.0 <1.15.1`; severity: high.
- [Axios: XSRF Token Cross-Origin Leakage via Prototype Pollution Gadget in `withXSRFToken` Boolean Coercion](https://github.com/advisories/GHSA-xx6v-rp6x-q39c); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios has prototype pollution read-side gadgets in HTTP adapter that allow credential injection and request hijacking](https://github.com/advisories/GHSA-q8qp-cvcw-x6jj); historical affected range: `>=1.0.0 <1.15.2`; severity: high.
- [Axios: unbounded recursion in toFormData causes DoS via deeply nested request data](https://github.com/advisories/GHSA-62hf-57xw-28j9); historical affected range: `>=1.0.0 <1.15.1`; severity: moderate.
- [Axios: Regular Expression Denial of Service (ReDoS) via Cookie Name Injection](https://github.com/advisories/GHSA-hfxv-24rg-xrqf); historical affected range: `>=1.0.0 <1.16.0`; severity: high.
- [Allocation of Resources Without Limits or Throttling in Axios](https://github.com/advisories/GHSA-777c-7fjr-54vf); historical affected range: `>=1.7.0 <1.16.0`; severity: high.
- [Axios: Proxy-Authorization Credential Leak to Origin Server Across HTTP-to-HTTPS Redirect in Axios Node.js HTTP Adapter](https://github.com/advisories/GHSA-p92q-9vqr-4j8v); historical affected range: `>=1.0.0 <1.16.0`; severity: high.
- [Axios: Proxy-Authorization header leaks to redirect target when proxy is re-evaluated to direct connection](https://github.com/advisories/GHSA-j5f8-grm9-p9fc); historical affected range: `>=1.0.0 <1.16.0`; severity: high.
- [axios Vulnerable to Credential Theft and Response Hijacking via Prototype Pollution Gadget in Config Merge](https://github.com/advisories/GHSA-3g43-6gmg-66jw); historical affected range: `>=1.0.0 <1.15.2`; severity: high.
- [axios Vulnerable to Full Man-in-the-Middle via Prototype Pollution Gadget in `config.proxy`](https://github.com/advisories/GHSA-35jp-ww65-95wh); historical affected range: `>=1.0.0 <1.16.0`; severity: high.
- [axios has DoS & Header Injection via Prototype Pollution Read-Side Gadgets in axios merge functions](https://github.com/advisories/GHSA-898c-q2cr-xwhg); historical affected range: `>=1.0.0 <1.16.0`; severity: moderate.
- [axios's shouldBypassProxy does not recognize IPv4-mapped IPv6 addresses, allowing NO_PROXY bypass (incomplete fix for CVE-2025-62718)](https://github.com/advisories/GHSA-pjwm-pj3p-43mv); historical affected range: `>=1.15.0 <1.16.0`; severity: high.
- [Axios: Prototype pollution gadgets can alter axios request construction](https://github.com/advisories/GHSA-mmx7-hfxf-jppx); historical affected range: `>=1.0.0 <1.18.0`; severity: moderate.
- [Axios: Deep formToJSON Key Recursion Can Cause Denial of Service](https://github.com/advisories/GHSA-pmv8-rq9r-6j72); historical affected range: `>=1.0.0 <1.18.0`; severity: moderate.
- [Axios: HTTP/2 streamed uploads bypass `maxBodyLength`](https://github.com/advisories/GHSA-mwf2-3pr3-8698); historical affected range: `>=1.13.0 <1.18.0`; severity: moderate.
- [Axios: Nested axios option objects can consume polluted prototype values](https://github.com/advisories/GHSA-7q8q-rj6j-mhjq); historical affected range: `>=1.0.0 <1.18.0`; severity: moderate.
- [Axios: Fetch adapter `ReadableStream` uploads bypass `maxBodyLength`](https://github.com/advisories/GHSA-jqh4-m9w3-8hp9); historical affected range: `>=1.7.0 <1.18.0`; severity: moderate.
- [Axios: NO_PROXY bypass for 0.0.0.0 local addresses in axios](https://github.com/advisories/GHSA-f4gw-2p7v-4548); historical affected range: `>=1.15.0 <1.18.0`; severity: moderate.
- [Axios: Excessive recursion in formDataToJSON can cause denial of service](https://github.com/advisories/GHSA-42h9-826w-cgv3); historical affected range: `>=1.0.0 <1.18.0`; severity: moderate.
- [Axios: Prototype pollution gadget in fetch adapter can alter outbound requests](https://github.com/advisories/GHSA-vh66-26gq-q6x8); historical affected range: `>=1.7.0 <1.20.0`; severity: moderate.
- [Axios: Prototype-Pollution Gadget in the Default Instance Allows Inherited Object.prototype.method to Override HTTP Method](https://github.com/advisories/GHSA-9fr6-4gfg-395g); historical affected range: `>=1.0.0 <1.20.0`; severity: moderate.
- [Axios: ReDoS (O(N²)) in shouldBypassProxy host normalization, reachable via untrusted redirect Location](https://github.com/advisories/GHSA-mghh-pgcx-3jjj); historical affected range: `>=1.15.0 <1.20.0`; severity: high.
- [Axios: HTTP/2 adapter bypasses configured DNS lookup and proxy controls](https://github.com/advisories/GHSA-3pq3-5fj3-cg6v); historical affected range: `>=1.13.0 <1.20.0`; severity: high.
- [Axios: Denial of Service via Unhandled 'error' Event in HTTP/2 ClientHttp2Session Initialization](https://github.com/advisories/GHSA-542g-h47m-68v8); historical affected range: `>=1.13.0 <1.20.0`; severity: high.
- [Axios: Header Injection via Inherited headers After Minimal Interceptor](https://github.com/advisories/GHSA-j8rh-479h-cp32); historical affected range: `>=1.0.0 <1.20.0`; severity: moderate.
- [Axios: Fetch Adapter Header Injection via Inherited FormData getHeaders](https://github.com/advisories/GHSA-4hqw-qxg8-jxx2); historical affected range: `>=1.12.0 <1.20.0`; severity: moderate.
- [Axios: CIDR-form NO_PROXY entries are ignored, causing proxy exclusion bypass for internal IP ranges](https://github.com/advisories/GHSA-44g4-m2mj-wpvx); historical affected range: `>=1.15.0 <1.20.0`; severity: moderate.
- Inherited from follow-redirects; this is not another independent exploit.
- Inherited from form-data; this is not another independent exploit.

### brace-expansion

Historical dependency paths: node_modules/brace-expansion, node_modules/glob/node_modules/brace-expansion, node_modules/readdir-glob/node_modules/brace-expansion.

- [brace-expansion: Large numeric range defeats documented `max` DoS protection](https://github.com/advisories/GHSA-jxxr-4gwj-5jf2); historical affected range: `>=5.0.0 <5.0.6`; severity: moderate.
- [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp); historical affected range: `>=2.0.0 <2.1.2`; severity: high.
- [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp); historical affected range: `<1.1.16`; severity: high.
- [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp); historical affected range: `>=3.0.0 <5.0.7`; severity: high.
- [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg); historical affected range: `<1.1.17`; severity: high.
- [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg); historical affected range: `>=2.0.0 <2.1.3`; severity: high.
- [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg); historical affected range: `>=4.0.0 <5.0.8`; severity: high.
- [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895); historical affected range: `>=4.0.0 <5.0.9`; severity: high.
- [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895); historical affected range: `>=2.0.0 <2.1.4`; severity: high.
- [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895); historical affected range: `<1.1.18`; severity: high.
- [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr); historical affected range: `<1.1.21`; severity: moderate.
- [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr); historical affected range: `>=2.0.0 <2.1.7`; severity: moderate.
- [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr); historical affected range: `>=4.0.0 <5.0.12`; severity: moderate.
- [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7); historical affected range: `<1.1.20`; severity: high.
- [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7); historical affected range: `>=2.0.0 <2.1.6`; severity: high.
- [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7); historical affected range: `>=4.0.0 <5.0.11`; severity: high.
- [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p); historical affected range: `<1.1.19`; severity: high.
- [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p); historical affected range: `>=2.0.0 <2.1.5`; severity: high.
- [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p); historical affected range: `>=4.0.0 <5.0.10`; severity: high.

### braces

Historical dependency paths: node_modules/braces.

- [braces vulnerable to stack-exhaustion denial of service through deeply nested patterns](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm); historical affected range: `<=3.0.3`; severity: high.

### chokidar

Historical dependency paths: node_modules/chokidar.

- Inherited from braces; this is not another independent exploit.

### exceljs

Historical dependency paths: node_modules/exceljs.

- Inherited from tmp; this is not another independent exploit.
- Inherited from uuid; this is not another independent exploit.

### form-data

Historical dependency paths: node_modules/form-data.

- [form-data: CRLF injection in form-data via unescaped multipart field names and filenames](https://github.com/advisories/GHSA-hmw2-7cc7-3qxx); historical affected range: `>=4.0.0 <4.0.6`; severity: high.

### multer

Historical dependency paths: node_modules/multer.

- [Multer vulnerable to Denial of Service via deeply nested field names](https://github.com/advisories/GHSA-72gw-mp4g-v24j); historical affected range: `>=1.0.0 <2.2.0`; severity: high.
- [Multer vulnerable to Denial of Service via incomplete cleanup of aborted uploads](https://github.com/advisories/GHSA-3p4h-7m6x-2hcm); historical affected range: `>=2.0.0-alpha.1 <2.2.0`; severity: moderate.
- [multer vulnerable to Denial of Service via crafted multipart field names](https://github.com/advisories/GHSA-wc9g-mqfw-jrwm); historical affected range: `<2.3.0`; severity: high.
- [multer vulnerable to file size limit bypass via async fileFilter race condition](https://github.com/advisories/GHSA-qvfw-j98x-7q72); historical affected range: `<2.3.0`; severity: low.
- [multer vulnerable to Denial of Service via oversized array index in field names](https://github.com/advisories/GHSA-535w-7cp7-47q4); historical affected range: `<2.3.0`; severity: high.

### nodemailer

Historical dependency paths: node_modules/nodemailer.

- [Nodemailer: CRLF injection in Nodemailer List-* header comments allows arbitrary message header injection](https://github.com/advisories/GHSA-268h-hp4c-crq3); historical affected range: `<=8.0.8`; severity: moderate.
- [Nodemailer jsonTransport bypasses disableFileAccess and disableUrlAccess during message normalization](https://github.com/advisories/GHSA-wqvq-jvpq-h66f); historical affected range: `<=8.0.8`; severity: moderate.
- [Nodemailer: Message-level raw option bypasses disableFileAccess/disableUrlAccess, enabling arbitrary file read and full-response SSRF in the delivered message](https://github.com/advisories/GHSA-p6gq-j5cr-w38f); historical affected range: `<=9.0.0`; severity: high.
- [Nodemailer: resolveContent() on a MailMessage bypasses disableFileAccess/disableUrlAccess when called with the legacy signature](https://github.com/advisories/GHSA-8m3c-c648-2xjj); historical affected range: `<=9.1.0`; severity: moderate.
- [Nodemailer: IDN/Punycode domain allow-list bypass leads to email delivery to an attacker-controlled domain](https://github.com/advisories/GHSA-wmmp-3585-3rmp); historical affected range: `<9.1.0`; severity: moderate.
- [Nodemailer: Quadratic (O(n²)) time complexity in addressparser allows remote denial of service via a crafted address list](https://github.com/advisories/GHSA-2x7j-588g-ccc2); historical affected range: `<9.1.0`; severity: high.
- [Nodemailer: Recipient-domain validation bypass via RFC 5322 comment mis-parsing leads to email delivery to an attacker-controlled domain](https://github.com/advisories/GHSA-cc9r-2j5m-2m83); historical affected range: `>=6.9.16 <9.1.0`; severity: moderate.
- [Nodemailer: Process-global DNS cache reuses TLS `servername` across transports, enabling cross-tenant SMTP credential disclosure](https://github.com/advisories/GHSA-6vj9-mwq6-2f5v); historical affected range: `>=5.0.0 <10.0.2`; severity: moderate.
- [Nodemailer: Nested structured recipient arrays bypass the parser depth limit and cause stack exhaustion DoS](https://github.com/advisories/GHSA-8vvx-rff5-p5rq); historical affected range: `<10.0.2`; severity: moderate.
- [Nodemailer: Quadratic backtracking in the addressparser free-text fallback allows remote denial of service](https://github.com/advisories/GHSA-v53p-9fqp-m79j); historical affected range: `<=10.0.5`; severity: high.
- [Nodemailer: Improper TLS Certificate Validation in OAuth2 Token Fetch Enables Credential Interception](https://github.com/advisories/GHSA-r7g4-qg5f-qqm2); historical affected range: `<=8.0.7`; severity: high.

### nodemon

Historical dependency paths: node_modules/nodemon.

- Inherited from chokidar; this is not another independent exploit.
- Inherited from minimatch; this is not another independent exploit.

### razorpay

Historical dependency paths: node_modules/razorpay.

- Inherited from axios; this is not another independent exploit.

### tmp

Historical dependency paths: node_modules/tmp.

- [tmp has Path Traversal via unsanitized prefix/postfix that enables directory escape](https://github.com/advisories/GHSA-ph9p-34f9-6g65); historical affected range: `<0.2.6`; severity: high.

### xlsx

Historical dependency paths: node_modules/xlsx.

- [Prototype Pollution in sheetJS](https://github.com/advisories/GHSA-4r6h-8v6p-xvw6); historical affected range: `<0.19.3`; severity: high.
- [SheetJS Regular Expression Denial of Service (ReDoS)](https://github.com/advisories/GHSA-5pgg-2g8v-p4x9); historical affected range: `<0.20.2`; severity: high.

### body-parser

Historical dependency paths: node_modules/body-parser.

- [body-parser vulnerable to denial of service when invalid limit value silently disables size enforcement](https://github.com/advisories/GHSA-v422-hmwv-36x6); historical affected range: `>=2.0.0 <2.3.0`; severity: low.
- Inherited from qs; this is not another independent exploit.

### follow-redirects

Historical dependency paths: node_modules/follow-redirects.

- [follow-redirects leaks Custom Authentication Headers to Cross-Domain Redirect Targets](https://github.com/advisories/GHSA-r4q5-vmmm-2653); historical affected range: `<=1.15.11`; severity: moderate.

### minimatch

Historical dependency paths: node_modules/minimatch.

- Inherited from brace-expansion; this is not another independent exploit.

### mongoose

Historical dependency paths: node_modules/mongoose.

- [Mongoose: Prototype pollution in mongoose update casting via __proto__-prefixed dotted path (Schema._getSchema/path getter)](https://github.com/advisories/GHSA-664h-wqgq-64gw); historical affected range: `>=9.0.0 <9.7.2`; severity: moderate.

### qs

Historical dependency paths: node_modules/qs.

- [qs has a remotely triggerable DoS: qs.stringify crashes with TypeError on null/undefined entries in comma-format arrays when encodeValuesOnly is set](https://github.com/advisories/GHSA-q8mj-m7cp-5q26); historical affected range: `>=6.11.1 <=6.15.1`; severity: moderate.
- [qs array-limit bypass via bracket-key comma parsing](https://github.com/advisories/GHSA-x5fp-wj9c-mxmx); historical affected range: `>=6.14.2 <=6.15.3`; severity: moderate.
- [qs: Denial of Service via Attacker Controlled isBuffer](https://github.com/advisories/GHSA-4mjr-xmp4-gh2g); historical affected range: `>=2.2.5 <6.16.0`; severity: moderate.

### resend

Historical dependency paths: node_modules/resend.

- Inherited from svix; this is not another independent exploit.

### svix

Historical dependency paths: node_modules/svix.

- Inherited from uuid; this is not another independent exploit.

### uuid

Historical dependency paths: node_modules/exceljs/node_modules/uuid, node_modules/uuid.

- [uuid: Missing buffer bounds check in v3/v5/v6 when buf is provided](https://github.com/advisories/GHSA-w5hq-g745-h8pq); historical affected range: `<11.1.1`; severity: moderate.

### Frontend @babel/core

- [@babel/core: Arbitrary File Read via sourceMappingURL Comment](https://github.com/advisories/GHSA-4x5r-pxfx-6jf8); affected range `<=7.29.0`; low.

### Frontend @humanfs/node

- [humanfs: Recursive copy follows symlinked files and copies data from outside the source tree](https://github.com/advisories/GHSA-p498-v437-472g); affected range `<0.16.8`; moderate.

### Frontend baseline-browser-mapping

- [baseline-browser-mapping process termination on invalid input causes denial of service](https://github.com/advisories/GHSA-w5vr-8v7q-w6rv); affected range `>=2.0.0 <2.11.0`; moderate.

### Frontend brace-expansion

- [brace-expansion: Large numeric range defeats documented `max` DoS protection](https://github.com/advisories/GHSA-jxxr-4gwj-5jf2); affected range `>=5.0.0 <5.0.6`; moderate.
- [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp); affected range `<1.1.16`; high.
- [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp); affected range `>=3.0.0 <5.0.7`; high.
- [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg); affected range `<1.1.17`; high.
- [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg); affected range `>=4.0.0 <5.0.8`; high.
- [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895); affected range `>=4.0.0 <5.0.9`; high.
- [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895); affected range `<1.1.18`; high.
- [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr); affected range `<1.1.21`; moderate.
- [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr); affected range `>=4.0.0 <5.0.12`; moderate.
- [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7); affected range `<1.1.20`; high.
- [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7); affected range `>=4.0.0 <5.0.11`; high.
- [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p); affected range `<1.1.19`; high.
- [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p); affected range `>=4.0.0 <5.0.10`; high.

### Frontend browserslist

- [Browserslist: Unbounded memory growth (no cache eviction) via distinct query results, leading to eventual OOM](https://github.com/advisories/GHSA-c83g-rgw3-j3cx); affected range `<=4.28.6`; high.
- [Browserslist: Uncaught crash / prototype write via untrusted browserslist-stats.json custom stats (normalizeStats)](https://github.com/advisories/GHSA-73wf-gq98-2v4g); affected range `<=4.28.6`; high.

### Frontend js-yaml

- [JS-YAML: Quadratic-complexity DoS in merge key handling via repeated aliases](https://github.com/advisories/GHSA-h67p-54hq-rp68); affected range `>=4.0.0 <=4.1.1`; moderate.
- [js-yaml: YAML merge-key chains can force quadratic CPU consumption](https://github.com/advisories/GHSA-52cp-r559-cp3m); affected range `>=4.0.0 <4.3.0`; high.
- [JS-YAML: Quadratic CPU consumption in !!omap resolution (3.x and 4.x) — CVE-2026-59870 fix not backported](https://github.com/advisories/GHSA-5p4m-2wfm-xmqj); affected range `>=4.0.0 <4.3.1`; high.
- [js-yaml: maxTotalMergeKeys does not limit CPU use for empty merge sources](https://github.com/advisories/GHSA-2883-xcg3-v3hh); affected range `>=4.0.0 <4.3.2`; high.

### Frontend nanoid

- [nanoid: non-secure generators can loop indefinitely with negative size](https://github.com/advisories/GHSA-28wg-ghj8-5hjv); affected range `<3.3.16`; high.
- [nanoid: custom generators can loop indefinitely when size is zero](https://github.com/advisories/GHSA-2v37-7h3g-55p8); affected range `<3.3.18`; high.
- [nanoid: Integer Overflow or Wraparound](https://github.com/advisories/GHSA-xwg4-73v4-xw9w); affected range `<3.3.12`; high.

### Frontend postcss

- [PostCSS has XSS via Unescaped </style> in its CSS Stringify Output](https://github.com/advisories/GHSA-qx2v-qp2m-jg93); affected range `<8.5.10`; moderate.
- [PostCSS: Arbitrary file read and information disclosure via attacker-controlled sourceMappingURL in CSS comments](https://github.com/advisories/GHSA-6g55-p6wh-862q); affected range `<=8.5.11`; high.
- [PostCSS: incomplete fix of GHSA-6g55-p6wh-862q — attacker-controlled sourceMappingURL reads arbitrary .map files when `from` is unset](https://github.com/advisories/GHSA-fxqj-rqcc-2cmp); affected range `<=8.5.22`; moderate.
- [PostCSS: Path Traversal in Previous Source Map Auto-Loading (sourceMappingURL) leads to Arbitrary .map File Disclosure](https://github.com/advisories/GHSA-r28c-9q8g-f849); affected range `<=8.5.17`; high.

### Frontend react-router

- [React Router's vendored turbo-stream v2 allows arbitrary constructor invocation via TYPE_ERROR deserialization leading to Unauth RCE](https://github.com/advisories/GHSA-49rj-9fvp-4h2h); affected range `>=7.0.0 <=7.14.1`; high.
- [React Router vulnerable to DoS via unbounded path expansion in __manifest endpoint](https://github.com/advisories/GHSA-8x6r-g9mw-2r78); affected range `>=7.0.0 <7.15.0`; high.
- [React Router: Potential CSRF via PUT/PATCH/DELETE document requests](https://github.com/advisories/GHSA-84g9-w2xq-vcv6); affected range `>=7.12.0 <7.15.1`; low.
- [React Router: Open redirect via backslash in <Link> and useNavigate (CVE-2025-68470 bypass)](https://github.com/advisories/GHSA-wrjc-x8rr-h8h6); affected range `>=6.0.0 <7.18.0`; moderate.
- [React Router: RSCErrorHandler Missing Protocol Validation (XSS)](https://github.com/advisories/GHSA-h8fp-f39c-q6mh); affected range `>=7.11.0 <7.18.0`; moderate.
- [React Router: Arbitrary Constructor Injection via deserializeErrors() in React Router SSR Hydration](https://github.com/advisories/GHSA-337j-9hxr-rhxg); affected range `>=6.4.0 <7.18.0`; moderate.
- [React Router: Unauthenticated Denial of Service via Inefficient Route Matching](https://github.com/advisories/GHSA-chx6-hx7r-mcp5); affected range `>=7.0.0 <7.18.0`; high.
- [React Router's same-origin redirect with path starting // causes open redirect via protocol-relative URL reinterpretation](https://github.com/advisories/GHSA-2j2x-hqr9-3h42); affected range `>=7.0.0 <7.14.1`; moderate.
- [React Router: RSC Mode CSRF Bypass Allows Action Execution Before 400 Response](https://github.com/advisories/GHSA-qwww-vcr4-c8h2); affected range `>=7.12.0 <7.18.2`; high.

### Frontend react-router-dom

- Inherited from react-router.

### Frontend source-map-js

- [source-map-js allows event-loop denial of service through indexed source-map section offsets](https://github.com/advisories/GHSA-68fv-2mgg-jv7q); affected range `>=1.0.0 <1.2.2`; high.

### Frontend vite

- [launch-editor: NTLMv2 hash disclosure via UNC path handling on Windows](https://github.com/advisories/GHSA-v6wh-96g9-6wx3); affected range `>=8.0.0 <=8.0.15`; moderate.
- [vite: `server.fs.deny` bypass on Windows alternate paths](https://github.com/advisories/GHSA-fx2h-pf6j-xcff); affected range `>=8.0.0 <=8.0.15`; high.

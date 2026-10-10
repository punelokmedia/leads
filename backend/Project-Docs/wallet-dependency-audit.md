> Historical pre-remediation findings. See [current remediation results](wallet-security-remediation.md) and the refreshed raw audit JSON files.

# Backend dependency audit ? 10 October 2026

Command: `npm audit --omit=dev --json`. Result: 22 affected package entries (2 critical, 12 high, 8 moderate), not 22 independent attack paths. Parent packages can inherit the same advisory from vulnerable dependencies. npm reports fixAvailable=false for every entry in this snapshot; this means no automatic fix was offered, not that mitigation or replacement is impossible. Exploitability has not been established.

## axios ? high

Installed versions: 1.15.0. Transitive dependency. Affected range: ``.

- **moderate**: [Axios: Authentication Bypass via Prototype Pollution Gadget in `validateStatus` Merge Strategy](https://github.com/advisories/GHSA-w9j2-pvgh-6h63)
- **high**: [Axios: Incomplete Fix for CVE-2025-62718 — NO_PROXY Protection Bypassed via RFC 1122 Loopback Subnet (127.0.0.0/8) in Axios 1.15.0](https://github.com/advisories/GHSA-pmwg-cvhr-8vh7)
- **moderate**: [Axios: Invisible JSON Response Tampering via Prototype Pollution Gadget in `parseReviver`](https://github.com/advisories/GHSA-3w6x-2g7m-8v23)
- **low**: [Axios: Null Byte Injection via Reverse-Encoding in AxiosURLSearchParams](https://github.com/advisories/GHSA-xhjh-pmcv-23jw)
- **moderate**: [Axios: CRLF Injection in multipart/form-data body via unsanitized blob.type in formDataToStream](https://github.com/advisories/GHSA-445q-vr5w-6q77)
- **moderate**: [Axios: no_proxy bypass via IP alias allows SSRF](https://github.com/advisories/GHSA-m7pr-hjqh-92cm)
- **moderate**: [Axios' HTTP adapter-streamed uploads bypass maxBodyLength when maxRedirects: 0](https://github.com/advisories/GHSA-5c9x-8gcm-mpgx)
- **moderate**: [Axios: HTTP adapter streamed responses bypass maxContentLength](https://github.com/advisories/GHSA-vf2m-468p-8v99)
- **high**: [Axios: Prototype Pollution Gadgets - Response Tampering, Data Exfiltration, and Request Hijacking](https://github.com/advisories/GHSA-pf86-5x62-jrwf)
- **high**: [Axios: Header Injection via Prototype Pollution](https://github.com/advisories/GHSA-6chq-wfr3-2hj9)
- **moderate**: [Axios: XSRF Token Cross-Origin Leakage via Prototype Pollution Gadget in `withXSRFToken` Boolean Coercion](https://github.com/advisories/GHSA-xx6v-rp6x-q39c)
- **high**: [Axios has prototype pollution read-side gadgets in HTTP adapter that allow credential injection and request hijacking](https://github.com/advisories/GHSA-q8qp-cvcw-x6jj)
- **moderate**: [Axios: unbounded recursion in toFormData causes DoS via deeply nested request data](https://github.com/advisories/GHSA-62hf-57xw-28j9)
- **high**: [Axios: Regular Expression Denial of Service (ReDoS) via Cookie Name Injection](https://github.com/advisories/GHSA-hfxv-24rg-xrqf)
- **high**: [Allocation of Resources Without Limits or Throttling in Axios](https://github.com/advisories/GHSA-777c-7fjr-54vf)
- **high**: [Axios: Proxy-Authorization Credential Leak to Origin Server Across HTTP-to-HTTPS Redirect in Axios Node.js HTTP Adapter](https://github.com/advisories/GHSA-p92q-9vqr-4j8v)
- **high**: [Axios: Proxy-Authorization header leaks to redirect target when proxy is re-evaluated to direct connection](https://github.com/advisories/GHSA-j5f8-grm9-p9fc)
- **high**: [axios Vulnerable to Credential Theft and Response Hijacking via Prototype Pollution Gadget in Config Merge](https://github.com/advisories/GHSA-3g43-6gmg-66jw)
- **high**: [axios Vulnerable to Full Man-in-the-Middle via Prototype Pollution Gadget in `config.proxy`](https://github.com/advisories/GHSA-35jp-ww65-95wh)
- **moderate**: [axios has DoS & Header Injection via Prototype Pollution Read-Side Gadgets in axios merge functions](https://github.com/advisories/GHSA-898c-q2cr-xwhg)
- **high**: [axios's shouldBypassProxy does not recognize IPv4-mapped IPv6 addresses, allowing NO_PROXY bypass (incomplete fix for CVE-2025-62718)](https://github.com/advisories/GHSA-pjwm-pj3p-43mv)
- **moderate**: [Axios: Prototype pollution gadgets can alter axios request construction](https://github.com/advisories/GHSA-mmx7-hfxf-jppx)
- **moderate**: [Axios: Deep formToJSON Key Recursion Can Cause Denial of Service](https://github.com/advisories/GHSA-pmv8-rq9r-6j72)
- **moderate**: [Axios: HTTP/2 streamed uploads bypass `maxBodyLength`](https://github.com/advisories/GHSA-mwf2-3pr3-8698)
- **moderate**: [Axios: Nested axios option objects can consume polluted prototype values](https://github.com/advisories/GHSA-7q8q-rj6j-mhjq)
- **moderate**: [Axios: Fetch adapter `ReadableStream` uploads bypass `maxBodyLength`](https://github.com/advisories/GHSA-jqh4-m9w3-8hp9)
- **moderate**: [Axios: NO_PROXY bypass for 0.0.0.0 local addresses in axios](https://github.com/advisories/GHSA-f4gw-2p7v-4548)
- **moderate**: [Axios: Excessive recursion in formDataToJSON can cause denial of service](https://github.com/advisories/GHSA-42h9-826w-cgv3)
- **moderate**: [Axios: Prototype pollution gadget in fetch adapter can alter outbound requests](https://github.com/advisories/GHSA-vh66-26gq-q6x8)
- **moderate**: [Axios: Prototype-Pollution Gadget in the Default Instance Allows Inherited Object.prototype.method to Override HTTP Method](https://github.com/advisories/GHSA-9fr6-4gfg-395g)
- **high**: [Axios: ReDoS (O(N²)) in shouldBypassProxy host normalization, reachable via untrusted redirect Location](https://github.com/advisories/GHSA-mghh-pgcx-3jjj)
- **high**: [Axios: HTTP/2 adapter bypasses configured DNS lookup and proxy controls](https://github.com/advisories/GHSA-3pq3-5fj3-cg6v)
- **high**: [Axios: Denial of Service via Unhandled 'error' Event in HTTP/2 ClientHttp2Session Initialization](https://github.com/advisories/GHSA-542g-h47m-68v8)
- **moderate**: [Axios: Header Injection via Inherited headers After Minimal Interceptor](https://github.com/advisories/GHSA-j8rh-479h-cp32)
- **moderate**: [Axios: Fetch Adapter Header Injection via Inherited FormData getHeaders](https://github.com/advisories/GHSA-4hqw-qxg8-jxx2)
- **moderate**: [Axios: CIDR-form NO_PROXY entries are ignored, causing proxy exclusion bypass for internal IP ranges](https://github.com/advisories/GHSA-44g4-m2mj-wpvx)
- Inherits findings through **follow-redirects**.
- Inherits findings through **form-data**.

## body-parser ? moderate

Installed versions: 2.2.2. Transitive dependency. Affected range: ``.

- **low**: [body-parser vulnerable to denial of service when invalid limit value silently disables size enforcement](https://github.com/advisories/GHSA-v422-hmwv-36x6)
- Inherits findings through **qs**.

## brace-expansion ? high

Installed versions: 5.0.5, 1.1.14, 2.1.0. Transitive dependency. Affected range: ``.

- **moderate**: [brace-expansion: Large numeric range defeats documented `max` DoS protection](https://github.com/advisories/GHSA-jxxr-4gwj-5jf2)
- **high**: [brace-expansion: DoS via exponential-time expansion of consecutive non-expanding {} groups](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp)
- **high**: [brace-expansion: DoS via unbounded expansion length causing an out-of-memory process crash](https://github.com/advisories/GHSA-mh99-v99m-4gvg)
- **high**: [brace-expansion: DoS via unbounded intermediate arrays, bypassing the CVE-2026-14257 mitigation](https://github.com/advisories/GHSA-rgw5-rvv9-x895)
- **moderate**: [brace-expansion: Quadratic-time expansion of the `{a},b}` rewrite causes CPU denial of service](https://github.com/advisories/GHSA-q2hr-2g5m-vwhr)
- **high**: [brace-expansion: DoS via uncontrolled recursion on nested brace groups causing stack exhaustion](https://github.com/advisories/GHSA-qhr7-859c-m2p7)
- **high**: [brace-expansion: DoS via uncontrolled recursion in parseCommaParts causing stack exhaustion](https://github.com/advisories/GHSA-6j4f-fj2g-mc7p)

## braces ? high

Installed versions: 3.0.3. Transitive dependency. Affected range: ``.

- **high**: [braces vulnerable to stack-exhaustion denial of service through deeply nested patterns](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm)

## chokidar ? high

Installed versions: 3.6.0. Transitive dependency. Affected range: ``.

- Inherits findings through **braces**.

## exceljs ? high

Installed versions: 4.4.0. Direct dependency. Affected range: ``.

- Inherits findings through **tmp**.
- Inherits findings through **uuid**.

## express ? critical

Installed versions: 5.2.1. Direct dependency. Affected range: ``.

- Inherits findings through **body-parser**.
- Inherits findings through **proxy-addr**.
- Inherits findings through **qs**.

## follow-redirects ? moderate

Installed versions: 1.15.11. Transitive dependency. Affected range: ``.

- **moderate**: [follow-redirects leaks Custom Authentication Headers to Cross-Domain Redirect Targets](https://github.com/advisories/GHSA-r4q5-vmmm-2653)

## form-data ? high

Installed versions: 4.0.5. Transitive dependency. Affected range: ``.

- **high**: [form-data: CRLF injection in form-data via unescaped multipart field names and filenames](https://github.com/advisories/GHSA-hmw2-7cc7-3qxx)

## minimatch ? moderate

Installed versions: 10.2.5. Transitive dependency. Affected range: ``.

- Inherits findings through **brace-expansion**.

## mongoose ? moderate

Installed versions: 9.4.1. Direct dependency. Affected range: ``.

- **moderate**: [Mongoose: Prototype pollution in mongoose update casting via __proto__-prefixed dotted path (Schema._getSchema/path getter)](https://github.com/advisories/GHSA-664h-wqgq-64gw)

## multer ? high

Installed versions: 2.1.1. Direct dependency. Affected range: ``.

- **high**: [Multer vulnerable to Denial of Service via deeply nested field names](https://github.com/advisories/GHSA-72gw-mp4g-v24j)
- **moderate**: [Multer vulnerable to Denial of Service via incomplete cleanup of aborted uploads](https://github.com/advisories/GHSA-3p4h-7m6x-2hcm)
- **high**: [multer vulnerable to Denial of Service via crafted multipart field names](https://github.com/advisories/GHSA-wc9g-mqfw-jrwm)
- **low**: [multer vulnerable to file size limit bypass via async fileFilter race condition](https://github.com/advisories/GHSA-qvfw-j98x-7q72)
- **high**: [multer vulnerable to Denial of Service via oversized array index in field names](https://github.com/advisories/GHSA-535w-7cp7-47q4)

## nodemailer ? high

Installed versions: 8.0.5. Direct dependency. Affected range: ``.

- **moderate**: [Nodemailer: CRLF injection in Nodemailer List-* header comments allows arbitrary message header injection](https://github.com/advisories/GHSA-268h-hp4c-crq3)
- **moderate**: [Nodemailer jsonTransport bypasses disableFileAccess and disableUrlAccess during message normalization](https://github.com/advisories/GHSA-wqvq-jvpq-h66f)
- **high**: [Nodemailer: Message-level raw option bypasses disableFileAccess/disableUrlAccess, enabling arbitrary file read and full-response SSRF in the delivered message](https://github.com/advisories/GHSA-p6gq-j5cr-w38f)
- **moderate**: [Nodemailer: resolveContent() on a MailMessage bypasses disableFileAccess/disableUrlAccess when called with the legacy signature](https://github.com/advisories/GHSA-8m3c-c648-2xjj)
- **moderate**: [Nodemailer: IDN/Punycode domain allow-list bypass leads to email delivery to an attacker-controlled domain](https://github.com/advisories/GHSA-wmmp-3585-3rmp)
- **high**: [Nodemailer: Quadratic (O(n²)) time complexity in addressparser allows remote denial of service via a crafted address list](https://github.com/advisories/GHSA-2x7j-588g-ccc2)
- **moderate**: [Nodemailer: Recipient-domain validation bypass via RFC 5322 comment mis-parsing leads to email delivery to an attacker-controlled domain](https://github.com/advisories/GHSA-cc9r-2j5m-2m83)
- **moderate**: [Nodemailer: Process-global DNS cache reuses TLS `servername` across transports, enabling cross-tenant SMTP credential disclosure](https://github.com/advisories/GHSA-6vj9-mwq6-2f5v)
- **moderate**: [Nodemailer: Nested structured recipient arrays bypass the parser depth limit and cause stack exhaustion DoS](https://github.com/advisories/GHSA-8vvx-rff5-p5rq)
- **high**: [Nodemailer: Quadratic backtracking in the addressparser free-text fallback allows remote denial of service](https://github.com/advisories/GHSA-v53p-9fqp-m79j)
- **high**: [Nodemailer: Improper TLS Certificate Validation in OAuth2 Token Fetch Enables Credential Interception](https://github.com/advisories/GHSA-r7g4-qg5f-qqm2)

## nodemon ? high

Installed versions: 3.1.14. Direct dependency. Affected range: ``.

- Inherits findings through **chokidar**.
- Inherits findings through **minimatch**.

## proxy-addr ? critical

Installed versions: 2.0.7. Transitive dependency. Affected range: ``.

- **critical**: [proxy-addr vulnerable to IP spoofing via IPv4-mapped IPv6 trust subnet](https://github.com/advisories/GHSA-jqcg-44mw-7w3h)

## qs ? moderate

Installed versions: 6.15.1. Transitive dependency. Affected range: ``.

- **moderate**: [qs has a remotely triggerable DoS: qs.stringify crashes with TypeError on null/undefined entries in comma-format arrays when encodeValuesOnly is set](https://github.com/advisories/GHSA-q8mj-m7cp-5q26)
- **moderate**: [qs array-limit bypass via bracket-key comma parsing](https://github.com/advisories/GHSA-x5fp-wj9c-mxmx)
- **moderate**: [qs: Denial of Service via Attacker Controlled isBuffer](https://github.com/advisories/GHSA-4mjr-xmp4-gh2g)

## razorpay ? high

Installed versions: 2.9.6. Direct dependency. Affected range: ``.

- Inherits findings through **axios**.

## resend ? moderate

Installed versions: 6.10.0. Direct dependency. Affected range: ``.

- Inherits findings through **svix**.

## svix ? moderate

Installed versions: 1.88.0. Transitive dependency. Affected range: ``.

- Inherits findings through **uuid**.

## tmp ? high

Installed versions: 0.2.5. Transitive dependency. Affected range: ``.

- **high**: [tmp has Path Traversal via unsanitized prefix/postfix that enables directory escape](https://github.com/advisories/GHSA-ph9p-34f9-6g65)

## uuid ? moderate

Installed versions: 8.3.2, 10.0.0. Transitive dependency. Affected range: ``.

- **moderate**: [uuid: Missing buffer bounds check in v3/v5/v6 when buf is provided](https://github.com/advisories/GHSA-w5hq-g745-h8pq)

## xlsx ? high

Installed versions: 0.18.5. Direct dependency. Affected range: ``.

- **high**: [Prototype Pollution in sheetJS](https://github.com/advisories/GHSA-4r6h-8v6p-xvw6)
- **high**: [SheetJS Regular Expression Denial of Service (ReDoS)](https://github.com/advisories/GHSA-5pgg-2g8v-p4x9)


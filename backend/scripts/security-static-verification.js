import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
const root = path.resolve('..');
const evidence = path.resolve('security-reports/evidence');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const locate = (file, expression) => read(file).split(/\r?\n/).flatMap((line, index) => expression.test(line) ? [{ file, line: index + 1 }] : []);
const findings = {
  urlBearerToken: locate('backend/src/Controllers/auth.controller.js', /searchParams\.set\("token"/),
  browserTokenStorage: ['frontend/apps/user-web/src/features/auth/pages/MobileAuthDrawerPage.tsx', 'frontend/apps/admin-web/src/features/auth/context/AdminAuthContext.tsx'].flatMap(file => locate(file, /localStorage\.setItem/)),
  mobileOtpLogging: locate('frontend/mobile/user_app/lib/features/auth/presentation/screens/verify_number_screen.dart', /print\(.*otpCode/),
  mobileSecureStorage: locate('frontend/mobile/user_app/lib/features/auth/shared/auth_providers.dart', /FlutterSecureStorage|_storage\.delete/),
  userWebLogout: locate('frontend/apps/user-web/src/components/layout/PublicHeader.tsx', /removeItem\('user_token'/),
  httpFallback: locate('frontend/mobile/user_app/lib/core/network/dio_provider.dart', /http:\/\/10\.0\.2\.2/),
  bundledMobileEnv: locate('frontend/mobile/user_app/pubspec.yaml', /- \.env.local/),
  suspectedHardcodedSecrets: [],
  trackedEnvFiles: [],
  environment: {},
};
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (['node_modules', '.git', '.dart_tool', '.npm-cache', '.tool-profile', 'build', 'dist', 'security-reports', 'test', 'tests', 'Project-Docs'].includes(entry.name)) continue;
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (/\.(js|ts|tsx|dart|kts|yaml|yml)$/.test(entry.name)) {
      fs.readFileSync(file, 'utf8').split(/\r?\n/).forEach((line, index) => {
        if (/-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|mongodb\+srv:\/\/[^\s:@]+:[^\s@]+@/.test(line)) findings.suspectedHardcodedSecrets.push({ file: path.relative(root, file), line: index + 1 });
      });
    }
  }
}
walk(path.join(root, 'backend/src')); walk(path.join(root, 'frontend/apps')); walk(path.join(root, 'frontend/mobile/user_app/lib'));
const tracked = execFileSync('git', ['ls-files'], { cwd: root, encoding: 'utf8' }).split(/\r?\n/);
findings.trackedEnvFiles = tracked.filter(file => /(^|\/)\.env($|\.)/.test(file) && !/example|sample/.test(file));
for (const file of ['backend/.env', 'frontend/mobile/user_app/.env.local']) {
  if (!fs.existsSync(path.join(root, file))) continue;
  const env = Object.fromEntries(read(file).split(/\r?\n/).filter(line => /^[A-Z_][A-Z0-9_]*\s*=/.test(line)).map(line => { const index = line.indexOf('='); return [line.slice(0, index).trim(), line.slice(index + 1).trim().replace(/^['"]|['"]$/g, '')]; }));
  // Values intentionally never written to evidence; only names/presence/scheme.
  findings.environment[file] = { keyNames: Object.keys(env), httpsBaseUrl: env.BASE_URL ? env.BASE_URL.startsWith('https://') : null };
}
fs.mkdirSync(evidence, { recursive: true });
fs.writeFileSync(path.join(evidence, 'static-checks.json'), JSON.stringify(findings, null, 2));
console.log('Static evidence written without credential values. Narrow pattern scan does not establish that no secrets exist.');

import { readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const sourceRoot = fileURLToPath(new URL('../src/', import.meta.url));
function javascriptFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? javascriptFiles(path) : entry.name.endsWith('.js') ? [path] : [];
  });
}

const files = [...javascriptFiles(sourceRoot), fileURLToPath(import.meta.url)];
for (const file of files) {
  const result = spawnSync(process.execPath, ['--check', file], { stdio: 'inherit' });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  if (result.status !== 0) process.exit(result.status || 1);
}
console.log(`Backend build check passed: ${files.length} JavaScript files. Start with npm start.`);

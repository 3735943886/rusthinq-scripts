// Prints the hex fixtures of an upstream rethink test file, fully assembled (some are built
// from string pieces). Evaluates the file's top-level constants, so run it only on a rethink
// checkout you trust:
//   node tools/rethink_fixtures.mjs <rethink>/tests/cloud/devices/<modelId>.test.ts
import fs from 'node:fs'
const src = fs.readFileSync(process.argv[2], 'utf8')
const top = src.split(/\n(?=describe\(|function |test\()/)[0]
  .split('\n').filter(l => !l.startsWith('import ')).join('\n')
  .replace(/:\s*Metadata\b/g, '').replace(/ as const/g, '').replace(/^const (\w+)\s*:\s*[^=]+=/gm, 'const $1 =')
const names = [...top.matchAll(/^const (\w+)/gm)].map(m => m[1])
const body = `const buf = s => s; const hex = s => s; ${top}\nreturn {${names.join(',')}}`
const values = new Function(body)()
for (const [k, v] of Object.entries(values)) if (typeof v === 'string' && /^[0-9A-Fa-f]{6,}$/.test(v)) console.log(k, v.toUpperCase())

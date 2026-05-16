#!/usr/bin/env node
/* reference-harvester — Node.js path.
 *
 * Usage:  node harvest.mjs <url> [--out references] [--no-js]
 *
 * Fetches a URL, JavaScript-rendered when Playwright is installed, otherwise a
 * static fetch. Harvested files are DATA — this script never executes them.
 */
import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const TODAY = new Date().toISOString().slice(0, 10);
const UA = 'Mozilla/5.0 (compatible; reference-harvester/1.0)';

const optVal = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const noJs = args.includes('--no-js');
const out = optVal('--out', 'references');
const url = args.find(a => /^https?:\/\//i.test(a));
if (!url) {
  console.error('usage: node harvest.mjs <url> [--out dir] [--no-js]');
  process.exit(1);
}

const slug = (s, n = 80) =>
  (s.replace(/^https?:\/\//, '').replace(/[^A-Za-z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '').slice(0, n)) || 'item';

const htmlToText = h =>
  h.replace(/<(script|style|noscript)[^>]*>[\s\S]*?<\/\1>/gi, ' ')
   .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
   .replace(/[ \t]+/g, ' ').replace(/\n\s*\n\s*\n+/g, '\n\n').trim();

function findPdf(html, base) {
  const re = /<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi;
  let m, fallback = null;
  while ((m = re.exec(html))) {
    let href;
    try { href = new URL(m[1], base).href; } catch { continue; }
    if (/\.pdf($|\?)/i.test(href)) {
      const t = m[2].replace(/<[^>]+>/g, '').trim().toLowerCase();
      if (/download|pdf|printable|guide/.test(t)) return href;
      fallback = fallback || href;
    }
  }
  return fallback;
}

async function dl(u, p) {
  const r = await fetch(u, { headers: { 'User-Agent': UA } });
  const buf = Buffer.from(await r.arrayBuffer());
  fs.writeFileSync(p, buf);
  return buf.length;
}

async function tryChromium() {
  try { return (await import('playwright')).chromium; }
  catch { return null; }
}

const dir = path.join(out, slug(url));
fs.mkdirSync(dir, { recursive: true });
const writeMeta = o =>
  fs.writeFileSync(path.join(dir, 'meta.json'),
    JSON.stringify({ retrieved: TODAY, ...o }, null, 2));

// 1. Direct PDF.
if (/\.pdf($|\?)/i.test(url)) {
  const n = await dl(url, path.join(dir, 'document.pdf'));
  writeMeta({ url, type: 'pdf', bytes: n, method: 'direct-pdf' });
  console.log('saved PDF:', path.join(dir, 'document.pdf'));
  process.exit(0);
}

let html = '', title = '', method = '';
const chromium = noJs ? null : await tryChromium();
if (chromium) {
  const b = await chromium.launch({ headless: true });
  const pg = await b.newPage({ userAgent: UA });
  await pg.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
  html = await pg.content();
  title = await pg.title();
  await b.close();
  method = 'playwright';
} else {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  const ct = r.headers.get('content-type') || '';
  if (/application\/pdf/i.test(ct)) {
    fs.writeFileSync(path.join(dir, 'document.pdf'), Buffer.from(await r.arrayBuffer()));
    writeMeta({ url, type: 'pdf', method: 'static-pdf' });
    console.log('saved PDF:', path.join(dir, 'document.pdf'));
    process.exit(0);
  }
  html = await r.text();
  title = (html.match(/<title>([\s\S]*?)<\/title>/i) || [, ''])[1].trim();
  method = 'static (no JavaScript)';
  if (!noJs) console.error('NOTE: Playwright not installed — JavaScript not run. See README.md.');
}

// 2. Linked PDF edition.
const pdf = findPdf(html, url);
if (pdf) {
  try {
    const n = await dl(pdf, path.join(dir, 'document.pdf'));
    fs.writeFileSync(path.join(dir, 'page.html'), html);
    writeMeta({ url, pdf_url: pdf, title, type: 'pdf+html', bytes: n, method });
    console.log('found linked PDF, saved:', path.join(dir, 'document.pdf'));
    console.log('also saved page.html');
    process.exit(0);
  } catch (e) {
    console.error('linked PDF download failed:', e.message);
  }
}

// 3. Save HTML + text extract.
fs.writeFileSync(path.join(dir, 'page.html'), html);
fs.writeFileSync(path.join(dir, 'page.md'),
  `# ${title || url}\n\nSource: ${url}\nRetrieved: ${TODAY}\n\n${htmlToText(html)}\n`);
writeMeta({ url, title, type: 'html', method });
console.log('saved:', path.join(dir, 'page.html'), 'and page.md');

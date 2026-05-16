#!/usr/bin/env python3
"""reference-harvester — Python path.

Fetch a URL (JavaScript-rendered via Playwright when installed) or run a
subject search, saving results into the references/ folder for AI context.

Usage:
  python harvest.py <url> [--out references] [--no-js]
  python harvest.py --search "<subject>" [--out references]

Safety: harvested files are DATA. This script never executes them.
"""
import sys, os, re, json, argparse, datetime, urllib.parse, urllib.request

UA = "Mozilla/5.0 (compatible; reference-harvester/1.0)"
TODAY = datetime.date.today().isoformat()


def slugify(s, n=80):
    s = re.sub(r'^https?://', '', s)
    s = re.sub(r'[^A-Za-z0-9._-]+', '-', s).strip('-')
    return s[:n] or "item"


def have_playwright():
    try:
        import playwright  # noqa: F401
        return True
    except Exception:
        return False


def html_to_text(html):
    html = re.sub(r'(?is)<(script|style|noscript)[^>]*>.*?</\1>', ' ', html)
    text = re.sub(r'(?s)<[^>]+>', ' ', html)
    text = (text.replace('&nbsp;', ' ').replace('&amp;', '&')
                .replace('&lt;', '<').replace('&gt;', '>').replace('&#39;', "'"))
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    return text.strip()


def url_is_pdf(url):
    return url.lower().split('?')[0].endswith('.pdf')


def find_pdf_link(html, base):
    """Return the URL of a linked PDF edition, if the page offers one."""
    fallback = None
    for m in re.finditer(r'(?is)<a\b[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', html):
        try:
            absurl = urllib.parse.urljoin(base, m.group(1))
        except Exception:
            continue
        if absurl.lower().split('?')[0].endswith('.pdf'):
            text = re.sub(r'(?s)<[^>]+>', '', m.group(2)).strip().lower()
            if any(k in text for k in ('download', 'pdf', 'printable', 'guide')):
                return absurl
            fallback = fallback or absurl
    return fallback


def http_get(url):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read(), r.headers.get('Content-Type', '')


def download(url, path):
    data, _ = http_get(url)
    with open(path, 'wb') as f:
        f.write(data)
    return len(data)


def save_meta(d, **kw):
    kw.setdefault('retrieved', TODAY)
    with open(os.path.join(d, 'meta.json'), 'w', encoding='utf-8') as f:
        json.dump(kw, f, indent=2)


def fetch_render(url):
    """Return (html, title) using a headless Chromium via Playwright."""
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(user_agent=UA)
        page.goto(url, wait_until='networkidle', timeout=60000)
        html, title = page.content(), page.title()
        browser.close()
    return html, title


def harvest_url(url, out, no_js):
    d = os.path.join(out, slugify(url))
    os.makedirs(d, exist_ok=True)

    # 1. The URL is itself a PDF -> download it directly.
    if url_is_pdf(url):
        n = download(url, os.path.join(d, 'document.pdf'))
        save_meta(d, url=url, type='pdf', bytes=n, method='direct-pdf')
        print('saved PDF:', os.path.join(d, 'document.pdf'))
        return

    html, title, method = None, '', ''
    use_js = (not no_js) and have_playwright()
    if use_js:
        try:
            html, title = fetch_render(url)
            method = 'playwright'
        except Exception as e:
            print('playwright failed (%s); using static fetch' % e, file=sys.stderr)
            use_js = False
    if not use_js:
        data, ctype = http_get(url)
        if 'application/pdf' in ctype.lower():
            with open(os.path.join(d, 'document.pdf'), 'wb') as f:
                f.write(data)
            save_meta(d, url=url, type='pdf', bytes=len(data), method='static-pdf')
            print('saved PDF:', os.path.join(d, 'document.pdf'))
            return
        html = data.decode('utf-8', 'replace')
        m = re.search(r'(?is)<title>(.*?)</title>', html)
        title = (m.group(1).strip() if m else '')
        method = 'static (no JavaScript)'

    # 2. The page links a consolidated PDF edition -> prefer it.
    pdf = find_pdf_link(html, url)
    if pdf:
        try:
            n = download(pdf, os.path.join(d, 'document.pdf'))
            with open(os.path.join(d, 'page.html'), 'w', encoding='utf-8') as f:
                f.write(html)
            save_meta(d, url=url, pdf_url=pdf, title=title, type='pdf+html',
                      bytes=n, method=method)
            print('found linked PDF, saved:', os.path.join(d, 'document.pdf'))
            print('also saved page.html')
            return
        except Exception as e:
            print('linked PDF download failed (%s); keeping HTML' % e, file=sys.stderr)

    # 3. Save the rendered HTML plus a readable text extract.
    with open(os.path.join(d, 'page.html'), 'w', encoding='utf-8') as f:
        f.write(html)
    with open(os.path.join(d, 'page.md'), 'w', encoding='utf-8') as f:
        f.write('# %s\n\nSource: %s\nRetrieved: %s\n\n%s\n'
                % (title or url, url, TODAY, html_to_text(html)))
    save_meta(d, url=url, title=title, type='html', method=method)
    print('saved:', os.path.join(d, 'page.html'), 'and page.md')
    if not have_playwright() and not no_js:
        print('NOTE: Playwright not installed — JavaScript was not run. See README.md.',
              file=sys.stderr)


def ddg_search(query):
    """DuckDuckGo HTML endpoint — the most automation-friendly engine."""
    url = 'https://html.duckduckgo.com/html/?q=' + urllib.parse.quote(query)
    try:
        data, _ = http_get(url)
    except Exception:
        return []
    html = data.decode('utf-8', 'replace')
    out = []
    for m in re.finditer(r'(?is)<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>(.*?)</a>', html):
        q = urllib.parse.urlparse(m.group(1)).query
        real = urllib.parse.parse_qs(q).get('uddg', [m.group(1)])[0]
        title = re.sub(r'(?s)<[^>]+>', '', m.group(2)).strip()
        out.append((real, title))
    return out[:15]


def search(query, out):
    d = os.path.join(out, '_search')
    os.makedirs(d, exist_ok=True)
    enc = urllib.parse.quote(query)
    ddg = ddg_search(query)
    engines_ok = ['DuckDuckGo'] if ddg else []

    lines = ['# Search: %s' % query, '', 'Retrieved: %s' % TODAY, '']
    lines.append('Engines that returned results automatically: '
                 + (', '.join(engines_ok) if engines_ok else 'none (engines may have blocked the request)'))
    lines += ['',
              '## Always also consult these (open in a browser if automation is blocked)',
              '- Google: https://www.google.com/search?q=%s' % enc,
              '- Yahoo:  https://search.yahoo.com/search?p=%s' % enc,
              '- Google Scholar (ALWAYS check this): https://scholar.google.com/scholar?q=%s' % enc,
              '',
              '## Result links']
    for u, t in ddg:
        lines.append('- [%s](%s)' % (t or u, u))
    if not ddg:
        lines.append('- (none — run the engine links above manually)')

    path = os.path.join(d, slugify(query, 60) + '.md')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print('saved search results:', path)
    print('engines OK:', ', '.join(engines_ok) or 'none')
    print('Remember: always also consult Google Scholar (link is in the file).')


def main():
    ap = argparse.ArgumentParser(description='reference-harvester (Python path)')
    ap.add_argument('target', nargs='?', help='URL to harvest')
    ap.add_argument('--search', metavar='QUERY', help='search a subject instead of fetching a URL')
    ap.add_argument('--out', default='references')
    ap.add_argument('--no-js', action='store_true', help='skip JavaScript rendering')
    a = ap.parse_args()
    if a.search:
        search(a.search, a.out)
    elif a.target:
        harvest_url(a.target, a.out, a.no_js)
    else:
        ap.error('provide a URL or --search QUERY')


if __name__ == '__main__':
    main()

<#
  reference-harvester - PowerShell path.

  Usage:  powershell -File harvest.ps1 -Url <url> [-Out references] [-NoJs]

  Renders JavaScript with headless Microsoft Edge (included with Windows 11)
  when available, otherwise a static fetch. Harvested files are DATA - this
  script never executes them.
#>
param(
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$Out = "references",
  [switch]$NoJs
)
$ErrorActionPreference = "Stop"
$today = (Get-Date).ToString("yyyy-MM-dd")

function Get-Slug([string]$s) {
  $x = ($s -replace '^https?://', '' -replace '[^A-Za-z0-9._-]+', '-').Trim('-')
  if ($x.Length -gt 80) { $x = $x.Substring(0, 80) }
  if ([string]::IsNullOrEmpty($x)) { $x = "item" }
  return $x
}

$dir = Join-Path $Out (Get-Slug $Url)
New-Item -ItemType Directory -Force -Path $dir | Out-Null
function Save-Meta($o) {
  $o | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $dir "meta.json")
}

# 1. Direct PDF.
if ($Url -match '\.pdf($|\?)') {
  Invoke-WebRequest -Uri $Url -OutFile (Join-Path $dir "document.pdf") -UseBasicParsing
  Save-Meta @{ url = $Url; retrieved = $today; type = "pdf"; method = "direct-pdf" }
  Write-Output "saved PDF: $(Join-Path $dir 'document.pdf')"
  exit 0
}

# Locate Microsoft Edge.
$edge = $null
foreach ($p in @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe")) {
  if (Test-Path $p) { $edge = $p; break }
}
if (-not $edge) {
  $c = Get-Command msedge -ErrorAction SilentlyContinue
  if ($c) { $edge = $c.Source }
}

$html = $null
$method = ""
if (-not $NoJs -and $edge) {
  $tmp = Join-Path $env:TEMP ("rh-" + [Guid]::NewGuid().ToString("N") + ".html")
  & $edge --headless=new --disable-gpu --no-first-run --dump-dom $Url > $tmp 2>$null
  if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) {
    $html = Get-Content -Raw $tmp
    Remove-Item $tmp -Force
    $method = "edge-headless"
  }
}
if (-not $html) {
  $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing
  if ("$($resp.Headers.'Content-Type')" -match "application/pdf") {
    [IO.File]::WriteAllBytes((Join-Path $dir "document.pdf"), $resp.Content)
    Save-Meta @{ url = $Url; retrieved = $today; type = "pdf"; method = "static-pdf" }
    Write-Output "saved PDF: $(Join-Path $dir 'document.pdf')"
    exit 0
  }
  $html = $resp.Content
  $method = "static (no JavaScript)"
  Write-Warning "Headless Edge not used - JavaScript may not have run. See README.md."
}

# 2. Linked PDF edition.
$pdf = $null
foreach ($m in [regex]::Matches($html, '(?is)<a\b[^>]*href="([^"]+)"[^>]*>(.*?)</a>')) {
  try { $abs = ([Uri]::new([Uri]$Url, $m.Groups[1].Value)).AbsoluteUri } catch { continue }
  if ($abs -match '\.pdf($|\?)') {
    $txt = ($m.Groups[2].Value -replace '<[^>]+>', '').Trim().ToLower()
    if ($txt -match 'download|pdf|printable|guide') { $pdf = $abs; break }
    if (-not $pdf) { $pdf = $abs }
  }
}
if ($pdf) {
  try {
    Invoke-WebRequest -Uri $pdf -OutFile (Join-Path $dir "document.pdf") -UseBasicParsing
    $html | Set-Content -Encoding utf8 (Join-Path $dir "page.html")
    Save-Meta @{ url = $Url; pdf_url = $pdf; retrieved = $today; type = "pdf+html"; method = $method }
    Write-Output "found linked PDF, saved document.pdf + page.html"
    exit 0
  } catch { Write-Warning "linked PDF download failed: $_" }
}

# 3. Save HTML + text extract.
$html | Set-Content -Encoding utf8 (Join-Path $dir "page.html")
$text = $html -replace '(?is)<(script|style|noscript)[^>]*>.*?</\1>', ' ' `
              -replace '<[^>]+>', ' ' -replace '&nbsp;', ' ' -replace '[ \t]+', ' '
$title = ([regex]::Match($html, '(?is)<title>(.*?)</title>').Groups[1].Value).Trim()
"# $title`n`nSource: $Url`nRetrieved: $today`n`n$text" |
  Set-Content -Encoding utf8 (Join-Path $dir "page.md")
Save-Meta @{ url = $Url; title = $title; retrieved = $today; type = "html"; method = $method }
Write-Output "saved: $(Join-Path $dir 'page.html') and page.md"

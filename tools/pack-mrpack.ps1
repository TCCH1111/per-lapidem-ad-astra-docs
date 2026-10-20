<#
.SYNOPSIS
  把 packwiz 工程打成 Modrinth 格式的 .mrpack（本机无 packwiz CLI 时的等价实现）。

.DESCRIPTION
  mrpack 规范（formatVersion 1）：
    - 根目录 modrinth.index.json：formatVersion / game / versionId / name / files[] / dependencies
    - files[]：path、hashes{sha1,sha256}、env{client,server}、downloads[]（空数组 = 内容在 overrides/ 里）
    - 随包文件放 overrides/<path>
  本脚本从 pack/ 读取：
    - 每个 *.pw.toml → 一个 files[] 条目（URL 来自 [download]，hash 通过 Modrinth API 补 sha1/sha256；无 Modrinth 信息则下载后现算）
    - pack/mods/*.jar（我们的产物）→ overrides/mods/，files[] 里 downloads 为空

.EXAMPLE
  pwsh -File tools/pack-mrpack.ps1
  pwsh -File tools/pack-mrpack.ps1 -OutDir .cache/dist -Version 0.1.1
#>
[CmdletBinding()]
param(
  [string]$PackDir = '',
  [string]$OutDir = '',
  [string]$Version = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $PackDir) { $PackDir = Join-Path $repo 'pack' }
if (-not $OutDir)  { $OutDir = Join-Path $repo '.cache\dist' }
$cachePath = Join-Path $repo '.cache\mrpack-hashes.json'

function Read-Toml([string]$path) {
  $t = @{}
  $section = ''
  foreach ($line in Get-Content -LiteralPath $path) {
    $l = $line.Trim()
    if ($l -match '^\[(.+)\]$') { $section = $Matches[1]; continue }
    if ($l -match '^([A-Za-z0-9_-]+)\s*=\s*"(.*)"$') {
      $k = $Matches[1]; $v = $Matches[2]
      $t[($section + '|' + $k)] = $v
      if (-not $t.ContainsKey($k)) { $t[$k] = $v }
    }
  }
  return $t
}

$pack = Read-Toml (Join-Path $PackDir 'pack.toml')
$name = $pack['name']
$ver  = if ($Version) { $Version } else { $pack['version'] }
$mc   = $pack['minecraft']
$nf   = $pack['neoforge']
if (-not $name -or -not $mc -or -not $nf) { throw "pack.toml 缺少 name/versions" }

$cache = @{}
if (Test-Path $cachePath) {
  $j = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
  foreach ($p in $j.PSObject.Properties) { $cache[$p.Name] = $p.Value }
}

$files = New-Object System.Collections.Generic.List[object]
$overrides = New-Object System.Collections.Generic.List[object]
$needDownload = New-Object System.Collections.Generic.List[object]

"扫描 pack：$PackDir"
foreach ($pw in Get-ChildItem (Join-Path $PackDir 'mods') -Filter '*.pw.toml' | Sort-Object Name) {
  $t = Read-Toml $pw.FullName
  $filename = $t['filename']; $url = $t['url']; $side = $t['side']
  if (-not $filename -or -not $url) { Write-Warning "跳过（缺 filename/url）：$($pw.Name)"; continue }
  $verId = $t['update.modrinth|version']
  $sha1 = $null; $sha256 = $null
  if ($verId) {
    $key = "modrinth:$verId"
    if ($cache.ContainsKey($key)) { $sha1 = $cache[$key].sha1; $sha256 = $cache[$key].sha256 }
    else {
      try {
        $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/$verId" -TimeoutSec 30 -Headers @{ 'User-Agent'='plaa-pack-builder' }
        $f = $v.files | Where-Object { $_.filename -eq $filename } | Select-Object -First 1
        if (-not $f) { $f = $v.files[0] }
        $sha1 = $f.hashes.sha1; $sha256 = $f.hashes.sha256
        $cache[$key] = [pscustomobject]@{ sha1 = $sha1; sha256 = $sha256 }
      } catch { Write-Warning "Modrinth API 失败（$verId）：$($_.Exception.Message)" }
    }
  }
  if (-not $sha1 -or -not $sha256) { $needDownload.Add([pscustomobject]@{ Name = $filename; Url = $url }) }
  $envClient = switch ($side) { 'client' { 'required' } 'server' { 'unsupported' } default { 'required' } }
  $envServer = switch ($side) { 'client' { 'unsupported' } 'server' { 'required' } default { 'required' } }
  $files.Add([pscustomobject]@{
    pw = $pw.Name; path = "mods/$filename"; url = $url; side = $side
    sha1 = $sha1; sha256 = $sha256; client = $envClient; server = $envServer
  })
}

# 需要现算的（非 Modrinth 来源）：下载到 .cache 再算
if ($needDownload.Count -gt 0) {
  $dl = Join-Path $repo '.cache\mrpack-dl'
  New-Item -ItemType Directory -Path $dl -Force | Out-Null
  foreach ($d in $needDownload) {
    $target = Join-Path $dl $d.Name
    if (-not (Test-Path $target)) { Invoke-WebRequest -Uri $d.Url -OutFile $target -TimeoutSec 120 }
    $h1 = (Get-FileHash -LiteralPath $target -Algorithm SHA1).Hash.ToLower()
    $h2 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()
    $row = $files | Where-Object { $_.path -eq "mods/$($d.Name)" } | Select-Object -First 1
    if ($row) { $row.sha1 = $h1; $row.sha256 = $h2 }
    $cache["url:$($d.Url)"] = [pscustomobject]@{ sha1 = $h1; sha256 = $h2 }
  }
}
$cache | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $cachePath -Encoding UTF8

$missing = $files | Where-Object { -not $_.sha1 -or -not $_.sha256 }
if ($missing) { throw ("以下条目缺哈希：" + (($missing | ForEach-Object { $_.path }) -join ', ')) }

# 我们的 jar → overrides
foreach ($jar in Get-ChildItem (Join-Path $PackDir 'mods') -Filter '*.jar' | Sort-Object Name) {
  $overrides.Add($jar)
}

$stage = Join-Path $repo '.cache\mrpack-stage'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $stage 'overrides\mods') -Force | Out-Null
foreach ($jar in $overrides) { Copy-Item $jar.FullName (Join-Path $stage 'overrides\mods') -Force }

$index = [ordered]@{
  formatVersion = 1
  game          = 'minecraft'
  versionId     = $ver
  name          = $name
  files         = @()
  dependencies  = [ordered]@{ minecraft = $mc; neoforge = $nf }
}
$fileList = @()
foreach ($f in $files) {
  $fileList += [ordered]@{
    path      = $f.path
    hashes    = [ordered]@{ sha1 = $f.sha1; sha256 = $f.sha256 }
    env       = [ordered]@{ client = $f.client; server = $f.server }
    downloads = @($f.url)
  }
}
foreach ($jar in $overrides) {
  $fileList += [ordered]@{
    path      = "mods/$($jar.Name)"
    hashes    = [ordered]@{
      sha1   = (Get-FileHash -LiteralPath $jar.FullName -Algorithm SHA1).Hash.ToLower()
      sha256 = (Get-FileHash -LiteralPath $jar.FullName -Algorithm SHA256).Hash.ToLower()
    }
    env       = [ordered]@{ client = 'required'; server = 'required' }
    downloads = @()
  }
}
$index.files = $fileList
$json = $index | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText((Join-Path $stage 'modrinth.index.json'), ($json -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$safe = ($ver -replace '[^\w\.\-\+]', '_')
$out = Join-Path $OutDir ("PerLapidemAdAstra-{0}.mrpack" -f $safe)
if (Test-Path $out) { Remove-Item $out -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $out, [System.IO.Compression.CompressionLevel]::Optimal, $false)

"{0} 个下载条目 + {1} 个随包 jar → {2} ({3:N1} MB)" -f $files.Count, $overrides.Count, $out, ((Get-Item $out).Length / 1MB)

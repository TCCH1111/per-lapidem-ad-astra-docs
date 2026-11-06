<#
.SYNOPSIS
  校验（并可修复）packwiz 工程的自洽性。

.DESCRIPTION
  这个脚本存在的理由很具体：本项目三次手工修过 index.toml 的 CRLF 与随之失效的哈希。
  人记住的事会忘，脚本不会。

  不带 -Fix：只读检查，发现问题以非零码退出。
  带 -Fix：先把文本文件归一化成 LF，再按"排除 index.toml 与 pack.toml"重建 index.toml，
          并同步 pack.toml 的 [index] hash；然后照常检查。

  检查项：
    1. pack/ 每个文件（index.toml / pack.toml 除外）的 sha256 与 index.toml 一致
    2. index.toml 不多不少
    3. pack.toml 的 [index] hash 等于 index.toml 的 sha256
    4. 文本文件不含 CRLF
    5. 每个 *.pw.toml 有 name / filename / side 与 [download]（url + hash-format + hash）

.EXAMPLE
  pwsh -File tools/pack-lint.ps1
  pwsh -File tools/pack-lint.ps1 -Fix
#>
[CmdletBinding()]
param(
    [string]$PackDir = '',
    [switch]$Fix
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $PackDir) { $PackDir = Join-Path $repo 'pack' }
if (-not (Test-Path $PackDir)) { throw "找不到整合包目录: $PackDir" }
# 必须是绝对路径，否则 GetRelativePath 在 Linux 上会返回绝对路径（CI 首次运行即栽在此）
$PackDir = (Resolve-Path -LiteralPath $PackDir).Path.TrimEnd('/', '\')

$enc = New-Object System.Text.UTF8Encoding($false)
$textExt = @('.toml', '.js', '.snbt', '.json', '.md', '.txt', '.cfg')

function Sha256($path) { (Get-FileHash $path -Algorithm SHA256).Hash.ToLower() }
function IsText($file) { $textExt -contains $file.Extension.ToLower() }
function HasCrlf($file) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    for ($i = 0; $i -lt $bytes.Length - 1; $i++) {
        if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10) { return $true }
    }
    return $false
}

function WriteIndex() {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('hash-format = "sha256"' + "`n`n")
    $files = Get-ChildItem $PackDir -Recurse -File |
        Where-Object { $_.Name -ne 'index.toml' -and $_.Name -ne 'pack.toml' } |
        Sort-Object FullName
    foreach ($f in $files) {
        $rel = [System.IO.Path]::GetRelativePath($PackDir, $f.FullName).Replace('\', '/')
        [void]$sb.Append('[[files]]' + "`n")
        [void]$sb.Append('file = "' + $rel + '"' + "`n")
        [void]$sb.Append('hash = "' + (Sha256 $f.FullName) + '"' + "`n`n")
    }
    [System.IO.File]::WriteAllText((Join-Path $PackDir 'index.toml'), $sb.ToString(), $enc)
    return $files.Count
}

function SyncManifestHash() {
    $idx = Join-Path $PackDir 'index.toml'
    $pt = Join-Path $PackDir 'pack.toml'
    $t = [System.IO.File]::ReadAllText($pt)
    $t = [regex]::Replace($t, '(?m)^hash = "[0-9a-f]{64}"$', ('hash = "' + (Sha256 $idx) + '"'))
    [System.IO.File]::WriteAllText($pt, $t, $enc)
}

if ($Fix) {
    $normalised = 0
    foreach ($f in (Get-ChildItem $PackDir -Recurse -File)) {
        if ((IsText $f) -and (HasCrlf $f)) {
            $t = [System.IO.File]::ReadAllText($f.FullName)
            [System.IO.File]::WriteAllText($f.FullName, ($t -replace "`r`n", "`n"), $enc)
            $normalised++
        }
    }
    $count = WriteIndex
    SyncManifestHash
    Write-Output ("修复: 归一化 $normalised 个文件 · 重建 index.toml（$count 条）· 同步 pack.toml 哈希")
}

# ---------- 检查 ----------
$problems = New-Object System.Collections.Generic.List[string]
$checked = 0
$indexPath = Join-Path $PackDir 'index.toml'
$indexText = [System.IO.File]::ReadAllText($indexPath)
$recorded = @{}
foreach ($m in [regex]::Matches($indexText, '(?ms)\[\[files\]\]\s*file\s*=\s*"([^"]+)"\s*hash\s*=\s*"([0-9a-f]+)"')) {
    $recorded[$m.Groups[1].Value] = $m.Groups[2].Value
}

$onDisk = Get-ChildItem $PackDir -Recurse -File |
    Where-Object { $_.Name -ne 'index.toml' -and $_.Name -ne 'pack.toml' }
foreach ($f in $onDisk) {
    $rel = $f.FullName.Replace($PackDir + '\', '').Replace('\', '/')
    if (-not $recorded.ContainsKey($rel)) { $problems.Add("未登记: $rel"); continue }
    $checked++
    if ((Sha256 $f.FullName) -ne $recorded[$rel]) { $problems.Add("哈希不符: $rel") }
}
foreach ($key in $recorded.Keys) {
    if (-not (Test-Path (Join-Path $PackDir $key))) { $problems.Add("索引有、磁盘无: $key") }
}

$packToml = Join-Path $PackDir 'pack.toml'
$t = [System.IO.File]::ReadAllText($packToml)
$m = [regex]::Match($t, '(?ms)\[index\].*?hash\s*=\s*"([0-9a-f]+)"')
if (-not $m.Success) { $problems.Add('pack.toml 缺少 [index] hash') }
elseif ($m.Groups[1].Value -ne (Sha256 $indexPath)) { $problems.Add('pack.toml 的 index 哈希不符') }

foreach ($f in $onDisk) {
    if ((IsText $f) -and (HasCrlf $f)) {
        $problems.Add('CRLF: ' + $f.FullName.Replace($PackDir + '\', '').Replace('\', '/'))
    }
}

$pw = Get-ChildItem (Join-Path $PackDir 'mods') -Filter '*.pw.toml'
foreach ($one in $pw) {
    $body = [System.IO.File]::ReadAllText($one.FullName)
    foreach ($field in @('name', 'filename', 'side')) {
        if ($body -notmatch ('(?m)^' + $field + '\s*=\s*".+"')) { $problems.Add('缺少 ' + $field + ': mods/' + $one.Name) }
    }
    if ($body -notmatch '(?ms)\[download\].*?url\s*=\s*"https?://.+?"') { $problems.Add('缺少 download.url: mods/' + $one.Name) }
    if ($body -notmatch '(?m)^hash-format\s*=\s*"(sha1|sha256|sha512|md5|murmur2)"') { $problems.Add('hash-format 非法: mods/' + $one.Name) }
    if ($body -notmatch '(?m)^hash\s*=\s*"[0-9a-f]+"') { $problems.Add('缺少 hash: mods/' + $one.Name) }
}

Write-Output ("哈希核对: $checked 个文件 · .pw.toml: $($pw.Count) 个")
if ($problems.Count -eq 0) {
    Write-Output 'pack-lint: 全部通过'
    exit 0
}
Write-Output ("pack-lint: $($problems.Count) 个问题")
foreach ($p in $problems) { Write-Output ('  - ' + $p) }
exit 1

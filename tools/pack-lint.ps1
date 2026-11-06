<#
.SYNOPSIS
  校验 packwiz 工程的自洽性：index 哈希、pack.toml 索引哈希、行尾、.pw.toml 字段。

.DESCRIPTION
  这个脚本存在的理由很具体：本项目两次手工修过 index.toml 的 CRLF 与随之失效的哈希。
  人记住的事会忘，脚本不会。它只读，不改任何文件；有问题时以非零码退出。

  检查项：
    1. pack/ 下每个文件（index.toml 除外）的 sha256 必须与 index.toml 记录一致
    2. index.toml 里不能有多余条目，也不能漏文件
    3. pack.toml 的 [index] hash 必须等于 index.toml 的 sha256
    4. pack/ 下的文本文件不得含 CRLF
    5. 每个 *.pw.toml 必须有 name / filename / side 与 [download]（url + hash-format + hash）

.EXAMPLE
  pwsh -File tools/pack-lint.ps1
#>
[CmdletBinding()]
param(
    [string]$PackDir = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $PackDir) { $PackDir = Join-Path $repo 'pack' }
if (-not (Test-Path $PackDir)) { throw "找不到整合包目录: $PackDir" }

function Sha256($path) { (Get-FileHash $path -Algorithm SHA256).Hash.ToLower() }

$problems = New-Object System.Collections.Generic.List[string]
$checked = 0

# ---------- 1/2. index.toml 与文件哈希 ----------
$indexPath = Join-Path $PackDir 'index.toml'
if (-not (Test-Path $indexPath)) { throw '找不到 index.toml' }
$indexText = [System.IO.File]::ReadAllText($indexPath)

$recorded = @{}
foreach ($m in [regex]::Matches($indexText, '(?ms)\[\[files\]\]\s*file\s*=\s*"([^"]+)"\s*hash\s*=\s*"([0-9a-f]+)"')) {
    $recorded[$m.Groups[1].Value] = $m.Groups[2].Value
}
Write-Output ('index.toml 记录: ' + $recorded.Count + ' 个文件')

$onDisk = Get-ChildItem $PackDir -Recurse -File | Where-Object { $_.Name -ne 'index.toml' -and $_.Name -ne 'pack.toml' }
foreach ($f in $onDisk) {
    $rel = $f.FullName.Replace($PackDir + '\', '').Replace('\', '/')
    if (-not $recorded.ContainsKey($rel)) {
        $problems.Add("未登记: $rel")
        continue
    }
    $checked++
    if ((Sha256 $f.FullName) -ne $recorded[$rel]) {
        $problems.Add("哈希不符: $rel")
    }
}
foreach ($key in $recorded.Keys) {
    if (-not (Test-Path (Join-Path $PackDir ($key -replace '/', '\')))) {
        $problems.Add("索引里有、磁盘上没有: $key")
    }
}

# ---------- 3. pack.toml 的 index 哈希 ----------
$packToml = Join-Path $PackDir 'pack.toml'
$t = [System.IO.File]::ReadAllText($packToml)
$m = [regex]::Match($t, '(?ms)\[index\].*?hash\s*=\s*"([0-9a-f]+)"')
if (-not $m.Success) {
    $problems.Add('pack.toml 缺少 [index] hash')
} elseif ($m.Groups[1].Value -ne (Sha256 $indexPath)) {
    $problems.Add('pack.toml 的 index 哈希与 index.toml 实际哈希不符')
}

# ---------- 4. 行尾 ----------
$textExt = @('.toml', '.js', '.snbt', '.json', '.md', '.txt', '.cfg')
foreach ($f in $onDisk) {
    if ($textExt -notcontains $f.Extension.ToLower()) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    for ($i = 0; $i -lt $bytes.Length - 1; $i++) {
        if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10) {
            $rel = $f.FullName.Replace($PackDir + '\', '').Replace('\', '/')
            $problems.Add("CRLF: $rel")
            break
        }
    }
}

# ---------- 5. .pw.toml 字段 ----------
$pw = Get-ChildItem (Join-Path $PackDir 'mods') -Filter '*.pw.toml'
foreach ($one in $pw) {
    $body = [System.IO.File]::ReadAllText($one.FullName)
    foreach ($field in @('name', 'filename', 'side')) {
        if ($body -notmatch ('(?m)^' + $field + '\s*=\s*".+"')) {
            $problems.Add(('缺少 ' + $field + ': mods/' + $one.Name))
        }
    }
    if ($body -notmatch '(?ms)\[download\].*?url\s*=\s*"https?://.+?"') {
        $problems.Add('缺少 download.url: mods/' + $one.Name)
    }
    if ($body -notmatch '(?m)^hash-format\s*=\s*"(sha1|sha256|sha512|md5|murmur2)"') {
        $problems.Add('缺少或非法的 hash-format: mods/' + $one.Name)
    }
    if ($body -notmatch '(?m)^hash\s*=\s*"[0-9a-f]+"') {
        $problems.Add('缺少 hash: mods/' + $one.Name)
    }
}

# ---------- 结果 ----------
Write-Output ('哈希核对: ' + $checked + ' 个文件 · .pw.toml: ' + $pw.Count + ' 个')
if ($problems.Count -eq 0) {
    Write-Output 'pack-lint: 全部通过'
    exit 0
}

Write-Output ('pack-lint: ' + $problems.Count + ' 个问题')
foreach ($p in $problems) { Write-Output ('  - ' + $p) }
exit 1

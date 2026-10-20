<#
.SYNOPSIS
  重新生成 packwiz 的 index.toml 与 pack.toml 的 [index] hash（本机没有 packwiz CLI 时的等价实现）。

.DESCRIPTION
  packwiz 的 `refresh` 只做两件事：
    1) 扫描 pack/ 下所有受管文件（mods/*.pw.toml 等元数据 + 直接分发的文件），按路径排序写入 index.toml（LF 换行、无 BOM）；
    2) 计算 index.toml 的 sha256（对文件字节），回填 pack.toml 的 [index].hash。
  本脚本按同样规则实现，产物与 packwiz 兼容；改完 pack/ 后跑一次即可。

.EXAMPLE
  pwsh -File tools/pack-refresh.ps1
  pwsh -File tools/pack-refresh.ps1 -Check     # 只校验，不写（应与 packwiz 的产物一致）
#>
[CmdletBinding()]
param(
  [string]$PackDir = '',
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
if (-not $PackDir) {
  $repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
  $PackDir = Join-Path $repo 'pack'
}
$indexPath = Join-Path $PackDir 'index.toml'
$packPath  = Join-Path $PackDir 'pack.toml'
if (-not (Test-Path $packPath)) { throw "不是 packwiz 工程：$PackDir" }

function Get-Build {
  $files = Get-ChildItem $PackDir -Recurse -File |
    Where-Object { $_.Name -notin @('index.toml', 'pack.toml') } |
    ForEach-Object { $_.FullName.Substring($PackDir.Length + 1).Replace('\', '/') } |
    Sort-Object

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('hash-format = "sha256"')
  foreach ($rel in $files) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $PackDir $rel) -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines.Add('')
    $lines.Add('[[files]]')
    $lines.Add("file = `"$rel`"")
    $lines.Add("hash = `"$hash`"")
    if ($rel.EndsWith('.pw.toml')) { $lines.Add('metafile = true') }
  }
  [pscustomobject]@{
    Text  = (($lines -join "`n") + "`n")
    Count = $files.Count
  }
}

function Get-Sha256([string]$text) {
  $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($text)
  ([System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
}

$b = Get-Build
$wantHash = Get-Sha256 $b.Text
$packText = Get-Content -LiteralPath $packPath -Raw
$m = [regex]::Match($packText, '(?m)^hash\s*=\s*"([0-9a-f]{64})"')

if ($Check) {
  $oldText = if (Test-Path $indexPath) { (Get-Content -LiteralPath $indexPath -Raw) -replace "`r`n", "`n" } else { '' }
  $indexOk = ($oldText -eq $b.Text)
  $hashOk = ($m.Success -and $m.Groups[1].Value -eq $wantHash)
  if ($indexOk -and $hashOk) { "OK：index.toml 与 pack.toml 一致（$($b.Count) 个文件，sha256=$wantHash）"; exit 0 }
  "不一致：index 内容相同=$indexOk，pack.toml hash 匹配=$hashOk（期望 $wantHash）"
  exit 1
}

[System.IO.File]::WriteAllText($indexPath, $b.Text, (New-Object System.Text.UTF8Encoding($false)))
$newPack = [regex]::Replace($packText, '(?m)^(hash\s*=\s*")[0-9a-f]{64}(")', ('${1}' + $wantHash + '${2}'))
[System.IO.File]::WriteAllText($packPath, ($newPack -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
"已刷新：$($b.Count) 个文件；index sha256 = $wantHash"

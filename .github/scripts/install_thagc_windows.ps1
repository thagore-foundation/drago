Param(
  [string]$Tag = "v0.9.6",
  [string]$Channel = "indev",
  [string]$Arch = ""
)

$ErrorActionPreference = "Stop"
$scriptUrl = "https://github.com/thagore-foundation/thagore/releases/latest/download/thagup.ps1"
$tmpPath = Join-Path $env:RUNNER_TEMP "thagup.ps1"
$prefix = Join-Path $HOME ".thagore"
$target = if ($Arch -eq "aarch64" -or $Arch -eq "arm64") { "aarch64-pc-windows-msvc" } else { "x86_64-pc-windows-msvc" }

Write-Host "installing thagc $Tag ($Channel)"
Invoke-WebRequest -Uri $scriptUrl -OutFile $tmpPath
powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -Target $target -Prefix $prefix -WithoutDrago -Force

$binPath = Join-Path $prefix "bin"
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $binPath
}

& (Join-Path $binPath "thagc.exe") --version

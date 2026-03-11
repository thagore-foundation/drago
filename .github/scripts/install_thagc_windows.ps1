Param(
  [string]$Tag = "v0.9.6",
  [string]$Channel = "indev",
  [string]$Arch = ""
)

$ErrorActionPreference = "Stop"
$scriptUrl = "https://github.com/thagore-foundation/thagore/releases/latest/download/thagup.ps1"
$tmpPath = Join-Path $env:RUNNER_TEMP "thagup.ps1"
$prefix = Join-Path $HOME ".thagore"

Write-Host "installing thagc $Tag ($Channel)"
Invoke-WebRequest -Uri $scriptUrl -OutFile $tmpPath
if ([string]::IsNullOrWhiteSpace($Arch)) {
  powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -Prefix $prefix -Force
} else {
  powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -Arch $Arch -Prefix $prefix -Force
}

$binPath = Join-Path $prefix "bin"
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $binPath
}

& (Join-Path $binPath "thagc.exe") --version

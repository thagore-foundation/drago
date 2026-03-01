Param(
  [string]$Tag = "v1.0.0",
  [string]$Channel = "stable"
)

$ErrorActionPreference = "Stop"
$scriptUrl = "https://raw.githubusercontent.com/thagore-foundation/thagore/main/tooling/release/thagup.ps1"
$tmpPath = Join-Path $env:RUNNER_TEMP "thagup.ps1"

Write-Host "installing thagc $Tag ($Channel)"
Invoke-WebRequest -Uri $scriptUrl -OutFile $tmpPath
powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -Force

$binPath = Join-Path $HOME ".thagore\bin"
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $binPath
}

& (Join-Path $binPath "thagc.exe") --version

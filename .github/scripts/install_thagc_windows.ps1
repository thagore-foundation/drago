Param(
  [string]$Tag = "v1.0.1",
  [string]$Channel = "stable",
  [string]$Arch = ""
)

$ErrorActionPreference = "Stop"
$scriptUrl = "https://raw.githubusercontent.com/thagore-foundation/thagore/main/tooling/release/thagup.ps1"
$tmpPath = Join-Path $env:RUNNER_TEMP "thagup.ps1"

Write-Host "installing thagc $Tag ($Channel)"
Invoke-WebRequest -Uri $scriptUrl -OutFile $tmpPath
if ([string]::IsNullOrWhiteSpace($Arch)) {
  powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -WithoutDrago -Force
} else {
  powershell -ExecutionPolicy Bypass -File $tmpPath -Tag $Tag -Channel $Channel -Arch $Arch -WithoutDrago -Force
}

$binPath = Join-Path $HOME ".thagore\bin"
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $binPath
}

& (Join-Path $binPath "thagc.exe") --version

<#
.SYNOPSIS
  Installs agit on Windows: downloads the release binary, verifies its
  SHA-256 checksum, and adds it to your user PATH so you can just run `agit`.

.USAGE
  irm https://raw.githubusercontent.com/Satari4545/ai-git-releases/main/install.ps1 | iex
#>
$ErrorActionPreference = 'Stop'

$Version = '0.2.0'
$BaseUrl = "https://github.com/Satari4545/ai-git-releases/releases/download/v$Version"

if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
  $Asset = 'agit-windows-arm64.exe'
} else {
  $Asset = 'agit-windows-amd64.exe'
}

$InstallDir = Join-Path $env:LOCALAPPDATA 'agit'
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$ExePath = Join-Path $InstallDir 'agit.exe'
$SumPath = Join-Path $InstallDir "$Asset.sha256"

Write-Host "Downloading $Asset (agit v$Version)..."
Invoke-WebRequest -Uri "$BaseUrl/$Asset" -OutFile $ExePath
Invoke-WebRequest -Uri "$BaseUrl/$Asset.sha256" -OutFile $SumPath

Write-Host 'Verifying checksum...'
$Expected = ((Get-Content $SumPath -TotalCount 1) -split '\s+')[0].Trim().ToLower()
$Actual = (Get-FileHash -Path $ExePath -Algorithm SHA256).Hash.ToLower()
if ($Expected -ne $Actual) {
  Remove-Item $ExePath -Force -ErrorAction SilentlyContinue
  throw 'Checksum mismatch - download may be corrupt. Aborting.'
}
Write-Host 'Checksum OK.'

$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($UserPath -split ';') -notcontains $InstallDir) {
  [Environment]::SetEnvironmentVariable('Path', "$UserPath;$InstallDir", 'User')
  Write-Host "Added $InstallDir to your user PATH."
}
if (($env:Path -split ';') -notcontains $InstallDir) {
  $env:Path += ";$InstallDir"
}

Write-Host ''
& $ExePath --version
Write-Host ''
Write-Host 'Done. Open a NEW terminal and type:  agit --version'

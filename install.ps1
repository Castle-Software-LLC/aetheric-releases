# Install the aetheric daemon and CLI (Windows).
#
#   irm https://raw.githubusercontent.com/<releases-repo>/main/install.ps1 | iex
#
# Downloads aetheric.exe from the public releases repo, checks it against the
# release's SHA256SUMS, installs it to %LOCALAPPDATA%\Programs\Aetheric and
# adds that folder to your user PATH. $env:AETHERIC_VERSION pins a version.
$ErrorActionPreference = 'Stop'

$Repo = if ($env:AETHERIC_RELEASES_REPO) { $env:AETHERIC_RELEASES_REPO } else { 'Castle-Software-LLC/aetheric-releases' }
$Api = if ($env:AETHERIC_GITHUB_API) { $env:AETHERIC_GITHUB_API } else { 'https://api.github.com' }
$Dest = if ($env:AETHERIC_INSTALL_DIR) { $env:AETHERIC_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\Aetheric' }

$arch = switch ($env:PROCESSOR_ARCHITECTURE) { 'AMD64' { 'x64' } 'ARM64' { 'arm64' } default { throw "unsupported CPU $env:PROCESSOR_ARCHITECTURE" } }
$target = "win-$arch"

if ($env:AETHERIC_VERSION) {
  $version = $env:AETHERIC_VERSION.TrimStart('v')
} else {
  # The newest release that isn't a draft (prereleases included while there is no stable one).
  $release = (Invoke-RestMethod "$Api/repos/$Repo/releases?per_page=1" -Headers @{ 'User-Agent' = 'aetheric-installer' })[0]
  if (-not $release) { throw "no release found in $Repo" }
  $version = $release.tag_name.TrimStart('v')
}

$asset = "aetheric-$version-$target.exe"
$base = if ($env:AETHERIC_DOWNLOAD_BASE) { $env:AETHERIC_DOWNLOAD_BASE } else { "https://github.com/$Repo/releases/download/v$version" }
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("aetheric-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Write-Host "downloading aetheric $version for $target"
  Invoke-WebRequest "$base/$asset" -OutFile (Join-Path $tmp $asset) -UseBasicParsing
  Invoke-WebRequest "$base/SHA256SUMS" -OutFile (Join-Path $tmp 'SHA256SUMS') -UseBasicParsing
  $line = Get-Content (Join-Path $tmp 'SHA256SUMS') | Where-Object { ($_ -split '\s+')[1] -eq $asset } | Select-Object -First 1
  if (-not $line) { throw "SHA256SUMS has no entry for $asset" }
  $expected = ($line -split '\s+')[0].ToLower()
  $actual = (Get-FileHash (Join-Path $tmp $asset) -Algorithm SHA256).Hash.ToLower()
  if ($actual -ne $expected) { throw "checksum mismatch for $asset; nothing installed" }

  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Move-Item -Force (Join-Path $tmp $asset) (Join-Path $Dest 'aetheric.exe')
  Write-Host "installed $(Join-Path $Dest 'aetheric.exe')"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not (($userPath -split ';') -contains $Dest)) {
  [Environment]::SetEnvironmentVariable('Path', "$userPath;$Dest", 'User')
  Write-Host "added $Dest to your PATH (open a new terminal)"
}

Write-Host @"

Next:
  aetheric doctor --fix                 check this machine; downloads Claude Code
  aetheric service install              run the daemon at logon
  aetheric remote enable --tailscale    let your phone reach it over Tailscale
  aetheric pair                         pair the phone
"@

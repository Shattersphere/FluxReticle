param(
    [string]$StarsectorDirectory,
    [string]$ModDirectoryName = 'Flux Reticle Fork',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$buildScript = Join-Path $repoRoot 'scripts\build_mod.ps1'

function Read-LocalProperty([string]$name) {
    $localProperties = Join-Path $repoRoot 'local.properties'
    if (!(Test-Path -LiteralPath $localProperties)) {
        return $null
    }

    foreach ($line in Get-Content -LiteralPath $localProperties) {
        if ($line -match '^\s*#' -or $line -notmatch '=') {
            continue
        }

        $parts = $line.Split('=', 2)
        if ($parts[0].Trim() -eq $name) {
            return $parts[1].Trim()
        }
    }

    return $null
}

function Resolve-StarsectorDirectory {
    if ($StarsectorDirectory) {
        return $StarsectorDirectory
    }
    if ($env:STARSECTOR_DIRECTORY) {
        return $env:STARSECTOR_DIRECTORY
    }

    $fromLocalProperties = Read-LocalProperty 'starsectorDirectory'
    if ($fromLocalProperties) {
        return $fromLocalProperties
    }

    throw 'Starsector directory not configured. Pass -StarsectorDirectory, set STARSECTOR_DIRECTORY, or add local.properties with starsectorDirectory=C:\Path\To\Starsector.'
}

function Assert-PathInside([string]$path, [string]$parent) {
    $resolvedParent = [IO.Path]::GetFullPath($parent).TrimEnd('\') + '\'
    $resolvedPath = [IO.Path]::GetFullPath($path).TrimEnd('\') + '\'
    if (!$resolvedPath.StartsWith($resolvedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify '$path' because it is not inside '$parent'."
    }
}

function Copy-RepoItem([string]$relativePath, [string]$targetRoot) {
    $source = Join-Path $repoRoot $relativePath
    $target = Join-Path $targetRoot $relativePath
    if (!(Test-Path -LiteralPath $source)) {
        throw "Missing repo-managed source path: $source"
    }

    $targetParent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
}

function Compare-RepoItem([string]$relativePath, [string]$targetRoot) {
    $source = Join-Path $repoRoot $relativePath
    $target = Join-Path $targetRoot $relativePath
    if ((Test-Path -LiteralPath $source -PathType Leaf) -and (Test-Path -LiteralPath $target -PathType Leaf)) {
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if ($sourceHash -ne $targetHash) {
            throw "Deploy hash mismatch for $relativePath"
        }
    }
}

$starsectorDir = Resolve-StarsectorDirectory
$modsDir = Join-Path $starsectorDir 'mods'
if (!(Test-Path -LiteralPath $modsDir)) {
    throw "Missing Starsector mods directory: $modsDir"
}

$targetRoot = Join-Path $modsDir $ModDirectoryName
Assert-PathInside $targetRoot $modsDir

if (!$SkipBuild) {
    & powershell -ExecutionPolicy Bypass -File $buildScript -StarsectorDirectory $starsectorDir
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
}

New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

$managedPaths = @(
    'Change Log.url',
    'FLUX_RETICLE_OPTIONS.ini',
    'data',
    'jars',
    'mod_info.json',
    'shat_fr.version',
    'shat_fr'
)

$retiredManagedPaths = @(
    'sun_fr.version',
    'sun_fr'
)

foreach ($relativePath in $managedPaths + $retiredManagedPaths) {
    $target = Join-Path $targetRoot $relativePath
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }
}

foreach ($relativePath in $managedPaths) {
    Copy-RepoItem $relativePath $targetRoot
}

foreach ($relativePath in @(
    'FLUX_RETICLE_OPTIONS.ini',
    'data\config\LunaSettings.csv',
    'data\config\LunaSettingsConfig.json',
    'data\config\settings.json',
    'data\config\sounds.json',
    'data\config\version\version_files.csv',
    'jars\FluxReticle.jar',
    'mod_info.json',
    'shat_fr.version'
)) {
    Compare-RepoItem $relativePath $targetRoot
}

Write-Host "Deployed Flux Reticle Fork to $targetRoot"

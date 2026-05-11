param(
    [string]$StarsectorDirectory
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$buildDir = Join-Path $repoRoot 'build'
$classesDir = Join-Path $buildDir 'classes'
$tmpJar = Join-Path $buildDir 'FluxReticle.jar.tmp'
$repoJar = Join-Path $repoRoot 'jars\FluxReticle.jar'

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

function Resolve-CoreDirectory([string]$starsectorDir) {
    $candidates = @(
        (Join-Path $starsectorDir 'starsector-core'),
        $starsectorDir
    )

    foreach ($candidate in $candidates) {
        $required = @('starfarer.api.jar', 'starfarer_obf.jar', 'fs.common_obf.jar')
        $hasAll = $true
        foreach ($jar in $required) {
            if (!(Test-Path -LiteralPath (Join-Path $candidate $jar))) {
                $hasAll = $false
                break
            }
        }
        if ($hasAll) {
            return $candidate
        }
    }

    throw "Could not find Starsector core jars under '$starsectorDir' or '$starsectorDir\starsector-core'."
}

function Resolve-ModDirectory([string]$starsectorDir, [string]$modId, [string]$displayName) {
    $modsDir = Join-Path $starsectorDir 'mods'
    if (!(Test-Path -LiteralPath $modsDir)) {
        throw "Missing Starsector mods directory: $modsDir"
    }

    foreach ($dir in Get-ChildItem -LiteralPath $modsDir -Directory) {
        $modInfo = Join-Path $dir.FullName 'mod_info.json'
        if (!(Test-Path -LiteralPath $modInfo)) {
            continue
        }

        $raw = Get-Content -Raw -LiteralPath $modInfo
        $firstId = [regex]::Match($raw, '"id"\s*:\s*"([^"]+)"')
        if ($firstId.Success -and $firstId.Groups[1].Value -eq $modId) {
            return $dir.FullName
        }
    }

    throw "Missing required dependency mod: $displayName ($modId). Install it under $modsDir."
}

function Join-Classpath([string[]]$paths) {
    return ($paths -join [IO.Path]::PathSeparator)
}

$starsectorDir = Resolve-StarsectorDirectory
$coreDir = Resolve-CoreDirectory $starsectorDir
$lunaDir = Resolve-ModDirectory $starsectorDir 'lunalib' 'LunaLib'
$lunaJar = Join-Path $lunaDir 'jars\LunaLib.jar'
if (!(Test-Path -LiteralPath $lunaJar)) {
    throw "Missing LunaLib jar: $lunaJar"
}

$coreJars = @(
    'starfarer.api.jar',
    'starfarer_obf.jar',
    'fs.common_obf.jar',
    'lwjgl.jar',
    'lwjgl_util.jar',
    'json.jar',
    'log4j-1.2.9.jar'
) | ForEach-Object { Join-Path $coreDir $_ }

foreach ($jar in $coreJars) {
    if (!(Test-Path -LiteralPath $jar)) {
        throw "Missing required Starsector jar: $jar"
    }
}

if (Test-Path -LiteralPath $classesDir) {
    Remove-Item -LiteralPath $classesDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $classesDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $repoJar) | Out-Null

$sources = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'src') -Recurse -Filter '*.java' | ForEach-Object { $_.FullName }
if (!$sources -or $sources.Count -eq 0) {
    throw 'No Java sources found under src.'
}

$classpath = Join-Classpath ($coreJars + @($lunaJar))
Write-Host "Starsector: $starsectorDir"
Write-Host "Core jars:  $coreDir"
Write-Host "LunaLib:    $lunaDir"
Write-Host "Output jar: $repoJar"

& javac -encoding UTF-8 -source 8 -target 8 -classpath $classpath -d $classesDir $sources
if ($LASTEXITCODE -ne 0) {
    throw "javac failed with exit code $LASTEXITCODE"
}

if (Test-Path -LiteralPath $tmpJar) {
    Remove-Item -LiteralPath $tmpJar -Force
}
Push-Location $classesDir
try {
    & jar cf $tmpJar .
    if ($LASTEXITCODE -ne 0) {
        throw "jar failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($tmpJar)
try {
    if ($zip.Entries.Count -eq 0) {
        throw "Built jar has no entries: $tmpJar"
    }
}
finally {
    $zip.Dispose()
}

Move-Item -LiteralPath $tmpJar -Destination $repoJar -Force
Write-Host "Built and validated $repoJar"

<#
Reusable agent deploy template.

Copy this file into a repo and customize the "Project configuration" block.
The default behavior is intentionally conservative:
- build and validation commands are opt-in;
- blocked user processes queue a background waiter by default, not a stuck agent process;
- a newer deploy run cancels an older recorded deploy script for the same repo;
- deploy writes to a staging directory first, then swaps/copies into the target.
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$DeployTarget = "",
    [switch]$SkipBuild,
    [switch]$SkipValidation,
    [switch]$NoWaitForBlockers,
    [switch]$DryRun,
    [switch]$ForegroundWait,
    [int]$PollSeconds = 5,
    [switch]$QueuedWorker,
    [string]$ResumeRunId = "",
    [string]$ResumeStagingRoot = ""
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Project configuration
# ---------------------------------------------------------------------------

# Repo root. Leave empty to auto-detect the nearest parent with .git.
$DefaultRepoRoot = ""

# Required unless passed with -DeployTarget.
$DefaultDeployTarget = "C:\Games\Starsector\mods\Flux Reticle Fork"

# Commands run from $RepoRoot. Leave empty to skip.
# Examples:
# $BuildCommand = { & .\gradlew.bat jar }
# $ValidationCommand = { & powershell -ExecutionPolicy Bypass -File .\scripts\validate_config.ps1 }
$BuildCommand = {
    $starsectorDir = Split-Path -Parent (Split-Path -Parent $DeployTarget)
    & powershell -ExecutionPolicy Bypass -File .\scripts\build_mod.ps1 -StarsectorDirectory $starsectorDir
}
$ValidationCommand = {
    $rows = Import-Csv -LiteralPath .\data\config\LunaSettings.csv
    $badRows = $rows | Where-Object {
        [string]::IsNullOrWhiteSpace($_.fieldID) `
            -or $_.modID -ne 'shattersphere_flux_reticle_fork' `
            -or $_.fieldID -notmatch '^shat_fr_'
    }
    $duplicateRows = $rows | Group-Object fieldID | Where-Object { $_.Name -and $_.Count -gt 1 }
    if ($badRows.Count -gt 0 -or $duplicateRows.Count -gt 0) {
        throw "Invalid LunaSettings.csv: badRows=$($badRows.Count), duplicateFieldIDs=$($duplicateRows.Count)"
    }
}
$PostDeployValidationCommand = {
    $checks = @(
        'FLUX_RETICLE_OPTIONS.ini',
        'data\config\LunaSettings.csv',
        'data\config\LunaSettingsConfig.json',
        'data\config\settings.json',
        'data\config\sounds.json',
        'data\config\version\version_files.csv',
        'jars\FluxReticle.jar',
        'mod_info.json',
        'shat_fr.version'
    )
    foreach ($relativePath in $checks) {
        $source = Join-Path $RepoRoot $relativePath
        $live = Join-Path $DeployTarget $relativePath
        if (!(Test-Path -LiteralPath $live)) {
            throw "Live deploy missing $relativePath"
        }
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $liveHash = (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash
        if ($sourceHash -ne $liveHash) {
            throw "Live deploy hash mismatch for $relativePath"
        }
    }
    foreach ($retiredPath in @('sun_fr', 'sun_fr.version')) {
        $liveRetiredPath = Join-Path $DeployTarget $retiredPath
        if (Test-Path -LiteralPath $liveRetiredPath) {
            throw "Retired upstream path still exists in live deploy: $liveRetiredPath"
        }
    }
}

# Files/directories to copy from repo to deploy target.
# Each item supports Source, Destination, and Optional.
# Destination is relative to deploy target unless absolute.
$DeployItems = @(
    @{ Source = "Change Log.url"; Destination = "Change Log.url"; Optional = $false },
    @{ Source = "FLUX_RETICLE_OPTIONS.ini"; Destination = "FLUX_RETICLE_OPTIONS.ini"; Optional = $false },
    @{ Source = "data"; Destination = "data"; Optional = $false },
    @{ Source = "jars"; Destination = "jars"; Optional = $false },
    @{ Source = "mod_info.json"; Destination = "mod_info.json"; Optional = $false },
    @{ Source = "shat_fr.version"; Destination = "shat_fr.version"; Optional = $false },
    @{ Source = "shat_fr"; Destination = "shat_fr"; Optional = $false }
)

# Processes that make it unsafe to copy/deploy. The script waits for these to
# exit. It never kills these processes.
$BlockedProcesses = @(
    @{ Name = "java"; PathContains = "Starsector"; WindowTitleContains = "" },
    @{ Name = "Starsector"; PathContains = ""; WindowTitleContains = "" }
)

# A repo-specific name lets multiple copied scripts in one repo supersede each
# other without affecting unrelated repos.
$DeployName = "flux-reticle-fork-deploy"

# State files live here. The newest deploy run records itself and can cancel
# the older recorded deploy script if it is still running.
$StateDirectoryName = ".agent-deploy"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Resolve-ConfigPath {
    param([string]$Base, [string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $Base $Path))
}

function Find-RepoRoot {
    param([string]$StartDirectory)
    $current = Get-Item -LiteralPath $StartDirectory
    while ($null -ne $current) {
        if (Test-Path -LiteralPath (Join-Path $current.FullName ".git")) {
            return $current.FullName
        }
        $current = $current.Parent
    }
    return [System.IO.Path]::GetFullPath($StartDirectory)
}

function Get-RepoHash {
    param([string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Path.ToLowerInvariant())
        $hash = $sha.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString("x2") }) -join "").Substring(0, 16)
    } finally {
        $sha.Dispose()
    }
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-ProcessCommandLine {
    param([int]$ProcessId)
    try {
        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction Stop
        return [string]$process.CommandLine
    } catch {
        return ""
    }
}

function Write-JsonFile {
    param([string]$Path, [object]$Value)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $Value | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Set-ObjectProperty {
    param([object]$Object, [string]$Name, [object]$Value)
    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function ConvertTo-ProcessArgument {
    param([string]$Value)
    if ($null -eq $Value) {
        return '""'
    }
    $escaped = $Value -replace '"', '\"'
    return '"' + $escaped + '"'
}

function Get-PowerShellExecutablePath {
    try {
        $current = Get-Process -Id $PID -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($current.Path)) {
            return $current.Path
        }
    } catch {
    }

    $candidates = @(
        (Join-Path $PSHOME "powershell.exe"),
        (Join-Path $PSHOME "pwsh.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw "Could not find the PowerShell executable for queued deploy worker."
}

function Stop-OlderDeployRun {
    param([string]$StateFile, [string]$RunId)
    $previous = Read-JsonFile -Path $StateFile
    if ($null -eq $previous -or $null -eq $previous.Pid) {
        return
    }

    $previousPid = [int]$previous.Pid
    if ($previousPid -eq $PID) {
        return
    }

    $oldProcess = Get-Process -Id $previousPid -ErrorAction SilentlyContinue
    if ($null -eq $oldProcess) {
        return
    }

    $previousScriptPath = [string]$previous.ScriptPath
    $commandLine = Get-ProcessCommandLine -ProcessId $previousPid
    if ([string]::IsNullOrWhiteSpace($previousScriptPath) -or $commandLine.IndexOf($previousScriptPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        Write-Host "Previous deploy pid=$previousPid is still alive, but it does not look like the recorded deploy script. Leaving it alone."
        return
    }

    Write-Host "Cancelling previous deploy run pid=$previousPid runId=$($previous.RunId)"
    Stop-Process -Id $previousPid -Force
}

function Assert-CurrentRun {
    param([string]$StateFile, [string]$RunId)
    $state = Read-JsonFile -Path $StateFile
    if ($null -eq $state -or $state.RunId -ne $RunId -or [int]$state.Pid -ne $PID) {
        throw "This deploy run has been superseded by a newer run."
    }
}

function Set-DeployPhase {
    param([string]$StateFile, [string]$RunId, [string]$Phase)
    $state = Read-JsonFile -Path $StateFile
    if ($null -eq $state) {
        return
    }
    $state.Phase = $Phase
    $state.UpdatedAt = (Get-Date).ToString("o")
    Write-JsonFile -Path $StateFile -Value $state
}

function Claim-QueuedDeployRun {
    param(
        [string]$StateFile,
        [string]$RunId,
        [string]$RepoRoot,
        [string]$DeployTarget
    )

    $state = Read-JsonFile -Path $StateFile
    if ($null -eq $state -or $state.RunId -ne $RunId) {
        throw "Queued deploy run is no longer current."
    }

    $state.Pid = $PID
    $state.RepoRoot = $RepoRoot
    $state.DeployTarget = $DeployTarget
    $state.ScriptPath = $PSCommandPath
    $state.Phase = "waiting"
    $state.UpdatedAt = (Get-Date).ToString("o")
    Write-JsonFile -Path $StateFile -Value $state
}

function Start-QueuedDeployWorker {
    param(
        [string]$StateFile,
        [string]$RunId,
        [string]$StagingRoot,
        [string]$RepoRoot,
        [string]$DeployTarget,
        [switch]$SkipValidation,
        [int]$PollSeconds
    )

    $powerShellExe = Get-PowerShellExecutablePath
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (ConvertTo-ProcessArgument -Value $PSCommandPath),
        "-RepoRoot", (ConvertTo-ProcessArgument -Value $RepoRoot),
        "-DeployTarget", (ConvertTo-ProcessArgument -Value $DeployTarget),
        "-PollSeconds", ([string]$PollSeconds),
        "-QueuedWorker",
        "-ResumeRunId", (ConvertTo-ProcessArgument -Value $RunId),
        "-ResumeStagingRoot", (ConvertTo-ProcessArgument -Value $StagingRoot)
    )
    if ($SkipValidation) {
        $arguments += "-SkipValidation"
    }

    $worker = Start-Process -FilePath $powerShellExe -ArgumentList $arguments -WindowStyle Hidden -PassThru
    $state = Read-JsonFile -Path $StateFile
    if ($null -ne $state -and $state.RunId -eq $RunId) {
        $state.Pid = $worker.Id
        $state.Phase = "queued"
        $workerStartedAt = (Get-Date).ToString("o")
        Set-ObjectProperty -Object $state -Name "WorkerStartedAt" -Value $workerStartedAt
        $state.UpdatedAt = $workerStartedAt
        Write-JsonFile -Path $StateFile -Value $state
    }
    Write-Host "Deploy queued in background worker pid=$($worker.Id). This shell does not need to wait."
}

function Get-ProcessPathSafe {
    param([System.Diagnostics.Process]$Process)
    try {
        return [string]$Process.MainModule.FileName
    } catch {
        return ""
    }
}

function Find-BlockedProcesses {
    param([array]$Rules)
    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($rule in $Rules) {
        $name = [string]$rule.Name
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }
        $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($process in $processes) {
            $path = Get-ProcessPathSafe -Process $process
            $commandLine = Get-ProcessCommandLine -ProcessId $process.Id
            $title = [string]$process.MainWindowTitle
            $pathNeedle = [string]$rule.PathContains
            $titleNeedle = [string]$rule.WindowTitleContains

            if ((-not [string]::IsNullOrWhiteSpace($pathNeedle)) `
                    -and $path.IndexOf($pathNeedle, [StringComparison]::OrdinalIgnoreCase) -lt 0 `
                    -and $commandLine.IndexOf($pathNeedle, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
                continue
            }
            if (-not [string]::IsNullOrWhiteSpace($titleNeedle) -and $title.IndexOf($titleNeedle, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
                continue
            }

            $matches.Add([pscustomobject]@{
                Id = $process.Id
                Name = $process.ProcessName
                Path = $path
                CommandLine = $commandLine
                WindowTitle = $title
            })
        }
    }
    return $matches
}

function Wait-ForBlockers {
    param([array]$Rules, [string]$StateFile, [string]$RunId, [int]$PollSeconds)
    if ($Rules.Count -eq 0) {
        return
    }

    while ($true) {
        Assert-CurrentRun -StateFile $StateFile -RunId $RunId
        $blocked = @(Find-BlockedProcesses -Rules $Rules)
        if ($blocked.Count -eq 0) {
            return
        }
        $summary = ($blocked | ForEach-Object { "$($_.Name)(pid=$($_.Id))" }) -join ", "
        Write-Host "Deploy waiting for blocked process(es) to exit: $summary"
        Start-Sleep -Seconds ([Math]::Max(1, $PollSeconds))
    }
}

function Copy-DeployItem {
    param(
        [string]$RepoRoot,
        [string]$StagingRoot,
        [hashtable]$Item,
        [switch]$DryRun
    )
    $source = Resolve-ConfigPath -Base $RepoRoot -Path ([string]$Item.Source)
    $destination = Resolve-ConfigPath -Base $StagingRoot -Path ([string]$Item.Destination)
    $optional = [bool]$Item.Optional

    if (-not (Test-Path -LiteralPath $source)) {
        if ($optional) {
            Write-Host "Skipping optional missing deploy item: $source"
            return
        }
        throw "Deploy source not found: $source"
    }

    Write-Host "Stage: $source -> $destination"
    if ($DryRun) {
        return
    }

    $destinationParent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationParent)) {
        New-Item -ItemType Directory -Path $destinationParent | Out-Null
    }

    $sourceItem = Get-Item -LiteralPath $source
    if ($sourceItem.PSIsContainer) {
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
    } else {
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}

function Publish-DeployItem {
    param(
        [string]$StagingRoot,
        [string]$DeployTarget,
        [hashtable]$Item,
        [switch]$DryRun
    )

    $stagedSource = Resolve-ConfigPath -Base $StagingRoot -Path ([string]$Item.Destination)
    $liveDestination = Resolve-ConfigPath -Base $DeployTarget -Path ([string]$Item.Destination)
    $optional = [bool]$Item.Optional

    if (-not (Test-Path -LiteralPath $stagedSource)) {
        if ($optional) {
            return
        }
        throw "Staged deploy item not found: $stagedSource"
    }

    Write-Host "Publish: $stagedSource -> $liveDestination"
    if ($DryRun) {
        return
    }

    if (-not (Test-Path -LiteralPath $DeployTarget)) {
        New-Item -ItemType Directory -Path $DeployTarget | Out-Null
    }
    $destinationParent = Split-Path -Parent $liveDestination
    if (-not (Test-Path -LiteralPath $destinationParent)) {
        New-Item -ItemType Directory -Path $destinationParent | Out-Null
    }

    $stagedItem = Get-Item -LiteralPath $stagedSource
    if ($stagedItem.PSIsContainer) {
        if (Test-Path -LiteralPath $liveDestination) {
            Remove-Item -LiteralPath $liveDestination -Recurse -Force
        }
        Copy-Item -LiteralPath $stagedSource -Destination $liveDestination -Recurse -Force
    } else {
        Copy-Item -LiteralPath $stagedSource -Destination $liveDestination -Force
    }
}

function Invoke-OptionalCommand {
    param([scriptblock]$Command, [string]$Name, [switch]$Skip, [string]$RepoRoot)
    if ($Skip -or $null -eq $Command) {
        Write-Host "Skipping $Name."
        return
    }
    Write-Host "Running $Name..."
    Push-Location $RepoRoot
    try {
        & $Command
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = $DefaultRepoRoot
}
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Find-RepoRoot -StartDirectory (Split-Path -Parent $PSCommandPath)
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

if ([string]::IsNullOrWhiteSpace($DeployTarget)) {
    $DeployTarget = $DefaultDeployTarget
}
if ([string]::IsNullOrWhiteSpace($DeployTarget)) {
    throw "Deploy target is required. Set `$DefaultDeployTarget in the script or pass -DeployTarget."
}
$DeployTarget = [System.IO.Path]::GetFullPath($DeployTarget)

if ($DeployItems.Count -eq 0) {
    throw "DeployItems is empty. Customize the script before using it."
}

$stateRoot = Join-Path $RepoRoot $StateDirectoryName
$repoHash = Get-RepoHash -Path $RepoRoot
$stateFile = Join-Path $stateRoot "$DeployName-$repoHash.latest.json"
$runId = if ([string]::IsNullOrWhiteSpace($ResumeRunId)) { [Guid]::NewGuid().ToString() } else { $ResumeRunId }

if ($QueuedWorker) {
    if ([string]::IsNullOrWhiteSpace($ResumeStagingRoot)) {
        throw "Queued worker requires -ResumeStagingRoot."
    }
    Claim-QueuedDeployRun -StateFile $stateFile -RunId $runId -RepoRoot $RepoRoot -DeployTarget $DeployTarget
} else {
    Stop-OlderDeployRun -StateFile $stateFile -RunId $runId
    Write-JsonFile -Path $stateFile -Value ([pscustomobject]@{
        RunId = $runId
        Pid = $PID
        DeployName = $DeployName
        RepoRoot = $RepoRoot
        DeployTarget = $DeployTarget
        ScriptPath = $PSCommandPath
        Phase = "starting"
        StartedAt = (Get-Date).ToString("o")
        UpdatedAt = (Get-Date).ToString("o")
        FinishedAt = $null
    })
}

try {
    if ($QueuedWorker) {
        $stagingRoot = [System.IO.Path]::GetFullPath($ResumeStagingRoot)
    } else {
        Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "build"
        Invoke-OptionalCommand -Command $BuildCommand -Name "build" -Skip:$SkipBuild -RepoRoot $RepoRoot

        Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "validation"
        Invoke-OptionalCommand -Command $ValidationCommand -Name "validation" -Skip:$SkipValidation -RepoRoot $RepoRoot

        Assert-CurrentRun -StateFile $stateFile -RunId $runId
        Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "staging"
        $stagingRoot = Join-Path $stateRoot "staging-$DeployName-$runId"
        if (Test-Path -LiteralPath $stagingRoot) {
            Remove-Item -LiteralPath $stagingRoot -Recurse -Force
        }
        New-Item -ItemType Directory -Path $stagingRoot | Out-Null

        foreach ($item in $DeployItems) {
            Assert-CurrentRun -StateFile $stateFile -RunId $runId
            Copy-DeployItem -RepoRoot $RepoRoot -StagingRoot $stagingRoot -Item $item -DryRun:$DryRun
        }
    }

    if (-not $NoWaitForBlockers) {
        $blocked = @(Find-BlockedProcesses -Rules $BlockedProcesses)
        if ($blocked.Count -gt 0 -and -not $ForegroundWait -and -not $QueuedWorker -and -not $DryRun) {
            Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "queued"
            Start-QueuedDeployWorker -StateFile $stateFile -RunId $runId -StagingRoot $stagingRoot -RepoRoot $RepoRoot -DeployTarget $DeployTarget -SkipValidation:$SkipValidation -PollSeconds $PollSeconds
            return
        }

        Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "waiting"
        Wait-ForBlockers -Rules $BlockedProcesses -StateFile $stateFile -RunId $runId -PollSeconds $PollSeconds
    }

    Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "publishing"
    foreach ($item in $DeployItems) {
        Assert-CurrentRun -StateFile $stateFile -RunId $runId
        Publish-DeployItem -StagingRoot $stagingRoot -DeployTarget $DeployTarget -Item $item -DryRun:$DryRun
    }

    Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "post-validation"
    Invoke-OptionalCommand -Command $PostDeployValidationCommand -Name "post-deploy validation" -Skip:$SkipValidation -RepoRoot $RepoRoot

    if (-not $DryRun -and (Test-Path -LiteralPath $stagingRoot)) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }

    Set-DeployPhase -StateFile $stateFile -RunId $runId -Phase "complete"
    Write-Host "Deploy complete: $DeployTarget"
} catch {
    $state = Read-JsonFile -Path $stateFile
    if ($null -ne $state -and $state.RunId -eq $runId -and [int]$state.Pid -eq $PID) {
        $failedAt = (Get-Date).ToString("o")
        $state.Phase = "failed"
        Set-ObjectProperty -Object $state -Name "Error" -Value $_.Exception.Message
        $state.UpdatedAt = $failedAt
        Write-JsonFile -Path $stateFile -Value $state
    }
    throw
} finally {
    $state = Read-JsonFile -Path $stateFile
    if ($null -ne $state -and $state.RunId -eq $runId -and [int]$state.Pid -eq $PID) {
        $state.FinishedAt = (Get-Date).ToString("o")
        $state.UpdatedAt = $state.FinishedAt
        Write-JsonFile -Path $stateFile -Value $state
    }
}

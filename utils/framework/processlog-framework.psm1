
$processLogs = New-Object -TypeName 'System.Collections.ArrayList'
$beginThreshold = 0.5

function Write-ProcessLogs {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory, ValueFromPipeline = $true)][AllowNull()][object]$inputLog,
        [Switch] $allowSuccessOutput
    )

    BEGIN {
        $next = @{
            name = $processDescription
            logs = New-Object -TypeName 'System.Collections.ArrayList'
        }
        $processLogs.Add($next) *> $null
    }
    PROCESS
    {
        # https://stackoverflow.com/a/71444848/195653 - can get ErrorRecord and many other types
        if ($inputLog -is [string] -AND $allowSuccessOutput) {
            return $inputLog
        }
        $next.logs.Add($inputLog) *>$nil
    }
    END {
    }
}

function Invoke-ProcessLogs {
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory)][scriptblock]$process,
        [Switch] $allowSuccessOutput
    )
    $state = @{ isRunning = $true; hasOutput = $false }
    $quiet = Get-IsQuiet
    $reportProgress = [scriptblock]::Create((-not $quiet) ? "
        params(`$state)

        Start-Sleep -Seconds $beginThreshold
        if (`$state.isRunning) {
            `$state.hasOutput = $true
            Write-Host `"Working on '$($processDescription.Replace('"', '`"').Replace('`', '``'))'...`"
        }
    " : "")
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $job = Start-ThreadJob $reportProgress -StreamingHost $Host -ArgumentList @($state)
    & $process *>&1 | Write-ProcessLogs $processDescription -allowSuccessOutput:$allowSuccessOutput
    $state.isRunning = $false
    $timer.Stop()
    if ($job.jobstateinfo.state -ne 'Completed') {
        Stop-Job $job *>$null
    }
    if ($state.hasOutput) {
        Write-Host "End '$processDescription'. ($([math]::Round($timer.Elapsed.TotalSeconds, 1))s)"
    }
    Remove-Job $job -Force
}

function Get-IsQuiet {
    return $false
}

function Clear-ProcessLogs {
    $processLogs.Clear()
}

function Get-ProcessLogs {
    return @(,$processLogs.Clone())
}

function Show-ProcessLogs {
    foreach ($entry in $processLogs) {
        Write-Host "Logs for '$($entry.name)':"
        foreach ($inner in $entry.logs) {
            Write-Host "    $inner"
        }
    }
}

Export-ModuleMember -Function Clear-ProcessLogs, Get-ProcessLogs, Invoke-ProcessLogs, Show-ProcessLogs


$processLogs = New-Object -TypeName 'System.Collections.ArrayList'

function Write-ProcessLogs {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory, ValueFromPipeline = $true)][object]$inputLog,
        [Switch] $allowSuccessOutput,
        [Switch] $quiet
    )

    BEGIN {
        $next = @{
            name = $processDescription
            logs = New-Object -TypeName 'System.Collections.ArrayList'
        }
        $processLogs.Add($next) *> $null
    
        if (-not $quiet) {
            Write-Host "Begin '$processDescription'..."
        }
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
        if (-not $quiet) {
            Write-Host "End '$processDescription'."
        }
    }
}

function Invoke-ProcessLogs {
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory)][scriptblock]$process,
        [Switch] $allowSuccessOutput,
        [Switch] $quiet
    )
    & $process *>&1 | Write-ProcessLogs $processDescription -allowSuccessOutput:$allowSuccessOutput -quiet:$quiet
}

function Clear-ProcessLogs {
    $processLogs.Clear()
}

function Get-ProcessLogs {
    return @(,$processLogs.Clone())
}

Export-ModuleMember -Function Clear-ProcessLogs, Get-ProcessLogs, Invoke-ProcessLogs

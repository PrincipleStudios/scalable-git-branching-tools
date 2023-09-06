
$processLogs = New-Object -TypeName 'System.Collections.ArrayList'

function Write-ProcessLogs {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory, ValueFromPipeline = $true)][object]$inputLog,
        [Switch] $allowSuccessOutput
    )

    BEGIN {
        Write-Host "Begin '$processDescription'..."
    }
    PROCESS
    {
        # https://stackoverflow.com/a/71444848/195653 - can get ErrorRecord and many other types
        if ($inputLog -is [string] -AND $allowSuccessOutput) {
            return $inputLog
        }
        $processLogs.Add($inputLog)
    }
    END {
        Write-Host "End '$processDescription'."
    }
}

function Invoke-ProcessLogs {
    Param (
        [Parameter(Mandatory)][string]$processDescription,
        [Parameter(Mandatory)][scriptblock]$process,
        [Switch] $allowSuccessOutput
    )
    & $process *>&1 | Write-ProcessLogs $processDescription -allowSuccessOutput:$allowSuccessOutput
}

function Clear-ProcessLogs {
    $processLogs.Clear()
}

function Get-ProcessLogs {
    return @(,$processLogs.Clone())
}

Export-ModuleMember -Function Clear-ProcessLogs, Get-ProcessLogs, Invoke-ProcessLogs

Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

class ResultWithCleanup {
    [object] $result

    ResultWithCleanup() {
    }

    ResultWithCleanup([object] $result) {
        $this.result = $result
    }
}

function New-ResultAfterCleanup([object] $result) {
    return New-Object ResultWithCleanup $result
}

function Get-GitHead() {
    $prevHead = Get-CurrentBranch
    if ($prevHead -eq $nil) {
        $prevHead = (git rev-parse HEAD)
    }
    return $prevHead
}

function Restore-GitHead([String] $previousHead) {
    Invoke-ProcessLogs "git reset --hard" {
        git reset --hard
    } -quiet
    Invoke-ProcessLogs "git checkout $previousHead" {
        git checkout $previousHead
    } -quiet
}

function Invoke-PreserveBranch([ScriptBlock]$scriptBlock, [ScriptBlock]$cleanup, [switch]$noDefaultCleanup, [switch]$onlyIfError) {
    Assert-CleanWorkingDirectory
    $prevHead = Get-GitHead

    $fullCleanup = {
        if (-not $noDefaultCleanup) {
            Restore-GitHead $prevHead
        }
        if ($cleanup -ne $nil) {
            & $cleanup $prevHead
        }
    }

    try {
        $result = & $scriptBlock
    } catch {
        & $fullCleanup
        throw;
    }

    $resultIsResultWithCleanup = $result -is [ResultWithCleanup]

    if (-not $onlyIfError -or $resultIsResultWithCleanup) {
        & $fullCleanup
    }

    if ($resultIsResultWithCleanup) {
        $result = $result.result
    }

    return $result
}
Export-ModuleMember -Function Invoke-PreserveBranch, New-ResultAfterCleanup, Get-GitHead, Restore-GitHead

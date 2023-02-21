Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"

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

function Invoke-PreserveBranch([ScriptBlock]$scriptBlock, [ScriptBlock]$cleanup, [switch]$noDefaultCleanup, [switch]$onlyIfError) {
    Assert-CleanWorkingDirectory
    $prevHead = Get-CurrentBranch
    if ($prevHead -eq $nil) {
        $prevHead = (git rev-parse HEAD)
    }

    $fullCleanup = {
        if (-not $noDefaultCleanup) {
            git reset --hard
            git checkout $prevHead
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
Export-ModuleMember -Function Invoke-PreserveBranch, New-ResultAfterCleanup

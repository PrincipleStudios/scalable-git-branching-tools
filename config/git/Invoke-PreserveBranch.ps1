. $PSScriptRoot/Assert-CleanWorkingDirectory.ps1

class ResultWithCleanup {
    [object] $result

    ResultWithCleanup() {
    }

    ResultWithCleanup([object] $result) {
        $this.result = $result
    }
}

function Invoke-PreserveBranch([ScriptBlock]$scriptBlock, [ScriptBlock]$cleanup, [switch]$noDefaultCleanup, [switch]$onlyIfError) {
    Assert-CleanWorkingDirectory
    $prevHead = (git branch --show-current)
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

    if (-not $onlyIfError -or $result -is [ResultWithCleanup]) {
        & $fullCleanup
    }

    if ($result -is [ResultWithCleanup]) {
        $result = $result.result
    }

    return $result
}

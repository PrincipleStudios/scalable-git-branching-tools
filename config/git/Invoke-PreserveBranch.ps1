. $PSScriptRoot/Assert-CleanWorkingDirectory.ps1

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
        & $scriptBlock
    } catch {
        & $fullCleanup
        throw;
    }

    if (-not $onlyIfError) {
        & $fullCleanup
    }
}

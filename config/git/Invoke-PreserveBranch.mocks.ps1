
. $PSScriptRoot/Invoke-PreserveBranch.ps1

$invokePreserveBranch = @{ cleanupCounter = 0 }

Mock -CommandName Invoke-PreserveBranch {
    $fullCleanup = {
        $invokePreserveBranch.cleanupCounter += 1
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

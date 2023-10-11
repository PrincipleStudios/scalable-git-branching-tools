Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeTogether.psm1"

function Invoke-MockGitModuleStartsWith([string] $gitCli, [object] $MockWith) {
    $result = New-VerifiableMock `
        -ModuleName 'Invoke-MergeTogether' `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ').StartsWith('$gitCli')"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            if ($MockWith -is [scriptblock]) {
                & $MockWith
            } elseif ($MockWith -ne $nil) {
                $MockWith
            }
        }.GetNewClosure()
    return $result
}

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Invoke-MergeTogether' @PSBoundParameters
}

function Initialize-MergeTogetherAllFailed(
    [AllowEmptyCollection()][string[]] $allBranches
) {
    foreach ($branch in $allBranches) {
        Invoke-MockGit "rev-parse --verify $branch" -MockWith { $global:LASTEXITCODE = 1 }
    }
}

function Initialize-MergeTogether(
    [AllowEmptyCollection()][string[]] $allBranches,
    [AllowEmptyCollection()][string[]] $successfulBranches,
    [string] $messageTemplate = "Merge {}",
    [string] $resultCommitish
) {
    $success = @()
    $failed = @()
    $initialSuccessfulBranch = $allBranches | Where-Object { $successfulBranches -contains $_ } | Select-Object -First 1

    if ($null -ne $initialSuccessfulBranch) {
        $lastBranch = ($allBranches | Where-Object { $successfulBranches -contains $_ } | Select-Object -Last 1)
        $commitish = $successfulBranches | ConvertTo-HashMap -getValue { "$_-commitish" }
        $commitish[$lastBranch] = $resultCommitish

        $success += $initialSuccessfulBranch

        $currentCommit = $commitish[$initialSuccessfulBranch]
        Invoke-MockGit "rev-parse --verify $initialSuccessfulBranch" -MockWith { $commitish[$initialSuccessfulBranch] }.GetNewClosure()
    }

    for ($i = 0; $i -lt $allBranches.Count; $i++) {
        $current = $allBranches[$i]
        if ($successfulBranches -contains $current) {
            $success += $current
            if ($current -eq $initialSuccessfulBranch) { continue }

            $treeish = "$current-tree"
            $message = $messageTemplate.Replace('{}', $current)
            Initialize-MergeTree $currentCommit $current $treeish
            Invoke-MockGit "commit-tree $treeish -m $message -p $currentCommit" -MockWith "$($commitish[$current])"
            $currentCommit = $commitish[$current]

            foreach ($failedBranch in $failed) {
                Initialize-MergeTree $currentCommit $failedBranch $treeish -fail
            }
        } else {
            if ($success.Count -eq 0) {
                Invoke-MockGit "rev-parse --verify $current" -MockWith { $global:LASTEXITCODE = 1 }
            } else {
                $treeish = "$current-tree"
                Initialize-MergeTree $currentCommit $current $treeish -fail
            }
            $failed += $current
        }
    }
}

Export-ModuleMember -Function Initialize-MergeTogetherAllFailed, Initialize-MergeTogether

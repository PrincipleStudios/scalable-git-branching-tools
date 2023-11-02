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
    [AllowNull()][string] $source = $null,
    [string] $messageTemplate = "Merge {}",
    [string] $resultCommitish
) {
    $success = @()
    $failed = @()
    if ($null -ne $source -AND '' -ne $source -AND $allBranches -notcontains $source) {
        $allBranches = @($source) + $allBranches
    }
    if ($null -ne $source -AND '' -ne $source -AND $successfulBranches -notcontains $source) {
        $successfulBranches = @($source) + ($successfulBranches | Where-Object { $_ })
    }
    $initialSuccessfulBranch = ($allBranches | Where-Object { $successfulBranches -contains $_ } | Select-Object -First 1)
    
    $commitish = $allBranches | ConvertTo-HashMap -getValue { "$_-commitish" }
    if ($null -ne $initialSuccessfulBranch) {
        $lastBranch = ($allBranches | Where-Object { $successfulBranches -contains $_ } | Select-Object -Last 1)
        $resultCommitishes = $successfulBranches | Where-Object { $successfulBranches -contains $_ } | ConvertTo-HashMap -getValue { "$_-result-commitish" }
        if ($lastBranch -eq $initialSuccessfulBranch) {
            $resultCommitishes[$lastBranch] = $resultCommitish
        }
        $commitish[$initialSuccessfulBranch] = $resultCommitishes[$initialSuccessfulBranch]
        if ($null -eq $resultCommitish) {
            throw 'Invalid Initialize-MergeTogether; -resultCommitish must be provided if any branches are successful'
        }

        $currentCommit = $resultCommitishes[$initialSuccessfulBranch]
        Invoke-MockGit "rev-parse --verify $initialSuccessfulBranch" -MockWith { $commitish[$initialSuccessfulBranch] }.GetNewClosure()
    }


    for ($i = 0; $i -lt $allBranches.Count; $i++) {
        $current = $allBranches[$i]
        if ($successfulBranches -contains $current) {
            $success += $current
            if ($current -eq $initialSuccessfulBranch) { continue }
            Invoke-MockGit "rev-parse --verify $current" -MockWith $commitish[$current]

            Invoke-MockGit "rev-list --count ^$currentCommit $($commitish[$current])" -MockWith "1"

            $treeish = "$current-tree"
            $message = $messageTemplate.Replace('{}', $current)
            Initialize-MergeTree $currentCommit $commitish[$current] $treeish
            Invoke-MockGit "commit-tree $treeish -p $currentCommit -p $($commitish[$current]) -m interim merge" -MockWith "$($resultCommitishes[$current])"
            $currentCommit = $resultCommitishes[$current]

            foreach ($failedBranch in $failed) {
                # Each failed branch will retry merging, so needs to be re-set-up for each success
                Invoke-MockGit "rev-list --count ^$currentCommit $($commitish[$failedBranch])" -MockWith "1"
                Initialize-MergeTree $currentCommit $commitish[$failedBranch] $treeish -fail
            }
        } else {
            if ($success.Count -eq 0) {
                # If everything fails, that means we weren't able to resolve a single commitish
                Invoke-MockGit "rev-parse --verify $current" -MockWith { $global:LASTEXITCODE = 1 }
            } else {
                Invoke-MockGit "rev-parse --verify $current" -MockWith $commitish[$current]
                Invoke-MockGit "rev-list --count ^$currentCommit $($commitish[$current])" -MockWith "1"
                $treeish = "$current-tree"
                Initialize-MergeTree $currentCommit $commitish[$current] $treeish -fail
            }
            $failed += $current
        }
    }

    if ($successfulBranches.Count -gt 1) {
        $message = $messageTemplate.Replace('{}', ($successfulBranches | Where-Object { $_ -ne $source }) -join ', ')
        $parents = $allBranches | Where-Object { $successfulBranches -contains $_ } | ForEach-Object { @("-p", $commitish[$_]) }
        $treeish = "$lastBranch-tree"
        Invoke-MockGit "commit-tree $treeish -m $message $parents" -MockWith "$($resultCommitish)"
    }
}

Export-ModuleMember -Function Initialize-MergeTogetherAllFailed, Initialize-MergeTogether

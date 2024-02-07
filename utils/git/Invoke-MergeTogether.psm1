Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Invoke-MergeTogether(
    [Parameter(Mandatory)][String[]] $commitishes, 
    [Parameter()][AllowNull()][string] $source = $null,
    [Parameter()][string] $messageTemplate = "Merge {}",
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter()][hashtable] $commitMappingOverride = @{},
    [switch] $asWarnings
) {
    function ResolveCommit($commitish) {
        if ($commitMappingOverride[$commitish]) {
            return $commitMappingOverride[$commitish]
        }
        $result = Invoke-ProcessLogs "git rev-parse --verify $target" {
            git rev-parse --verify $target
        } -allowSuccessOutput
        if ($global:LASTEXITCODE -ne 0) { return $null }
        return $result
    }

    [String[]]$remaining = $commitishes
    [String[]]$failed = @()
    [String[]]$successful = @()

    $currentCommit = $null
    $parentCommits = @()
    if ($null -ne $source -AND '' -ne $source) {
        $target = $source

        $currentCommit = ResolveCommit $target
        if ($null -eq $currentCommit) {
            $remaining = $remaining | Where-Object { $_ -ne $target }
            $failed += $target
            Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)' for source of merge"
            
            return @{
                result = $null
                hasChanges = $false
                successful = @()
                failed = @($target)
            }
        } else {
            $parentCommits += $currentCommit
        }
    }
    while ($remaining.Count -gt 0) {
        $target = $remaining[0]
        if ($null -eq $currentCommit) {
            $parsedCommitish = ResolveCommit $target
            if ($null -ne $parsedCommitish) {
                $currentCommit = $parsedCommitish
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $parentCommits += $currentCommit
                $successful += $target
            } else {
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $failed += $target
                if ($asWarnings) {
                    Add-WarningDiagnostic $diagnostics "Could not resolve '$($target)'"
                } else {
                    Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)'"
                }
            }
        } else {
            $allFailed = $true
            for ($i = 0; $i -lt $remaining.Count; $i++) {
                $target = $remaining[$i]
                $targetCommit = ResolveCommit $target
                if ($null -eq $targetCommit) {
                    # If we can't resolve the commit, it'll never resolve
                    $remaining = $remaining | Where-Object { $_ -ne $target }
                    $failed += $target
                    if ($asWarnings) {
                        Add-WarningDiagnostic $diagnostics "Could not resolve '$($target)'"
                    } else {
                        Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)'"
                    }
                    $i--
                    continue
                }

                $commitsDiff = Invoke-ProcessLogs "git rev-list --count ^$currentCommit $targetCommit" {
                    # Check to see if there are any new commits in the $currentCommit history from $target's history
                    git rev-list --count "^$currentCommit" $targetCommit
                } -allowSuccessOutput
                if ($commitsDiff -ne 0) {
                    # New commits on $targetCommit compared to $currentCommit; do the merge
                    $mergeTreeResult = Get-MergeTree $currentCommit $targetCommit
                    if (-not $mergeTreeResult.isSuccess) { continue }
                    $nextTree = $mergeTreeResult.treeish

                    # Successful merge
                    $commitMessage = $messageTemplate.Replace('{}', $target)
                    $resultCommit = Invoke-ProcessLogs "git commit-tree $nextTree -p $currentCommit -p $targetCommit -m $commitMessage" {
                        # Order and message is different here from below so that the mocks can give different results
                        git commit-tree $nextTree -p $currentCommit -p $targetCommit -m $commitMessage
                    } -allowSuccessOutput
                    if ($global:LASTEXITCODE -ne 0) { continue }

                    $currentCommit = $resultCommit
                    $parentCommits += $targetCommit
                    $successful += $target
                }
                $allFailed = $false
                $i--
                $remaining = $remaining | Where-Object { $_ -ne $target }
                break;
            }
            if ($allFailed -AND $remaining.Count -gt 0) {
                if ($asWarnings) {
                    Add-WarningDiagnostic $diagnostics "Could not merge the following branches: $remaining"
                } else {
                    Add-ErrorDiagnostic $diagnostics "Could not merge the following branches: $remaining"
                }

                $failed += $remaining
                $remaining = @()
            }
        }
    }

    $hasChanges = $false
    if ($parentCommits.Count -gt 1) {
        $hasChanges = $true
        # $commitMessage = $messageTemplate.Replace('{}', $successful -join ', ')
        # $parents = $parentCommits | ForEach-Object { @("-p", $_) }
        # $currentCommit = Invoke-ProcessLogs "git commit-tree $nextTree -m $commitMessage $parents" {
        #     git commit-tree $nextTree -m $commitMessage @parents
        # } -allowSuccessOutput
    }

    return @{
        result = $currentCommit
        hasChanges = $hasChanges
        successful = $successful
        failed = $failed
    }
}

Export-ModuleMember -Function Invoke-MergeTogether

Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

# TODO: this assumes all branches are remotes (if remote is specified)
function Register-LocalActionMergeBranches([PSObject] $localActions) {
    $localActions['merge-branches'] = {
        param(
            [string] $source,
            [string[]] $upstreamBranches,
            [string] $mergeMessageTemplate = "Merge {}",
            [hashtable] $commitMappingOverride = @{},

            [Parameter()][bool] $errorOnFailure = $false,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $config = Get-Configuration
        if ($null -ne $config.remote) {
            $upstreamBranches = [string[]]$upstreamBranches | Where-Object { $_ } | Foreach-Object { "$($config.remote)/$_" }
            if ($null -ne $source -AND '' -ne $source) {
                $source = "$($config.remote)/$source"
            }
        }

        if ($null -eq $upstreamBranches) {
            # Nothing to merge
            return @{
                commit = $null;
                hasChanges = $false;
                failed = @();
                successful = $();
            }
        }

        $mergeResult = Invoke-MergeTogether `
            -source $source `
            -commitishes $upstreamBranches `
            -messageTemplate $mergeMessageTemplate `
            -commitMappingOverride $commitMappingOverride `
            -diagnostics $diagnostics `
            -noFailureMessages:$(-not $errorOnFailure)
        $commit = $mergeResult.result
        if ($null -eq $commit) {
            if ($source -notin $mergeResult.failed) {
                Add-ErrorDiagnostic $diagnostics "No branches could be resolved to merge"
            }
        }

        $failed = $mergeResult.failed
        $successful = $mergeResult.successful
        if ($null -ne $config.remote) {
            $prefix = "$($config.remote)/"
            $failed = [string[]]$failed | Foreach-Object { $_.StartsWith($prefix) ? $_.Substring($prefix.Length) : $_ }
            $successful = [string[]]$successful | Foreach-Object { $_.StartsWith($prefix) ? $_.Substring($prefix.Length) : $_ }
        }

        return @{
            # [string] new commit hash, or null if everything failed
            commit = $mergeResult.result
            
            # [boolean] false if the commit is null or if it matches the source
            hasChanges = $mergeResult.hasChanges
            
            # [string[]] list of branches that could not merge due to conflicts
            failed = $failed
            
            # [string[]] list of branches that would merge without errors (but may have no changes)
            successful = $successful
        }
    }
}

Export-ModuleMember -Function Register-LocalActionMergeBranches

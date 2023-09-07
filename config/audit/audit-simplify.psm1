. $PSScriptRoot/../core/ArrayToHash.ps1
Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFileNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Compress-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Set-MultipleUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Update-UpstreamBranch.psm1"

function Invoke-SimplifyAudit([switch] $apply) {
    $config = Get-Configuration

    $allConfiguredUpstream = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote
        | ArrayToHash -getValue { Select-UpstreamBranches $_ }

    $updatedConfigurations = @{}

    $simplifyResult = $allConfiguredUpstream.Keys
        | ArrayToHash -getValue {
            $result = Compress-UpstreamBranches $allConfiguredUpstream[$_]
            if (($result -join ',') -ne ($allConfiguredUpstream[$_] -join ',')) {
                $updatedConfigurations[$_] = $result
            }
            return $result
        }

    if ($updatedConfigurations.Count -ne 0) {
        Write-Host -ForegroundColor green "Simplify check discovered the following:"
        Write-Host -ForegroundColor green "  Configured branches can be simplified:"
        foreach ($branch in $updatedConfigurations.Keys) {
            Write-Host -ForegroundColor green "  - $branch"
        }

        if ($apply) {
            $commitish = Set-MultipleUpstreamBranches $updatedConfigurations -m "Applied changes from 'simplify' audit"
            Update-UpstreamBranch $commitish
        }
    }
}

Export-ModuleMember -Function Invoke-SimplifyAudit

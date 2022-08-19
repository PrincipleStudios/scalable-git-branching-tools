BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}
}


Describe 'git-verify-updated' {
    It 'fails if no current branch and none provided' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { $Global:LASTEXITCODE = 0 }

        { & $PSScriptRoot/git-verify-updated.ps1 } | Should -Throw
    }
    
    It 'uses the default branch when none specified, without a remote' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { 'feature/PS-2' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1
    }
    
    It 'uses the branch specified, without a remote' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -branchName feature/PS-2
    }
    
    It 'throws when one branch is out of date' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "other-hash" }

        { & $PSScriptRoot/git-verify-updated.ps1 -branchName feature/PS-2 } | Should -Throw
    }
    
    It 'uses the current branch if none specified, with a remote' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { 'feature/PS-2' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1
    }
    
    It 'uses the branch specified, with a remote' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse} {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -branchName feature/PS-2
    }
    
    It 'uses the branch specified, recursively, with a remote' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1        
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/feature/PS-2' } { 'target-branch-hash' }

        . $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND $recurse } {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -branchName feature/PS-2 -recurse
    }
    
}

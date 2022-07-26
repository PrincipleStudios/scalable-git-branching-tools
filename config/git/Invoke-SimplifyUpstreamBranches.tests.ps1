BeforeAll {
    . $PSScriptRoot/Invoke-SimplifyUpstreamBranches.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'Invoke-SimplifyUpstreamBranches' {
    BeforeAll {
        $branches = @(
            @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
            @{ remote = $nil; branch='feature/FOO-124-comment'; type = 'feature'; ticket='FOO-124'; comment='comment' }
            @{ remote = $nil; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') }
            @{ remote = $nil; branch='feature/FOO-76'; type = 'feature'; ticket='FOO-76' }
            @{ remote = $nil; branch='feature/XYZ-1-services'; type = 'feature'; ticket='XYZ-1'; comment='services' }
            @{ remote = $nil; branch='main'; type = 'service-line' }
            @{ remote = $nil; branch='rc/2022-07-14'; type = 'rc'; comment='2022-07-14' }
            @{ remote = $nil; branch='integrate/FOO-125_XYZ-1'; type = 'integration'; tickets=@('FOO-125','XYZ-1') }
        )

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/FOO-123' } { 'main' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/FOO-124-comment' } { 'main' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/FOO-124_FOO-125' } { 'feature/FOO-124-comment' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/FOO-76' } { 'main' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/XYZ-1-services' } { 'main' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'main' } { }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'rc/2022-07-14' } { 'integrate/FOO-125_XYZ-1' }
        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'integrate/FOO-125_XYZ-1' } {
            'feature/FOO-124_FOO-125'
            'feature/XYZ-1-services'
        }
    }

    It 'preserves the same branch' {
        Invoke-SimplifyUpstreamBranches @(
            @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
        ) $branches | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-123')
    }
    It 'preserves all branches if they do not have shared parents' {
        Invoke-SimplifyUpstreamBranches @(
            @{ remote = $nil; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') },
            @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
        ) $branches | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-123','feature/FOO-124_FOO-125')
    }
    It 'filters parents if they are actually extra' {
        Invoke-SimplifyUpstreamBranches @(
            @{ remote = $nil; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') },
            @{ remote = $nil; branch='feature/XYZ-1-services'; type = 'feature'; ticket='XYZ-1'; comment='services' },
            @{ remote = $nil; branch='integrate/FOO-125_XYZ-1'; type = 'integration'; tickets=@('FOO-125','XYZ-1') }
        ) $branches | ForEach-Object { $_.branch } | Should -Be @('integrate/FOO-125_XYZ-1')
    }
    It 'fetches the branch info if not provided' {
        Mock -CommandName Select-Branches { return $branches }
        Invoke-SimplifyUpstreamBranches @(
            @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
        ) | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-123')
    }

}

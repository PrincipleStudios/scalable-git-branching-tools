BeforeAll {
    . $PSScriptRoot/Select-ParentBranches.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-ParentBranches' {
    Context 'When Configured with an origin' {
        BeforeEach{
            Mock git {
                Write-Output "
                origin/feature/FOO-123
                origin/feature/FOO-124-comment
                origin/feature/FOO-124_FOO-125
                origin/feature/FOO-76
                origin/feature/XYZ-1-services
                origin/main
                origin/rc/2022-07-14
                origin/integrate/FOO-125_XYZ-1
                "
            } -ParameterFilter { ($args -join ' ') -eq 'branch -r' }
            
            Mock git {
                Write-Output "origin"
            } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
            
            $branches = Select-Branches
        }

        It 'reports main for no parents' {
            Select-ParentBranches 'feature/FOO-123' | Should -Be @('main')
        }
        It 'reports parent for single-depth entries' {
            Select-ParentBranches 'feature/FOO-124_FOO-125' | Should -Be @('feature/FOO-124-comment')
        }
        It 'reports parent for multi-depth entries' {
            Select-ParentBranches 'feature/FOO-124_FOO-125_FOO-126' | Should -Be @('feature/FOO-124_FOO-125')
        }
        It 'reports parents for integration branches' {
            Select-ParentBranches 'integrate/FOO-125_XYZ-1' | Should -Be @('feature/FOO-124_FOO-125','feature/XYZ-1-services')
        }
        It 'reports integration parents for integration branches' {
            Select-ParentBranches 'integrate/FOO-76_FOO-125_XYZ-1' | Should -Be @('feature/FOO-76','integrate/FOO-125_XYZ-1')
        }
    }
    
    Context 'When Configured without an origin' {
        BeforeEach{
            Mock git {
                Write-Output "
                origin/main
                other/main
                "
            } -ParameterFilter { ($args -join ' ') -eq 'branch -r' }
            
            Mock git {
            } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
            
            $branches = Select-Branches
        }

        It 'errors with multiple service lines' {
            { Select-ParentBranches 'feature/FOO-123' } | Should -Throw
        }
    }
}

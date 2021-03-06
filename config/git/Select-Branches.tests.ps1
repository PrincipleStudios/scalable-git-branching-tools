BeforeAll {
    . $PSScriptRoot/Select-Branches.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-Branches' {
    Context 'With a remote branch specified' {
        BeforeEach{
            Mock git {
                Write-Output "
                origin/feature/FOO-123
                origin/feature/FOO-124-comment
                origin/feature/FOO-124_FOO-125
                origin/main
                origin/rc/2022-07-14
                origin/integrate/FOO-125_XYZ-1
                other/feature/FOO-100
                "
            } -ParameterFilter {($args -join ' ') -eq 'branch -r'}
            
            Mock git {
                Write-Output "origin"
            } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
            
            $branches = Select-Branches
        }

        It 'excludes feature FOO-100' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-100' } 
                | Should -Be $nil
        }
        It 'includes feature FOO-123' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-123' } 
                | Should-BeObject @{ branch = 'feature/FOO-123'; remote = 'origin'; type = 'feature'; ticket = 'FOO-123' }
        }
        It 'includes feature FOO-124' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124-comment' } 
                | Should-BeObject @{ branch = 'feature/FOO-124-comment'; remote = 'origin'; type = 'feature'; ticket = 'FOO-124'; comment = 'comment' }
        }
        It 'includes feature FOO-125' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124_FOO-125' } 
                | Should-BeObject @{ branch = 'feature/FOO-124_FOO-125'; remote = 'origin'; type = 'feature'; ticket = 'FOO-125'; parents = @( 'FOO-124' ) }
        }
        It 'includes rc 2022-07-14' {
            $branches | Where-Object { $_.branch -eq 'rc/2022-07-14' } 
                | Should-BeObject @{ branch = 'rc/2022-07-14'; remote = 'origin'; type = 'rc'; comment = '2022-07-14' }
        }
        It 'includes main' {
            $branches | Where-Object { $_.branch -eq 'main' } 
                | Should-BeObject @{ branch = 'main'; remote = 'origin'; type = 'service-line' }
        }
        It 'includes integrate/FOO-125_XYZ-1' {
            $branches | Where-Object { $_.branch -eq 'integrate/FOO-125_XYZ-1' } 
                | Should-BeObject @{ branch = 'integrate/FOO-125_XYZ-1'; remote = 'origin'; type = 'integration'; tickets = @('FOO-125', 'XYZ-1') }
        }
    }
    
    Context 'Without a remote branch specified' {
        BeforeEach{
            Mock git {
                Write-Output "
                origin/feature/FOO-123
                origin/feature/FOO-124-comment
                origin/feature/FOO-124_FOO-125
                origin/main
                origin/rc/2022-07-14
                origin/integrate/FOO-125_XYZ-1
                other/feature/FOO-100
                "
            } -ParameterFilter {($args -join ' ') -eq 'branch -r'}
            
            Mock git {
            } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
            
            $branches = Select-Branches
        }

        It 'includes feature FOO-100' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-100' } 
                | Should-BeObject @{ branch = 'feature/FOO-100'; remote = 'other'; type = 'feature'; ticket = 'FOO-100' }
        }
        It 'includes feature FOO-123' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-123' } 
                | Should-BeObject @{ branch = 'feature/FOO-123'; remote = 'origin'; type = 'feature'; ticket = 'FOO-123' }
        }
        It 'includes feature FOO-124' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124-comment' } 
                | Should-BeObject @{ branch = 'feature/FOO-124-comment'; remote = 'origin'; type = 'feature'; ticket = 'FOO-124'; comment = 'comment' }
        }
        It 'includes feature FOO-125' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124_FOO-125' } 
                | Should-BeObject @{ branch = 'feature/FOO-124_FOO-125'; remote = 'origin'; type = 'feature'; ticket = 'FOO-125'; parents = @( 'FOO-124' ) }
        }
        It 'includes rc 2022-07-14' {
            $branches | Where-Object { $_.branch -eq 'rc/2022-07-14' } 
                | Should-BeObject @{ branch = 'rc/2022-07-14'; remote = 'origin'; type = 'rc'; comment = '2022-07-14' }
        }
        It 'includes main' {
            $branches | Where-Object { $_.branch -eq 'main' } 
                | Should-BeObject @{ branch = 'main'; remote = 'origin'; type = 'service-line' }
        }
        It 'includes integrate/FOO-125_XYZ-1' {
            $branches | Where-Object { $_.branch -eq 'integrate/FOO-125_XYZ-1' } 
                | Should-BeObject @{ branch = 'integrate/FOO-125_XYZ-1'; remote = 'origin'; type = 'integration'; tickets = @('FOO-125', 'XYZ-1') }
        }
    }
}

BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-Branches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-Branches.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-Branches' {
    Context 'With a remote branch specified' {
        BeforeEach{
            Initialize-ToolConfiguration
            Initialize-SelectBranches @(
                'origin/feature/FOO-123'
                'origin/feature/FOO-124-comment'
                'origin/feature/FOO-124_FOO-125'
                'origin/main'
                'origin/rc/2022-07-14'
                'origin/integrate/FOO-125_XYZ-1'
                'other/feature/FOO-100'
            )

            $branches = Select-Branches
        }

        It 'excludes feature FOO-100' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-100' }
                | Should -Be $nil
        }
        It 'includes feature FOO-123' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-123' }
                | Should-BeObject @{ branch = 'feature/FOO-123'; remote = 'origin' }
        }
        It 'includes feature FOO-124' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124-comment' }
                | Should-BeObject @{ branch = 'feature/FOO-124-comment'; remote = 'origin' }
        }
        It 'includes feature FOO-125' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124_FOO-125' }
                | Should-BeObject @{ branch = 'feature/FOO-124_FOO-125'; remote = 'origin' }
        }
        It 'includes rc 2022-07-14' {
            $branches | Where-Object { $_.branch -eq 'rc/2022-07-14' }
                | Should-BeObject @{ branch = 'rc/2022-07-14'; remote = 'origin' }
        }
        It 'includes main' {
            $branches | Where-Object { $_.branch -eq 'main' }
                | Should-BeObject @{ branch = 'main'; remote = 'origin' }
        }
        It 'includes integrate/FOO-125_XYZ-1' {
            $branches | Where-Object { $_.branch -eq 'integrate/FOO-125_XYZ-1' }
                | Should-BeObject @{ branch = 'integrate/FOO-125_XYZ-1'; remote = 'origin' }
        }
    }

    Context 'Without a remote specified uses local branches' {
        BeforeEach{
            Initialize-ToolConfiguration -noRemote
            Initialize-SelectBranches @(
                'feature/FOO-123'
                'feature/FOO-124-comment'
                'feature/FOO-124_FOO-125'
                'main'
                'rc/2022-07-14'
                'integrate/FOO-125_XYZ-1'
            )

            $branches = Select-Branches
        }

        It 'includes feature FOO-123' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-123' }
                | Should-BeObject @{ branch = 'feature/FOO-123'; remote = $nil }
        }
        It 'includes feature FOO-124' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124-comment' }
                | Should-BeObject @{ branch = 'feature/FOO-124-comment'; remote = $nil }
        }
        It 'includes feature FOO-125' {
            $branches | Where-Object { $_.branch -eq 'feature/FOO-124_FOO-125' }
                | Should-BeObject @{ branch = 'feature/FOO-124_FOO-125'; remote = $nil }
        }
        It 'includes rc 2022-07-14' {
            $branches | Where-Object { $_.branch -eq 'rc/2022-07-14' }
                | Should-BeObject @{ branch = 'rc/2022-07-14'; remote = $nil }
        }
        It 'includes main' {
            $branches | Where-Object { $_.branch -eq 'main' }
                | Should-BeObject @{ branch = 'main'; remote = $nil }
        }
        It 'includes integrate/FOO-125_XYZ-1' {
            $branches | Where-Object { $_.branch -eq 'integrate/FOO-125_XYZ-1' }
                | Should-BeObject @{ branch = 'integrate/FOO-125_XYZ-1'; remote = $nil }
        }
    }
}

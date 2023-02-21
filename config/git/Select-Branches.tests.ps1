BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
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

            $config = @{ remote = 'origin'; upstreamBranch = '_upstream' }

            $branches = Select-Branches -config $config
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
            Mock git {
                Write-Output "
                feature/FOO-123
                feature/FOO-124-comment
                feature/FOO-124_FOO-125
                main
                rc/2022-07-14
                integrate/FOO-125_XYZ-1
                "
            } -ParameterFilter {($args -join ' ') -eq 'branch'}

            $config = @{ remote = $nil; upstreamBranch = '_upstream' }

            $branches = Select-Branches -config $config
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

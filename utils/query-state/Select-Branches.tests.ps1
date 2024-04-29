BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-Branches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-Branches.psm1"
}

Describe 'Select-Branches' {

    function Add-StandardTests {
        It 'excludes feature FOO-100' {
            $branches | Where-Object { $_ -eq 'feature/FOO-100' }
                | Should -Be $nil
        }
        It 'includes feature FOO-123' {
            $branches | Where-Object { $_ -eq 'feature/FOO-123' }
                | Should -Be 'feature/FOO-123'
        }
        It 'includes feature FOO-124' {
            $branches | Where-Object { $_ -eq 'feature/FOO-124-comment' }
                | Should -Be 'feature/FOO-124-comment'
        }
        It 'includes feature FOO-125' {
            $branches | Where-Object { $_ -eq 'feature/FOO-124_FOO-125' }
                | Should -Be 'feature/FOO-124_FOO-125'
        }
        It 'includes rc 2022-07-14' {
            $branches | Where-Object { $_ -eq 'rc/2022-07-14' }
                | Should -Be 'rc/2022-07-14'
        }
        It 'includes main' {
            $branches | Where-Object { $_ -eq 'main' }
                | Should -Be 'main'
        }
        It 'includes integrate/FOO-125_XYZ-1' {
            $branches | Where-Object { $_ -eq 'integrate/FOO-125_XYZ-1' }
                | Should -Be 'integrate/FOO-125_XYZ-1'
        }
    }

    Context 'With two remotes specified' {
        BeforeEach{
            Initialize-ToolConfiguration
            Invoke-MockGitModule -ModuleName 'Select-Branches' 'branch -r' -MockWith @(
                'origin/feature/FOO-123'
                'origin/feature/FOO-124-comment'
                'origin/feature/FOO-124_FOO-125'
                'origin/main'
                'origin/rc/2022-07-14'
                'origin/integrate/FOO-125_XYZ-1'
                'other/feature/FOO-100'
            )

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $branches = Select-Branches
        }

        Add-StandardTests
    }

    Context 'With a remote specified uses local branches' {
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

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $branches = Select-Branches
        }
        
        Add-StandardTests
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

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $branches = Select-Branches
        }

        Add-StandardTests
    }
}

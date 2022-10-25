BeforeAll {
    . $PSScriptRoot/Get-CurrentBranch.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-CurrentBranch' {
    BeforeEach{
        Mock git {
            Write-Output "feature/FOO-1"
        } -ParameterFilter {($args -join ' ') -eq 'branch --show-current'}
    }

    It 'excludes feature FOO-100' {
        Get-CurrentBranch | Should -Be 'feature/FOO-1'
    }
}

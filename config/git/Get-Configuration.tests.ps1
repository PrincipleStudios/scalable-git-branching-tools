BeforeAll {
    . $PSScriptRoot/Get-Configuration.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-Configuration' {
    BeforeEach{
        Mock git {
            Write-Output "origin"
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
    }

    It 'excludes feature FOO-100' {
        Get-Configuration | Should-BeObject @{ remote = 'origin' }
    }
}

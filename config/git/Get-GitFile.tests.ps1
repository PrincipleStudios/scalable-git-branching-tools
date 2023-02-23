BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
}

Describe 'Get-GitFile' {
    It 'outputs a file' {
        Initialize-GitFile 'origin/_upstream' 'integrate/FOO-125_XYZ-1' @("feature/FOO-124_FOO-125", "feature/XYZ-1-services")

        $result = Get-GitFile 'integrate/FOO-125_XYZ-1' 'origin/_upstream'
        $result[0] | Should -Be "feature/FOO-124_FOO-125"
        $result[1] | Should -Be "feature/XYZ-1-services"
    }
}

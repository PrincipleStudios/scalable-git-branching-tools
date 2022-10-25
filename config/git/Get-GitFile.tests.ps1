BeforeAll {
    . $PSScriptRoot/Get-GitFile.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-GitFile' {
    It 'outputs a file' {

        Mock git {
            Write-Output "feature/FOO-124_FOO-125"
            Write-Output "feature/XYZ-1-services"
        } -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:integrate/FOO-125_XYZ-1'}

        $result = Get-GitFile 'integrate/FOO-125_XYZ-1' 'origin/_upstream'
        $result[0] | Should -Be "feature/FOO-124_FOO-125"
        $result[1] | Should -Be "feature/XYZ-1-services"
    }
}

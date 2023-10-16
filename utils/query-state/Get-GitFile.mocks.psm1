Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"

function Initialize-OtherGitFilesAsBlank([string] $branch) {
    $result = New-VerifiableMock `
        -ModuleName 'Get-GitFile' `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ').StartsWith('cat-file -p $($branch):')"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 1
            $nil
        }
    return $result
}

function Initialize-GitFile([string]$branch, [string] $path, [object] $contents) {
    Invoke-MockGitModule -ModuleName 'Get-GitFile' -gitCli "cat-file -p $($branch):$($path)" -MockWith $contents
}

Export-ModuleMember -Function Initialize-OtherGitFilesAsBlank,Initialize-GitFile

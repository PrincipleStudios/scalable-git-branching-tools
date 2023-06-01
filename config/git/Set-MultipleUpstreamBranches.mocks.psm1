Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-VerifyMock.psm1"

function Lock-SetMultipleUpstreamBranches() {
    Mock -ModuleName 'Set-MultipleUpstreamBranches' -CommandName Set-GitFiles -MockWith {
        throw "Set-MultipleUpstreamBranches was not set up for this test, $commitMessage, $($files | ConvertTo-Json)"
    }
}

function Initialize-SetMultipleUpstreamBranches([PSObject] $upstreamBranches, [string] $commitMessage, [string] $resultCommitish) {
    Initialize-FetchUpstreamBranch
    Lock-SetMultipleUpstreamBranches
    $contents = ($upstreamBranches.Keys | ForEach-Object { "`$files['$_'] -eq '$($upstreamBranches[$_] -join "`n")'" }) -join ' -AND '

    $result = New-VerifiableMock `
        -CommandName Set-GitFiles `
        -ModuleName 'Set-MultipleUpstreamBranches' `
        -ParameterFilter $([scriptblock]::Create("`$commitMessage -eq '$($commitMessage.Replace("'", "''"))' -AND $contents"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $resultCommitish
        }.GetNewClosure()
    return $result
}
Export-ModuleMember -Function Lock-SetMultipleUpstreamBranches, Initialize-SetMultipleUpstreamBranches

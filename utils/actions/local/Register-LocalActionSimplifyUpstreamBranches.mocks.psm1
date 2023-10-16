Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSimplifyUpstreamBranches.psm1"

function Lock-LocalActionSimplifyUpstreamBranches() {
    Mock -ModuleName 'Register-LocalActionSimplifyUpstreamBranches' -CommandName Compress-UpstreamBranches -MockWith {
        throw "Register-LocalActionSimplifyUpstreamBranches was not set up for this test, $originalUpstream"
    }
}

function Initialize-LocalActionSimplifyUpstreamBranchesSuccess(
    [string[]] $from,
    [string[]] $to
) {
    Lock-LocalActionSimplifyUpstreamBranches
    foreach ($branch in $from) {
        Initialize-AssertValidBranchName $branch
    }

    $contents = (@(
         "`$originalUpstream.Count -eq $($from.Count)"
        "(`$originalUpstream -join ',') -eq '$($from  -join ',')'"
     ) | ForEach-Object { $_ } | Where-Object { $_ -ne $null }) -join ' -AND '

    $result = New-VerifiableMock `
        -CommandName Compress-UpstreamBranches `
        -ModuleName 'Register-LocalActionSimplifyUpstreamBranches' `
        -ParameterFilter $([scriptblock]::Create($contents))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $to
        }.GetNewClosure()
    return $result
}

Export-ModuleMember -Function Initialize-LocalActionSimplifyUpstreamBranchesSuccess

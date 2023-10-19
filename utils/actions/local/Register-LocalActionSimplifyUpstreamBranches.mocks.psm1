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
        $from | ForEach-Object { "`$originalUpstream -contains '$_'" }
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

# Uses expected upstream branches to determine simplification
function Initialize-LocalActionSimplifyUpstreamBranches(
    [string[]] $from
) {
    foreach ($branch in $from) {
        Initialize-AssertValidBranchName $branch
    }
}

Export-ModuleMember -Function Initialize-LocalActionSimplifyUpstreamBranchesSuccess,Initialize-LocalActionSimplifyUpstreamBranches

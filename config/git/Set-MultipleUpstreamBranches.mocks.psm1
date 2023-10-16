Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state/Get-UpstreamBranch.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"

function Lock-SetMultipleUpstreamBranches() {
    Mock -ModuleName 'Set-MultipleUpstreamBranches' -CommandName Set-GitFiles -MockWith {
        throw "Set-MultipleUpstreamBranches was not set up for this test, $commitMessage, $($files | ConvertTo-Json)"
    }
}

function Initialize-SetMultipleUpstreamBranches([PSObject] $upstreamBranches, [string] $commitMessage, [string] $commitish) {
    Initialize-FetchUpstreamBranch
    Lock-SetMultipleUpstreamBranches
    $contents = (@(
        $commitMessage -ne '' ? "`$commitMessage -eq '$($commitMessage.Replace("'", "''"))'" : $nil
        $upstreamBranches -ne $nil ? @(
            "`$files.Keys.Count -eq $($upstreamBranches.Keys.Count)"
            ($upstreamBranches.Keys | ForEach-Object {
                if ($upstreamBranches[$_] -eq $nil) {
                    "`$files['$_'] -eq `$nil"
                } else {
                    "`$files['$_'] -eq ('$($upstreamBranches[$_] -join "`n")' + `"``n`")"
                }
            })
        ) : $nil
     ) | ForEach-Object { $_ } | Where-Object { $_ -ne $nil }) -join ' -AND '

    $result = New-VerifiableMock `
        -CommandName Set-GitFiles `
        -ModuleName 'Set-MultipleUpstreamBranches' `
        -ParameterFilter $([scriptblock]::Create($contents))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $commitish
        }.GetNewClosure()
    return $result
}
Export-ModuleMember -Function Lock-SetMultipleUpstreamBranches, Initialize-SetMultipleUpstreamBranches

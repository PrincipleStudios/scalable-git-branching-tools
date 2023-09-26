Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"

function Lock-LocalActionSetUpstream() {
    Mock -ModuleName 'Register-LocalActionSetUpstream' -CommandName Set-GitFiles -MockWith {
        throw "Register-LocalActionSetUpstream was not set up for this test, $commitMessage, $($files | ConvertTo-Json)"
    }
}

function Initialize-LocalActionSetUpstream([PSObject] $upstreamBranches, [string] $message, [string] $commitish) {
    Lock-LocalActionSetUpstream
    $contents = (@(
        $message -ne '' ? "`$message -eq '$($message.Replace("'", "''"))'" : $nil
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
        -ModuleName 'Register-LocalActionSetUpstream' `
        -ParameterFilter $([scriptblock]::Create($contents))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $commitish
        }.GetNewClosure()
    return $result
}
Export-ModuleMember -Function Lock-LocalActionSetUpstream, Initialize-LocalActionSetUpstream

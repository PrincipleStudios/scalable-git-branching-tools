Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionRecurse.psm1"

function Initialize-LocalActionRecurseSuccess(
    [Parameter(Mandatory)][string] $ScriptName,
    [Parameter(Mandatory)][string] $ScriptContents
) {
    $mockScriptFullPath = "$PSScriptRoot/../../../$ScriptName"
    Mock -CommandName Get-Content `
        -ModuleName "Register-LocalActionRecurse" `
        -ParameterFilter $([scriptblock]::Create("`$path -eq '$mockScriptFullPath'")) -MockWith {
        $ScriptContents
    }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-LocalActionRecurseSuccess

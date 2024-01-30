Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.internal.psm1"

function Initialize-FakeLocalAction(
    [Parameter(Mandatory)][string] $actionType,
    [Parameter()][scriptblock] $returns
) {
    Mock -CommandName Get-LocalAction `
        -ModuleName "Invoke-LocalAction.internal" `
        -ParameterFilter $([scriptblock]::Create("`$type -eq '$actionType'")) -MockWith {
            return $returns
        }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-FakeLocalAction

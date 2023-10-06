Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"

function Invoke-ScriptedCommand {
    [OutputType([scriptblock])]
    param (
        [Parameter(Mandatory)][scriptblock] $action
    )

    return {
        try {
            Write-Host "running $action"
            & $action
        } catch {
            try {
                # Ensure diagnostics are flushed. Register-Framework will reuse the diagnostic array
                $diag = New-Diagnostics
                Assert-Diagnostics $diag
            } catch { }

            throw
        }
    }
}

Export-ModuleMember -Function Invoke-ScriptedCommand

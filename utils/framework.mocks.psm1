Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.mocks.psm1"

function Register-Framework {
    [OutputType([System.Collections.ArrayList])]
    Param (
        [switch] $throwInsteadOfExit
    )

    Register-ProcessLog
    $diagnostics = Register-Diagnostics -throwInsteadOfExit:$throwInsteadOfExit
    return @{
        diagnostics = $diagnostics
    }
}

Export-ModuleMember -Function Register-Diagnostics, Register-Framework, Clear-ProcessLogs, Get-ProcessLogs

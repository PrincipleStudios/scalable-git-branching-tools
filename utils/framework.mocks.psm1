Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteBlob.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteTree.mocks.psm1"

function Register-Framework {
    [OutputType([System.Collections.ArrayList])]
    Param (
        [switch] $throwInsteadOfExit
    )

    . "$PSScriptRoot/../config/testing/Lock-Git.mocks.ps1"

    Register-ProcessLog
    $diagnostics = Register-Diagnostics -throwInsteadOfExit:$throwInsteadOfExit
    return @{
        diagnostics = $diagnostics
    }

    Lock-InvokeWriteBlob
    Lock-InvokeWriteTree
}

Export-ModuleMember -Function Register-Framework `
    , New-Diagnostics, Register-Diagnostics, Get-DiagnosticStrings `
    , Clear-ProcessLogs, Get-ProcessLogs `
    , Initialize-WriteBlob `
    , Initialize-WriteTree

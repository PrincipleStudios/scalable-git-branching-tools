Import-Module -Scope Local "$PSScriptRoot/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteBlob.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteTree.mocks.psm1"

function Register-Framework {
    [OutputType([System.Collections.ArrayList])]
    Param (
        [switch] $throwInsteadOfExit
    )

    . "$PSScriptRoot/testing.ps1"

    Register-ProcessLog
    $diag = New-Diagnostics
    Mock -CommandName New-Diagnostics -MockWith { $diag }
    
    $diagnostics = Register-Diagnostics -throwInsteadOfExit
    return @{
        assertDiagnosticOutput = $diagnostics
        diagnostics = $diag
    }

    Lock-InvokeWriteBlob
    Lock-InvokeWriteTree
}

Export-ModuleMember -Function New-Diagnostics, Add-ErrorDiagnostic, Add-ErrorException, Add-WarningDiagnostic, Assert-Diagnostics `
    , Invoke-ProcessLogs `
    , Register-Framework `
    , New-Diagnostics, Register-Diagnostics, Get-DiagnosticStrings `
    , Clear-ProcessLogs, Get-ProcessLogs

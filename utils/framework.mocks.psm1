Import-Module -Scope Local "$PSScriptRoot/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteBlob.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteTree.mocks.psm1"

function Register-Framework {
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

function Invoke-FlushAssertDiagnostic(
    [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    try { Assert-Diagnostics $diagnostics } catch { }
}

Export-ModuleMember -Function New-Diagnostics, Add-ErrorDiagnostic, Add-ErrorException, Add-WarningDiagnostic, Assert-Diagnostics, Get-HasErrorDiagnostic `
    , Invoke-ProcessLogs `
    , Register-Framework, Invoke-FlushAssertDiagnostic `
    , New-Diagnostics, Register-Diagnostics, Get-DiagnosticStrings `
    , Clear-ProcessLogs, Get-ProcessLogs

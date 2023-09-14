Import-Module -Scope Local "$PSScriptRoot/diagnostic-framework.psm1"

function Register-Diagnostics {
    [OutputType([System.Collections.ArrayList])]
    Param (
        [switch] $throwInsteadOfExit
    )

    $prevNewLine = $true
    $result = New-Object -TypeName 'System.Collections.ArrayList'

    New-Variable -Name "mockPrevNewLine" -Value $prevNewLine -Scope "script" -Force
    New-Variable -Name "mockDiagnosticResult" -Value $result -Scope "script" -Force

    if ($throwInsteadOfExit) {
        Mock -ModuleName 'diagnostic-framework' -CommandName 'Exit-DueToAssert' { throw 'Fake Exit-DueToAssert' }
    }
    Mock -ModuleName 'diagnostic-framework' Write-Host {
        if ($mockPrevNewLine) {
            $mockDiagnosticResult.Add([string]$Object) *> $nil
        } else {
            $mockDiagnosticResult[$mockDiagnosticResult.count - 1] += [string]$Object
        }
        $script:mockPrevNewLine = -not $NoNewLine
    }

    return @(,$result)
}

function Get-DiagnosticStrings(
    [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $output = Register-Diagnostics -throwInsteadOfExit
    try
    {
        Assert-Diagnostics $diagnostics
    } catch { }
    return $output
}

Export-ModuleMember -Function New-Diagnostics, Register-Diagnostics, Get-DiagnosticStrings


function Register-Diagnostics {
    [OutputType([System.Collections.ArrayList])]
    Param ()

    $prevNewLine = $true
    $result = New-Object -TypeName 'System.Collections.ArrayList'

    New-Variable -Name "mockPrevNewLine" -Value $prevNewLine -Scope "script" -Force
    New-Variable -Name "mockDiagnosticResult" -Value $result -Scope "script" -Force

    Mock -ModuleName 'diagnostic-framework' Write-Host {
        if ($mockPrevNewLine) {
            $mockDiagnosticResult.Add([string]$Object)
        } else {
            $mockDiagnosticResult[$mockDiagnosticResult.count - 1] += [string]$Object
        }
        $script:mockPrevNewLine = -not $NoNewLine
    }

    return @(,$result)
}

Export-ModuleMember -Function Register-Diagnostics

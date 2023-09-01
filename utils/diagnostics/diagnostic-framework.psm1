
function New-Diagnostics {
    [OutputType([System.Collections.ArrayList])]
    Param ()

    return New-Object -TypeName 'System.Collections.ArrayList'
}

function New-ErrorDiagnostic(
    [Parameter(Mandatory)][string] $message
) {
    return @{ message = $message; level = 'error' }
}

function New-WarningDiagnostic(
    [Parameter(Mandatory)][string] $message
) {
    return @{ message = $message; level = 'warning' }
}

function Add-Diagnostic(
    [Parameter()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter()][psobject] $diagnostic
) {
    if ($nil -ne $diagnostics) {
        $diagnostics.Add($diagnostic)
    } else {
        throw $diagnostic.message
    }
}

function Assert-Diagnostics(
    [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    if ($diagnostics -ne $nil) {
        $shouldExit = $false
        foreach ($diagnostic in $diagnostics) {
            switch ($diagnostic.level) {
                'error' {
                    Write-Host 'ERR:  ' -ForegroundColor Red -BackgroundColor Black -NoNewline
                    $shouldExit = $true
                }
                'warning' {
                    Write-Host 'WARN: ' -ForegroundColor Yellow -BackgroundColor Black -NoNewline
                }
            }
            Write-Host $diagnostic.message
        }
        if ($shouldExit) {
            exit 1
        }
    }
}

Export-ModuleMember -Function New-Diagnostics, New-ErrorDiagnostic, New-WarningDiagnostic, Add-Diagnostic, Assert-Diagnostics

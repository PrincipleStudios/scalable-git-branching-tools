
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
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter(Mandatory)][psobject] $diagnostic
) {
    if ($nil -ne $diagnostics) {
        $diagnostics.Add($diagnostic) *> $null
    } else {
        if ($diagnostic.level -eq 'error') {
            throw $diagnostic.message
        }
    }
}

function Add-ErrorDiagnostic(
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter(Mandatory)][string] $message
) {
    Add-Diagnostic $diagnostics (New-ErrorDiagnostic $message)
}

function Add-ErrorException(
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter(Mandatory)][System.Management.Automation.ErrorRecord] $exception
) {
    Add-Diagnostic $diagnostics (New-ErrorDiagnostic "$($exception.Exception.Message)`n$($exception.ScriptStackTrace)")
}

function Add-WarningDiagnostic(
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [Parameter(Mandatory)][string] $message
) {
    Add-Diagnostic $diagnostics (New-WarningDiagnostic $message)
}

function Get-HasErrorDiagnostic(
    [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    return ($diagnostics | Where-Object { $_.level -eq 'error' }).Count -gt 0
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
            Exit-DueToAssert
        } else {
            $diagnostics.Clear()
        }
    }
}

function Exit-DueToAssert {
    exit 1
}

Export-ModuleMember -Function New-Diagnostics, Add-ErrorDiagnostic, Add-ErrorException, Add-WarningDiagnostic, Assert-Diagnostics, Get-HasErrorDiagnostic

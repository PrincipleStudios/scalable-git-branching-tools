Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

function Assert-CleanWorkingDirectory(
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $cleanOutput = Invoke-ProcessLogs "git clean -n" {
        git clean -n
    } -allowSuccessOutput
    Invoke-ProcessLogs "git diff --stat" {
        git diff --stat --exit-code
    }

    if ($LASTEXITCODE -ne 0 -OR $null -ne $cleanOutput) {
        Add-ErrorDiagnostic $diagnostics 'Git working directory is not clean.'
    }
}

Export-ModuleMember -Function Assert-CleanWorkingDirectory

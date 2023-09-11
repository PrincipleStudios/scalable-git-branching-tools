Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

function Assert-CleanWorkingDirectory(
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $cleanOutput = Invoke-ProcessLogs "git clean -n" {
        git clean -n
    } -allowSuccessOutput -quiet
    Invoke-ProcessLogs "git diff --stat $($config.remote)" {
        git diff --stat --exit-code
    } -quiet

    if ($LASTEXITCODE -ne 0 -OR $cleanOutput -ne $nil) {
        Add-ErrorDiagnostic $diagnostics 'Git working directory is not clean.'
    }
}

Export-ModuleMember -Function Assert-CleanWorkingDirectory

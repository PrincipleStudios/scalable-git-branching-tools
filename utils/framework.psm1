Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.psm1"

Export-ModuleMember -Function New-Diagnostics, Add-ErrorDiagnostic, Add-WarningDiagnostic, Assert-Diagnostics `
    , Invoke-ProcessLogs

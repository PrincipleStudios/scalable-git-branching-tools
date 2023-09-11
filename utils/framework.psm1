Import-Module -Scope Local "$PSScriptRoot/framework/diagnostic-framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/framework/processlog-framework.psm1"

Export-ModuleMember -Function Assert-Diagnostics, New-Diagnostics, Invoke-ProcessLogs, Add-ErrorDiagnostic, Add-WarningDiagnostic

Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"

function Invoke-AddDiagnosticLocalAction {
    param(
        [Parameter()][string] $message,
        [switch] $isWarning,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    if ($isWarning) {
        Add-WarningDiagnostic $diagnostics $message
    } else {
        Add-ErrorDiagnostic $diagnostics $message
    }

    return @{}
}

Export-ModuleMember -Function Invoke-AddDiagnosticLocalAction

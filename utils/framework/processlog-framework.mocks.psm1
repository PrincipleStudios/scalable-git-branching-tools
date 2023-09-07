Import-Module -Scope Local "$PSScriptRoot/processlog-framework.psm1"

function Register-ProcessLog {
    Clear-ProcessLogs
    Mock -ModuleName 'processlog-framework' Write-Host {
        # Hide "Begin"/"End" messages
    }
}

Export-ModuleMember -Function Register-ProcessLog

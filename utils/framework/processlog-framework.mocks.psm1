Import-Module -Scope Local "$PSScriptRoot/processlog-framework.psm1"

function Register-ProcessLog {
    Clear-ProcessLogs
    # Hide "Begin"/"End" messages
    Mock -ModuleName 'processlog-framework' -CommandName 'Get-IsQuiet' { return $true }
    Mock -ModuleName 'processlog-framework' -CommandName 'Write-Host' { 
        # Hides output from Show-ProcessLog
    }
}

Export-ModuleMember -Function Register-ProcessLog

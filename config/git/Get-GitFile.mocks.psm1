Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"

function Initialize-GitFile([string]$branch, [string] $path, [object] $contents) {
    Invoke-MockGitModule -ModuleName 'Get-GitFile' -gitCli "cat-file -p $($branch):$($path)" -MockWith $contents
}

Export-ModuleMember -Function Initialize-GitFile

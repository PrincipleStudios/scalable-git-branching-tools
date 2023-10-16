Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-MergeTree.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-MergeTree' @PSBoundParameters
}

function Initialize-MergeTree(
    [Parameter(Mandatory)][string] $commitishA, 
    [Parameter(Mandatory)][string] $commitishB, 
    [string] $resultTree,
    [string[]] $conflictingFiles,
    [switch] $fail
) {
    Invoke-MockGit "merge-tree --name-only --write-tree --no-messages $commitishA $commitishB" {
        $resultTree
        foreach ($e in $conflictingFiles) {
            $e
        }
        if ($fail -OR $conflictingFiles.Count -gt 0) {
            $global:LASTEXITCODE = 1
        }
    }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-MergeTree
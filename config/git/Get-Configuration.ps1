. $PSScriptRoot/../core/Coalesce.ps1

function Get-Configuration() {
    return @{
        remote = git config scaled-git.remote
    }
}

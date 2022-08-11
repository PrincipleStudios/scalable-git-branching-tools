. $PSScriptRoot/../core/coalesce.ps1

function Get-Configuration() {
    $remote = git config scaled-git.remote
    if ($remote -eq $nil) {
        $remote = git remote | Select-Object -First 1
    }
    return @{
        remote = $remote
        upstreamBranch = (Coalesce (git config scaled-git.upstreamBranch) "_upstream")
    }
}

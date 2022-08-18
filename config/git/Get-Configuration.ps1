. $PSScriptRoot/../core/coalesce.ps1

function Get-Configuration() {
    $remote = git config scaled-git.remote
    if ($remote -eq $nil) {
        $remote = git remote | Select-Object -First 1
    }
    return @{
        remote = $remote
        upstreamBranch = (Coalesce (git config scaled-git.upstreamBranch) "_upstream")
        defaultServiceLine = Get-DefaultServiceLine -remote $remote
    }
}

function Get-DefaultServiceLine([string]$remote) {
    $result = (git config scaled-git.defaultServiceLine)
    if ($result -ne $nil) { return $result }

    $commitish = git rev-parse --verify ($remote -eq $nil -OR $remote -eq '' ? 'main' : "$($remote)/main") -q 2> $nil
    if ($LASTEXITCODE -eq 0) {
        return "main"
    }
    return $nil
}

function Get-GitFile([Parameter()]$path, [Parameter()]$branch) {
    return (git cat-file -p "$($branch):$($path)" 2> $nil)
}

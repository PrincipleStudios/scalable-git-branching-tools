function Get-GitFile([Parameter()]$path, [Parameter()]$branch) {
    $args = @("cat-file", "-p", "$($branch):$($path)")
    return (git @args 2> $nil)
}

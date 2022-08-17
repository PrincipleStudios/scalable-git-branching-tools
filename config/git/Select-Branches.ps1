function Select-Branches([Parameter(Mandatory)][PSObject] $config) {
    $remote = $config.remote
    $temp = $remote -eq $nil ? (git branch) : (git branch -r)
    return $temp | Foreach-Object { $_.split("`n") } | Foreach-Object {
        if ($remote -eq $nil) {
            $branchName = $_.Trim()
        } else {
            $split = $_.Trim().Split('/')
            if ($remote -ne $split[0]) {
                return $nil
            }
            $branchName = $split[1..($split.Length-1)] -join '/'
            if ($branchName -eq "") {
                return $nil
            }
        }

        return @{ remote = $remote; branch = $branchName }
    } | Where-Object { $_ -ne $nil }
}

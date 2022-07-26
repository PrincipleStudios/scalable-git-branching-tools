. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1
. $PSScriptRoot/Get-Configuration.ps1

function Select-Branches() {
    $config = (Get-Configuration)
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

        $info = ConvertTo-BranchInfo $branchName
        if ($info -eq $nil) {
            return @{ remote = $remote; branch = $branchName }
        }
        $info.remote = $remote
        $info.branch = $branchName
        return $info
    } | Where-Object { $_ -ne $nil }
}

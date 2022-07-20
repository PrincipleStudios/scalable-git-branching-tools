. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1
. $PSScriptRoot/Get-Configuration.ps1

function Select-Branches() {
    $remote = (Get-Configuration).remote
    $temp = (git branch -r)
    return $temp | Foreach-Object { $_.split("`n") } | Foreach-Object {
        $split = $_.Trim().Split('/')
        if ($remote -ne $nil -AND $remote -ne $split[0]) {
            return $nil
        }
        $branchName = $split[1..($split.Length-1)] -join '/'
        if ($branchName -eq "") {
            return $nil
        }

        $info = ConvertTo-BranchInfo $branchName
        if ($info -eq $nil) {
            return @{ remote = $split[0]; branch = $branchName }
        }
        $info.remote = $split[0]
        $info.branch = $branchName
        return $info
    } | Where-Object { $_ -ne $nil }
}

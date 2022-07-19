# . $PSScriptRoot/../Variables.ps1
. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1

function Select-Branches() {
    $temp =(git branch -r)
    return $temp | Foreach-Object { $_.split("`n") } | Foreach-Object {
        $split = $_.Trim().Split('/')
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

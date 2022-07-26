
function ConvertTo-BranchName($branchInfo, [switch] $includeRemote) {
    return ($includeRemote -AND $branchInfo.remote -ne $nil) ? "$($branchInfo.remote)/$($branchInfo.branch)" : $branchInfo.branch
}

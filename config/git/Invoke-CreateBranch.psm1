function Invoke-CreateBranch([String]$branchName, [String]$source) {
    git branch $branchName $source --quiet --no-track
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create new branch '$branchName' from '$($source)'"
    }
}
Export-ModuleMember -Function Invoke-CreateBranch

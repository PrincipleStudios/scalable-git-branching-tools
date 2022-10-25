
function Invoke-CreateBranch([String]$branchName, [String]$source) {
    git branch $branchName $source --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create new branch '$branchName' from '$($source)'"
    }
}

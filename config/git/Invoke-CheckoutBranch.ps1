
function Invoke-CheckoutBranch([String]$branchName, [switch]$quiet) {
    git checkout $branchName --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Could not checkout newly created branch '$branchName'"
    }

    if (-not $quiet) {
        Write-Host "Checked out new branch '$branchName'."
    }
}
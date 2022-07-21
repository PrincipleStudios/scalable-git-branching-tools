
function Invoke-MergeBranches([String[]] $branches, [switch]$quiet, [switch]$noAbort) {
    $branches | ForEach-Object {
        git merge $_ --quiet --commit --no-edit --no-squash
        if ($LASTEXITCODE -ne 0) {
            if (-not $noAbort) {
                git merge --abort
            }
            throw "Could not merge all branches. Failed to merge '$_'."
        }
    }
    
    if (-not $quiet) {
        Write-Host "All branches merged successfully."
    }
}

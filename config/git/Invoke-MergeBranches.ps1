
class SuccessfulMergeResult {
    [string] ToString() {
        return "Successfully merged branches"
    }

    [void] ThrowIfInvalid() {}
}

class InvalidMergeResult {
    [string] $branch

    InvalidMergeResult([string] $branch) {
        $this.branch = $branch
    }

    [string] ToString() {
        return "Failed to merge the branch(es): $($this.branch)"
    }

    [string] ThrowIfInvalid() {
        throw New-Object InvalidMergeException $this.branch
    }
}

class InvalidMergeException : InvalidOperationException {
    [string] $branch

    InvalidMergeException([String] $branch) : base('Could not complete the merge.') {
        $this.branch = $branch
    }

    [InvalidMergeResult] ToResult() {
        return New-Object InvalidMergeResult $this.branch
    }
}

function Invoke-MergeBranches([String[]] $branches, [switch]$quiet, [switch]$noAbort) {
    try {
        $branches | Where-Object { $_ -ne $nil } | ForEach-Object {
            git merge $_ --quiet --commit --no-edit --no-squash
            if ($LASTEXITCODE -ne 0) {
                if (-not $noAbort) {
                    git merge --abort
                }
                throw New-Object InvalidMergeException $_
            }
        }
    } catch [InvalidMergeException] {
        if (-not $quiet) {
            Write-Host "Failed to merge $($_.Exception.branch)"
        }
        return $_.Exception.ToResult()
    }

    if (-not $quiet) {
        Write-Host "All branches merged successfully."
    }
    return New-Object SuccessfulMergeResult
}

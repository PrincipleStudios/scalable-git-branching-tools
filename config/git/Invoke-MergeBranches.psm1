
class MergeResult {
    [boolean] $isValid
    [string] $branch

    MergeResult([boolean] $isValid) {
        $this.isValid = $isValid
        if (-not $isValid) {
            throw "Cannot create a failed MergeResult without specifying the branch."
        }
        $this.branch = $global:nil
    }

    MergeResult([boolean] $isValid, [string] $branch) {
        $this.isValid = $isValid
        $this.branch = $branch
    }

    [string] ToString() {
        return $this.isValid ? "Successfully merged branches" : "Failed to merge the branch(es): $($this.branch)"
    }

    [void] ThrowIfInvalid() {
        if (-not $this.isValid) {
            throw New-Object InvalidMergeException $this.branch
        }
    }
}

class InvalidMergeException : InvalidOperationException {
    [string] $branch

    InvalidMergeException([String] $branch) : base('Could not complete the merge.') {
        $this.branch = $branch
    }

    [MergeResult] ToResult() {
        return [MergeResult]::new($false, $this.branch)
    }
}

function Invoke-MergeBranches {
    [OutputType([MergeResult])]
    Param([String[]] $branches, [switch]$quiet, [switch]$noAbort)

    try {
        $branches | Where-Object { $_ -ne $nil } | ForEach-Object {
            git merge $_ --quiet --commit --no-edit --no-squash | Write-Host
            if ($LASTEXITCODE -ne 0) {
                if (-not $noAbort) {
                    git merge --abort | Write-Host
                }
                throw New-Object InvalidMergeException $_
            }
        }
    } catch [InvalidMergeException] {
        if (-not $quiet) {
            Write-Host -ForegroundColor red "Failed to merge $($_.Exception.branch)"
        }
        return $_.Exception.ToResult()
    }

    if (-not $quiet) {
        Write-Host "All branches merged successfully."
    }
    return New-Object MergeResult $true
}

Export-ModuleMember -Function Invoke-MergeBranches

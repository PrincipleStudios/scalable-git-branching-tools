Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

# While this function actually writes the tree to git's object store, it doesn't have any serious side effects (like updating refs, working directory, etc.)
# so it is placed in the query-state folder.
function Get-MergeTree([string]$commitishA, [string]$commitishB) {
	$output = Invoke-ProcessLogs "git merge-tree --name-only --write-tree --no-messages $commitishA $commitishB" {
        git merge-tree --name-only --write-tree --no-messages $commitishA $commitishB
    } -allowSuccessOutput -quiet
	$isClean = $global:LASTEXITCODE -eq 0 # git-merge-tree uses 0 for clean, 1 for not, and <0 for various other errors
	return [ordered]@{
		isSuccess = $isClean;
		treeish = $output | Select-Object -First 1
		# Just because this list is empty doesn't mean there aren't issues merging
		conflicts = ($output | Select-Object -Skip 1)
	}
}

Export-ModuleMember -Function Get-MergeTree

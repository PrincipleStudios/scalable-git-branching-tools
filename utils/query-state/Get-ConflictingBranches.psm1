Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranchMap.psm1"

function Get-LastTouchedBranch {
	Param(
		[Parameter(Mandatory)][String] $upstreamMap,
		[Parameter(Mandatory)][String] $branchName,
		[Parameter(Mandatory)][String] $file
	)

	$temp = $upstreamMap[$branchName];
	$result = git name-rev --name-only @temp (git rev-list -1 "$branchName" -- "$file")
	return $result.split("~")[0].split("^")[0]
}

function Get-MergeConflicts([string]$a, [string]$b) {
	$output = git merge-tree --name-only --write-tree $a $b 
	$isClean = $LASTEXITCODE -eq 0 # git-merge-tree uses 0 for clean, 1 for not, and <0 for various other errors
	return [ordered]@{
		isClean = $isClean;
		# Just because this list is empty doesn't mean there aren't conflicts
		conflictList = ($output | Select-Object -Skip 1).Where({ $_ -eq "" }, [System.Management.Automation.WhereOperatorSelectionMode]::Until)
	}
}

function Get-ConflictingBranches([string]$base = (git rev-parse --abbrev-ref HEAD), [string] $mergeCandidate) {
	$files_by_branch = @{}
	$upstreamMap = Get-UpstreamBranchMap;
	try {
		$upstreamMap["origin/$base"] | ForEach-Object {
			$conflictInfo = Get-MergeConflicts $_ $mergeCandidate
			if (-not $conflictInfo.isClean) {
				Write-Host "x" -NoNewline
				$files_by_branch[$_] = $conflictInfo.conflictList
			} else {
				Write-host "." -NoNewline
			}
		}
		Write-Host ""
	} finally {
		# hrm...
	}
	$files_by_branch.Keys | ForEach-Object {
		$branch = $_
		Write-Host $branch
		Write-Host
		$files_by_branch[$branch] | ForEach-Object {
			Write-Host -NoNewline "`t"
			Write-Host $_
			Write-Host -NoNewline "`t"
			Write-Host (Get-LastTouchedBranch -upstreamMap $upstreamMap -branchName $branch -file $_)
			Write-Host
		}
		Write-Host
	} 
}

Export-ModuleMember -Function Get-ConflictingBranches
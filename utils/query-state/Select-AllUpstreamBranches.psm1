Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

# allUpstreams is a hashmap where the key is the git working directory and 
$allUpstreams = @{}
$treeSuffix = '^{tree}'

function Select-AllUpstreamBranches([switch]$refresh) {
	$workDir = Invoke-ProcessLogs "git rev-parse --show-toplevel" {
		git rev-parse --show-toplevel
	} -allowSuccessOutput
	if ($allUpstreams[$workDir] -AND -not $refresh) {
		return $allUpstreams[$workDir]
	}

	$nodes = $allUpstreams[$workDir] = @{}

	$upstreamBranch = Get-UpstreamBranch

	$queue = New-Object 'System.Collections.Generic.Queue[object]';

	# Load all upstream branch configurations to the hashmap
	$queue.Enqueue($null)
	while ($queue.Count -gt 0) {
		$baseName = $queue.Dequeue()
		$treeish = "$upstreamBranch$($baseName ? ":$baseName" : $treeSuffix)"
		$treeEntries = Invoke-ProcessLogs "git ls-tree $treeish" {
			git ls-tree $treeish
		} -allowSuccessOutput
		foreach ($entry in $treeEntries) {
			# entry is (permission ' ' ('tree' | 'blob') ' ' hash '`t' name)
			$record, $name = $entry.Split("`t")
			$permission, $type, $hash = $record.Split(' ')
			$name = $baseName ? "$baseName/$name" : $name
			if ($type -eq 'tree') {
				$queue.Enqueue($name)
			} else {
				$nodes[$name] = Get-GitFile $name $upstreamBranch
			}
		}
	}
	return $nodes
}

function Clear-AllUpstreamBranchCache([string] $workDir) {
	if ($workDir) {
		$allUpstreams[$workDir] = $null
	} else {
		$allUpstreams = @{}
	}
}

Export-ModuleMember -Function Select-AllUpstreamBranches, Clear-AllUpstreamBranchCache

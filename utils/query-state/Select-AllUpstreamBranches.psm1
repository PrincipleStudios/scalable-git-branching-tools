Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

# allUpstreams is a hashmap where the key is the git working directory and 
$allUpstreams = @{}

function Select-AllUpstreamBranches([switch]$refresh) {
	$workDir = Invoke-ProcessLogs "git rev-parse --show-toplevel" {
		git rev-parse --show-toplevel
	} -allowSuccessOutput
	if ($allUpstreams[$workDir] -AND -not $refresh) {
		return $allUpstreams[$workDir]
	}

	$nodes = $allUpstreams[$workDir] = @{}

	$upstreamBranch = Get-UpstreamBranch

	$treeEntries = Invoke-ProcessLogs "git ls-tree -r $upstreamBranch --format=`"%(objectname)`t%(path)`"" {
		git ls-tree -r $upstreamBranch "--format=%(objectname)`t%(path)"
	} -allowSuccessOutput

	# build "$blobs", a Dictionary<hash, contents-split-by-line>
	$hashes = $treeEntries | ForEach-Object { $_.Split("`t")[0] }
	if ($hashes) {
		$hashEntries = (Invoke-ProcessLogs "git cat-file '--batch=`t%(objectname)'" {
			# --batch gives a header, in this case:"`t<blobhash>", followed by a new line,
			# followed by the contents of the file, followed by two line breaks.
			# Empty files, therefore, would have three subsequent line breaks and make the whole result messy
			# I hope that no one adds files with "`t" in them.
			$hashes | git cat-file "--batch=`t%(objectname)"
		} -allowSuccessOutput) -join "`n" -split "`t" | Where-Object { $_ } | ForEach-Object { $_.Trim() }
		$blobs = @{}
		foreach ($entry in $hashEntries) {
			$lines = $entry.Split("`n")
			$blobs[$lines[0]] = $lines | Select-Object -Skip 1
		}

		foreach ($entry in $treeEntries) {
			# entry is (hash '`t' name)
			$hash, $name = $entry.Split("`t")
			[string[]]$nodes[$name] = $blobs[$hash]
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

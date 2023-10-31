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

	$treeEntries = Invoke-ProcessLogs "git ls-tree -r $upstreamBranch --format=`"%(path)`"" {
		git ls-tree -r $upstreamBranch '--format=%(path)'
	} -allowSuccessOutput

	foreach ($name in $treeEntries) {
		# TODO - make the Get-GitFile lazy
		$nodes[$name] = Get-GitFile $name $upstreamBranch
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

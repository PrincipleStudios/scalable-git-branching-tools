Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
	return Invoke-MockGitModule -ModuleName 'Select-AllUpstreamBranches' @PSBoundParameters
}

function Initialize-AllUpstreamBranches([PSObject] $upstreamConfiguration) {
	$upstream = Get-UpstreamBranch
	$workDir = [System.IO.Path]::GetRandomFileName()
	Invoke-MockGit "rev-parse --show-toplevel" -MockWith $workDir

	$treeEntries = $upstreamConfiguration.Keys | Sort-Object
	Invoke-MockGit "ls-tree -r $upstream --format=%(path)" -MockWith $treeEntries

	foreach ($branch in $upstreamConfiguration.Keys) {
		$branchFile = $upstreamConfiguration[$branch]
		Initialize-GitFile $upstream $fullPath $branchFile
	}
}
Export-ModuleMember -Function Initialize-AllUpstreamBranches

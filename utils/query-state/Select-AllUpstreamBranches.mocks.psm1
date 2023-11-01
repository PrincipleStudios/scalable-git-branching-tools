Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
	return Invoke-MockGitModule -ModuleName 'Select-AllUpstreamBranches' @PSBoundParameters
}

function Initialize-AllUpstreamBranches([PSObject] $upstreamConfiguration) {
	$upstream = Get-UpstreamBranch
	$workDir = [System.IO.Path]::GetRandomFileName()
	Invoke-MockGit "rev-parse --show-toplevel" -MockWith $workDir

	$treeEntries = $upstreamConfiguration.Keys | ForEach-Object { "100644 blob $_-blob`t$_" } | Sort-Object
	Invoke-MockGit "ls-tree -r $upstream" -MockWith $treeEntries

	if ($upstreamConfiguration.Count -gt 0) {
		$result = ($upstreamConfiguration.Keys | ForEach-Object {
			"`t$_-blob`n$($upstreamConfiguration[$_] -join "`n")"
		}) -join "`n`n"
		Invoke-MockGit "cat-file --batch=`t%(objectname)" -MockWith $result
	}
}
Export-ModuleMember -Function Initialize-AllUpstreamBranches

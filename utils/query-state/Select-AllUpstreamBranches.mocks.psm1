Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
	return Invoke-MockGitModule -ModuleName 'Select-AllUpstreamBranches' @PSBoundParameters
}

$treeSuffix = '^{tree}'

function Initialize-AllUpstreamBranches([PSObject] $upstreamConfiguration) {
	$upstream = Get-UpstreamBranch
	$workDir = [System.IO.Path]::GetRandomFileName()
	Invoke-MockGit "rev-parse --show-toplevel" -MockWith $workDir

	$trees = @{ '' = @{} }

	foreach ($branch in $upstreamConfiguration.Keys) {
		$parts = $branch.Split('/')
		for ($i = 0; $i -lt $parts.Count; $i++) {
			$lastPart = $parts[$i]
			$current = ($parts | Select-Object -First $i) -join '/'
			$fullPath = ($parts | Select-Object -First ($i + 1)) -join '/'
			if ($null -eq $trees[$current]) {
				$trees[$current] = @{}
			}

			if ($i -eq ($parts.Count - 1)) {
				$branchFile = $upstreamConfiguration[$branch]
				Initialize-GitFile $upstream $fullPath $branchFile
				$trees[$current][$lastPart] = "100644 blob hash-ignored`t$lastPart"
			} else {
				$trees[$current][$lastPart] = "040000 tree hash-ignored`t$lastPart"
			}
		}
	}

	foreach ($tree in $trees.Keys) {
		$treeish = "$upstream$($tree ? ":$tree" : $treeSuffix)"
		[string[]]$treeResult = $trees[$tree].Keys | Sort-Object { $_ } | ForEach-Object {
			$trees[$tree][$_]
		}
		Invoke-MockGit "ls-tree $treeish" -MockWith $treeResult
	}
}
Export-ModuleMember -Function Initialize-AllUpstreamBranches

Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Get-GraphLayers($root) {
	$uniqueNamesWithoutMain = $root `
		| ForEach-Object { $_.name } `
		| Where-Object { $_ -ne 'main' } `
		| Sort-Object -Unique;

	$output = ,$uniqueNamesWithoutMain
	$elems = $root | ForEach-Object {
		$_.connections | Where-Object { $_.name -ne 'main' };
	}
	if ($elems.Length -gt 0) {
		$output += Get-GraphLayers $elems;
	}
	return $output;
}

function Write-GraphLayers($layers) {
	[array]::Reverse($layers);
	$seen = New-Object 'System.Collections.Generic.HashSet[string]';

	$layers | ForEach-Object {
		$unseen = $_ | Where-Object { -not $seen.Contains($_) }
		$to_write = $unseen -join ', ';
		if ($to_write.Length -gt 180) {
			Write-Host ($unseen -join "`r`n")
		} else {
			Write-Host $to_write
		}
		$unseen | ForEach-Object {
			$seen.Add($_) > $null;
		}
		Write-Host ("=" * 24)
		Write-Host
	}
}

function Select-UpstreamBranchGraph([String]$branchName) {
	# $config = Get-Configuration
	$upstreamBranch = Get-UpstreamBranch  # Usually _upstream

	$nodes = New-Object 'System.Collections.Generic.Dictionary[string, object]';
	$queue = New-Object 'System.Collections.Generic.Queue[object]';

	# Build a graph of edges, snaking back to main 
	$queue.Enqueue($branchName)
	while ($queue.Count -gt 0 ) {
		$branch = $queue.Dequeue()
		if (-not $nodes.ContainsKey($branch)) {
			$nodes[$branch] = [ordered]@{
				name=$branch;
				connections=New-Object 'System.Collections.Generic.List[object]';
			}
		}
		Get-GitFile $branch $upstreamBranch | ForEach-Object {
			if (-not $nodes.ContainsKey($_)) {
				$nodes[$_] = [ordered]@{
					name=$_;
					connections=New-Object 'System.Collections.Generic.List[object]';
				}
			}
			$nodes[$branch].connections.Add($nodes[$_])
			$queue.Enqueue($_)
		}
	}

	$root = $nodes[$branchName]
	if ($null -eq $root) {
		throw "Main is not in the upstreams of $branchName!"
	}

	Write-Host
	Write-Host
	$layers = Get-GraphLayers $root
	Write-GraphLayers $layers
}

Export-ModuleMember -Function Select-UpstreamBranchGraph


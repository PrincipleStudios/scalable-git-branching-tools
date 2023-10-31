function Get-UpstreamBranchMap([Array]$branches) {
	$upstreams = @{};
	$files = git ls-tree -r origin/_upstream --format="%(objectname)`t%(path)" `
		| ForEach-Object {
			$row = $_ -split "`t"
			[psobject]@{ 
				oid=$row[0];
				path=$row[1] 
			}
		} `
		| Where-Object { 
			$branches -contains $_.path -or $branches.Length -eq 0 
		};

	$blobs = @{}
	(git ls-tree -r origin/_upstream --format="%(objectname)" 
		| git cat-file --batch="%(objectname) %(rest)")  -join "`n" -split "\n\n" `
		| ForEach-Object {
			$lines = $_ -split "\r?\n"
			$blobs[$lines[0].Trim()] = $lines | Select-Object -Skip 1 | ForEach-Object { "origin/$_" }
		}
	$files | ForEach-Object {
		$upstreams["origin/" + $_.path] = $blobs[$_.oid]
	}
	return $upstreams
}

Export-ModuleMember -Function Get-UpstreamBranchMap
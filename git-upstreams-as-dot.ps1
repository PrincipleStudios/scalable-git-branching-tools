#!/usr/bin/env pwsh

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
. $PSScriptRoot/config/core/coalesce.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"

$target = ($target -eq $nil -OR $target -eq '') ? (Get-CurrentBranch) : $target
if ($target -eq $nil) {
    throw 'Must specify a branch'
}

$upstreamMap = Get-UpstreamBranchMap;
$allBranches = $upstreamMap.Keys | ForEach-Object {
	Write-Output $_
	$upstreamMap[$_] | ForEach-Object {
		if ($null -ne $_) {
			Write-Output $upstreamMap[$_]
		}
	}
} | Select-Object -Unique;

$branchNames = @{};
$namesFromids = @{};
$colors = @{};
$branchNameIndex = 0;

$nodes = ($allBranches | ForEach-Object {
	$branch = $_
	$idName = "branch_$branchNameIndex";
	$branchNames[$branch] = $idName
	$namesFromids[$idName] = $branch;
	$branchNameIndex += 1;
	$colors[$idName] = "#{0:X6}" -f (Get-Random -Maximum 0x888888);
	Write-Output "`t$idName [label=`"$_`"];"
}) -join "`n"


$dotEdges = ($upstreamMap.Keys | ForEach-Object {
	$branch = $_;
	$from = $branchNames[$branch];

	$upstreamMap[$branch] | ForEach-Object {
		if ($null -ne $_ -and $branchNames.ContainsKey($_)) {
			$to = $branchNames[$_]
			$tooltip = "From $($namesFromids[$to]) to $branch";
			Write-Output "`t$to -> $from [color=`"$($colors[$to])`", tooltip=`"$tooltip`"];"
		}
	}
} | Select-Object -Unique) -join "`n"

Write-Output @"
digraph  { 
	rankdir=LR;
$nodes
	
$dotEdges
  }
"@
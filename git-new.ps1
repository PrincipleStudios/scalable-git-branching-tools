#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String[]] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type,
    [Switch] $noFetch
)

. $PSScriptRoot/config/Common.ps1

if (-not $noFetch) {
    Update-Git
}

$type = Coalesce $type $defaultFeatureType
$ticketNames = $ticketNames | Where-Object { $_ -ne '' }

$branchName = Format-BranchName $type $ticketNames $comment
$parentBranches = [System.Collections.Generic.List[String]](Select-ParentBranches $branchName -includeRemote)

if ($parentBranches.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

Assert-CleanWorkingDirectory
git branch $branchName $parentBranches[0] --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Could not create new branch '$branchName' from '$($parentBranches[0])'"
}

git checkout $branchName --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Could not checkout newly created branch '$branchName'"
}

Write-Host "Checked out new branch '$branchName'."

$parentBranches | select -skip 1 | ForEach-Object {
    git merge -q $_ --commit --no-squash
    if ($LASTEXITCODE -ne 0) {
        git merge --abort
        throw "Could not merge all parent branches. Failed to merge '$_'."
    }
}

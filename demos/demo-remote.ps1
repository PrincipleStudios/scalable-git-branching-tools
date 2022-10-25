#!/usr/bin/env pwsh

function ThrowOnNativeFalure {
    if ($LASTEXITCODE -ne 0) {
        throw "Native Falure - exit code $LASTEXITCODE"
    }
}

& $PSScriptRoot/_setup-existing.ps1

git clone ./origin local

cd local
/git-tools/init.ps1

git new feature/PS-1 -from feature/add-item-1
ThrowOnNativeFalure

if ((git rev-parse origin/feature/add-item-1) -ne (git rev-parse HEAD)) {
    throw 'HEAD does not point to the same commit as feature/add-item-1';
}

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name did not match expected';
}

$upstreamOfNewFeature = [string[]](git show-upstream -recurse)
if ($upstreamOfNewFeature -notcontains 'origin/main') {
    throw "Expected main to be upstream of the current branch; found: $(ConvertTo-Json $upstreamOfNewFeature)"
}

git rc rc/test -branches feature/add-item-1,feature/add-item-2
ThrowOnNativeFalure

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name should not have changed';
}

git verify-updated rc/test
ThrowOnNativeFalure

$branches = (git branch -a) | ForEach-Object { $_.Trim() }
if ($branches -notcontains 'remotes/origin/rc/test') {
    throw "Expected that rc/test was on origin; found $(ConvertTo-Json $branches)"
}
if ($branches -notcontains 'remotes/origin/feature/PS-1') {
    throw 'Expected that feature/PS-1 was on origin'
}

git branch -a > ../report.txt

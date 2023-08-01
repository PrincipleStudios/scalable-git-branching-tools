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

git new feature/PS-1 -u feature/add-item-1
ThrowOnNativeFalure

git rc rc/test -u feature/subfeature,feature/add-item-2
ThrowOnNativeFalure

git verify-updated rc/test
ThrowOnNativeFalure

git release rc/test main
ThrowOnNativeFalure

$branches = (git branch -a) | ForEach-Object { $_.Trim() }
if ($branches -contains 'remotes/origin/rc/test') {
    throw "Expected that rc/test was not on origin; found $(ConvertTo-Json $branches)"
}
if ($branches -contains 'remotes/origin/feature/subfeature') {
    throw "Expected that feature/subfeature was no longer on origin due to the release; found $(ConvertTo-Json $branches)"
}
if ($branches -contains 'remotes/origin/feature/add-item-1') {
    throw "Expected that feature/add-item-1 was no longer on origin due to the release (included in feature/subfeature); found $(ConvertTo-Json $branches)"
}
if ($branches -contains 'remotes/origin/feature/add-item-2') {
    throw "Expected that feature/add-item-2 was no longer on origin due to the release; found $(ConvertTo-Json $branches)"
}

git branch -a > ../report.txt

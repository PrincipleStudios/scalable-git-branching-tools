#!/usr/bin/env pwsh

function ThrowOnNativeFalure {
    if ($LASTEXITCODE -ne 0) {
        throw "Native Falure - exit code $LASTEXITCODE"
    }
}

& $PSScriptRoot/_setup-existing.ps1

ln -s origin local
cd local

git new feature/PS-1
ThrowOnNativeFalure

if ((git rev-parse main) -ne (git rev-parse HEAD)) {
    throw 'HEAD does not point to the same commit as main';
}

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name did not match expected';
}

git rc rc/test -u feature/add-item-1,feature/add-item-2
ThrowOnNativeFalure

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name should not have changed';
}

git verify-updated rc/test
ThrowOnNativeFalure

git branch > ../report.txt

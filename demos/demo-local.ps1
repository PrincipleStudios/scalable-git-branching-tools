#!/usr/bin/env pwsh

function ThrowOnNativeFalure {
    if ($LASTEXITCODE -ne 0) {
        throw "Native Falure - exit code $LASTEXITCODE"
    }
}

& $PSScriptRoot/_setup.ps1

cd origin

git new PS-1 -from main
ThrowOnNativeFalure

if ((git rev-parse main) -ne (git rev-parse HEAD)) {
    throw 'HEAD does not point to the same commit as main';
}

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name did not match expected';
}

git rc -label 'test' -branches feature/add-item-1,feature/add-item-2
ThrowOnNativeFalure

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name should not have changed';
}

git verify-rc rc/test
ThrowOnNativeFalure

git branch > ../report.txt

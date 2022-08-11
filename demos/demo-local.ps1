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

git rc -label 'test' -branches feature/add-item-1,feature/add-item-2
ThrowOnNativeFalure

git branch > ../report.txt

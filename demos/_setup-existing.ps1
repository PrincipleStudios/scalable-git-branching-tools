#!/usr/bin/env pwsh

& $PSScriptRoot/_setup.ps1

Push-Location
try {
    cd origin

    /git-tools/init.ps1

    git add-upstream main -branchName feature/add-item-1
    git add-upstream main -branchName feature/add-item-2
    git add-upstream main -branchName feature/change-existing-item-A
    git add-upstream main -branchName feature/change-existing-item-B
    git add-upstream feature/add-item-1 -branchName feature/subfeature

} finally {
    Pop-Location
}

#!/usr/bin/env pwsh

& $PSScriptRoot/_setup.ps1

Push-Location
try {
    cd origin

    /git-tools/init.ps1

    for ($i = 0; $i -lt 100; $i++) {
        git add-upstream main -target feature/add-item-1
        git add-upstream main -target feature/add-item-2
        git add-upstream main -target feature/change-existing-item-A
        git add-upstream main -target feature/change-existing-item-B
        git add-upstream feature/add-item-1 -target feature/subfeature
    }

} finally {
    Pop-Location
}

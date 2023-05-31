#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"

try {
    Push-Location $PSScriptRoot
    try {
        Assert-CleanWorkingDirectory

        $currentBranch = Get-CurrentBranch

        Invoke-PreserveBranch {
            $oldCommit = git rev-parse --verify HEAD

            if ($branchName -ne '') {
                # Change branch
                git checkout $branchName
                if ($Global:LASTEXITCODE -ne 0) {
                    throw "Could not switch to $branchName"
                }
            } elseif ($currentBranch -eq $nil) {
                throw "Tools are not currently on a branch - you must specify one via -branchName."
            } else {
                $branchName = $currentBranch
            }
            Write-Host "Updating git-tools to latest on $($branchName)"
            git pull --ff-only
            if ($Global:LASTEXITCODE -ne 0) {
                throw "Could not pull latest for $($branchName)"
            }

            # Ideally, we'd force reloading of this, but it breaks mocks, and
            # realistically, this script is being run in its own scope due to
            # how git will invoke it. This should be safe.
            Import-Module -Scope Local "$PSScriptRoot/migration/Invoke-Migration.psm1"
            Invoke-Migration -from $oldCommit

            Write-Host $oldBranch
        } -onlyIfError

    } finally {
        Pop-Location
    }
    . $PSScriptRoot/init.ps1
} finally {
}

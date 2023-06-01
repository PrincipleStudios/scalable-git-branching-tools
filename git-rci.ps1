#!/usr/bin/env pwsh
Param(
    [Parameter(Mandatory)][string] $branchName,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $force
)

function Select-Branch {
    param(
        [string]$Prompt
    )

    $availableBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -notin $selectedBranches })
    $selectedBranches = New-Object System.Collections.ArrayList
    $currentIndex = 0
    $filterText = ""

    while ($true) {
        Clear-Host
        Write-Host "'$Prompt'" -ForegroundColor Cyan
        Write-Host ""

        $filteredBranches = $availableBranches | Where-Object { $_.branch -like "*$filterText*" }

        for ($i = 0; $i -lt $filteredBranches.Count; $i++) {
            $isSelected = $false
            if ($filteredBranches[$i] -in $selectedBranches) { $isSelected = $true }

            if ($i -eq $currentIndex) {
                Write-Host "->" -NoNewline -ForegroundColor Yellow
            }
            else {
                Write-Host "  " -NoNewline
            }

            Write-Host ("[" + ($isSelected ? "x" : " ") + "]") -NoNewline -ForegroundColor Yellow
            Write-Host (" $($filteredBranches[$i].branch)") -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Selected Branches:" -ForegroundColor Cyan
        foreach ($branch in $selectedBranches) {
            Write-Host "  $($branch.branch)"
        }

        Write-Host ""
        Write-Host "Filter: '$filterText'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "'Use Arrow Keys to navigate. [Enter] to select/deselect the branch. [Esc] to complete"

        # If testing locally on Powershell, switch IncludeKeyDown => IncludeKeyUp
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { if ($currentIndex -gt 0) { $currentIndex-- } }         # Up arrow
            40 { if ($currentIndex -lt $filteredBranches.Count - 1) { $currentIndex++ } } # Down arrow
            13 {
                $selectedBranch = $filteredBranches[$currentIndex]
                if ($selectedBranches.Contains($selectedBranch)) {
                    $selectedBranches.Remove($selectedBranch)
                }
                else {
                    $selectedBranches.Add($selectedBranch)
                }
            }
            27 {
                return $selectedBranches
            }
            8 {  # Backspace
                if ($filterText.Length -gt 0) {
                    $filterText = $filterText.Substring(0, $filterText.Length - 1)
                }
            }
            default {
                if ($key.Character -match "\w") {
                    $filterText += $key.Character
                }
            }
        }
    }
}


. $PSScriptRoot/config/core/split-string.ps1
. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.psm1"

$config = Get-Configuration
Update-Git

Assert-CleanWorkingDirectory
$allBranches = Select-Branches -config $config
$allBranches = $allBranches | Where-Object { $_.branch -ne $config.defaultServiceLine -and $_.branch -ne $config.upstreamBranch}

$selectedBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -in $selectedBranches })
$availableBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -notin $selectedBranches })

if ($availableBranches.Count -gt 0) {
    $selectedBranches = Select-Branch -Prompt "Select branch to merge"
    $selectedBranches = $selectedBranches | Where-Object { $_.branch -ne '' }
}

$upstreamBranchesNoRemote = [string[]](($selectedBranches | Where-Object { $_.branch -ne '' } | Foreach-Object { ConvertTo-BranchName $_ } | Where-Object { $_ -ne '' -and $_ -notmatch '^\s*$' }) | Select-Object -Unique)

Write-Host "RC command: git rc" -branches $upstreamBranchesNoRemote @PSBoundParameters -ForegroundColor Green
. $PSScriptRoot/git-rc.ps1 -branches $upstreamBranchesNoRemote @PSBoundParameters

#!/usr/bin/env pwsh
Param(
    [Parameter(Mandatory)][string] $branchName,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $force,
    [Switch] $noFetch
)

function Select-Branch {
    param(
        [string]$Prompt
    )

    $availableBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -notin $selectedBranches })
    $selectedBranches = New-Object System.Collections.ArrayList
    $currentIndex = 0

    while ($true) {
        Clear-Host
        Write-Host "Available Branches for '$Prompt'" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $availableBranches.Count; $i++) {
            $isSelected = $false
            if ($availableBranches[$i] -in $selectedBranches) { $isSelected = $true }

            if ($i -eq $currentIndex) {
                Write-Host "->" -NoNewline -ForegroundColor Yellow
            }
            else {
                Write-Host "  " -NoNewline
            }

            Write-Host ("[" + ($isSelected ? "x" : " ") + "]") -NoNewline -ForegroundColor Yellow
            Write-Host (" $($availableBranches[$i].branch)") -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Selected Branches:" -ForegroundColor Cyan
        foreach ($branch in $selectedBranches) {
            Write-Host "  $($branch.branch)"
        }

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { if ($currentIndex -gt 0) { $currentIndex-- } }         # Up arrow
            40 { if ($currentIndex -lt $availableBranches.Count - 1) { $currentIndex++ } } # Down arrow
            13 {
                $selectedBranch = $availableBranches[$currentIndex]
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
        }
    }
}

function ToDictionary([System.Collections.Generic.IEnumerable[PSObject]] $input, [scriptblock] $keySelector, [scriptblock] $valueSelector) {
    $output = @{}
    foreach ($item in $input) {
        $key = Invoke-Command -ScriptBlock $keySelector -ArgumentList $item
        $value = Invoke-Command -ScriptBlock $valueSelector -ArgumentList $item
        $output[$key] = $value
    }
    return $output
}


. $PSScriptRoot/config/core/split-string.ps1
. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Select-Branches.ps1
. $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
. $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
. $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1
Import-Module "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";
. $PSScriptRoot/config/git/Set-UpstreamBranches.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git -config $config
}

$selectedBranches = @()

Assert-CleanWorkingDirectory
$allBranches = Select-Branches -config $config
$allBranches = $allBranches | Where-Object { $_.branch -ne 'main' -and $_.branch -ne '_upstream' }

$selectedBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -in $selectedBranches })
$availableBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -notin $selectedBranches })

if ($availableBranches.Count -gt 0) {
    $selectedBranches = Select-Branch -Prompt "Select branch to merge"
    $selectedBranches = $selectedBranches | Where-Object { $_.branch -ne '' }
}

$upstreamBranches = [string[]]($selectedBranches | Where-Object { $_.branch -ne '' } | Foreach-Object { ConvertTo-BranchName $_ -includeRemote } | Where-Object { $_ -ne '' -and $_ -notmatch '^\s*$' }) | Select-Object -Unique
$upstreamBranchesNoRemote = [string[]]($selectedBranches | Where-Object { $_.branch -ne '' } | Foreach-Object { ConvertTo-BranchName $_ } | Where-Object { $_ -ne '' -and $_ -notmatch '^\s*$' }) | Select-Object -Unique

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName
    $(Invoke-MergeBranches ($upstreamBranches | select -skip 1)).ThrowIfInvalid()

    $commitMessage = Coalesce $commitMessage "Add branch $branchName$($comment -eq $nil ? '' : " for $comment")"

    Set-UpstreamBranches $branchName $upstreamBranchesNoRemote -m $commitMessage -config $config

    if ($config.remote -ne $nil) {
        $params = $force ? @('--force') : @()
        git push $config.remote "$($branchName):refs/heads/$($branchName)" @params
        if ($global:LASTEXITCODE -ne 0) {
            throw "Unable to push $branchName to $($config.remote)"
        }
    }
} -cleanup {
    if ($config.remote -ne $nil) {
        git branch -D $branchName 2> $nil
    }
}
#!/usr/bin/env pwsh
Param(
    [Parameter(Mandatory)][string] $branchName,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $force,
    [Switch] $noFetch,
    [Parameter()][string] $search
)

function Show-Menu {
    param (
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][hashtable]$MenuItems
    )

    do {
        Write-Host $Prompt
        foreach ($key in $MenuItems.Keys) {
            Write-Host "[$key] $($MenuItems[$key])" -NoNewline
            if ($key -eq 'd' -or $key -eq 'c') {
                Write-Host "`t" -NoNewline
            }
            else {
                Write-Host " " -NoNewline
            }
        }
        $userInput = Read-Host
    } until ($MenuItems.ContainsKey($userInput))

    return $userInput
}


function Select-Branch {
    param(
        [string]$Prompt
    )

    $branches = (Get-Branches | ForEach-Object { $_.Trim() }) | Where-Object { $_ -ne 'main' -and $_ -ne '_upstream' }

    $selectedBranches = New-Object System.Collections.ArrayList

    $selected = $null
    while ($selected -eq $null) {
        Clear-Host

        Write-Host "Available Branches for '$Prompt'" -ForegroundColor Cyan
        Write-Host ""

        $index = 1
        foreach ($branch in $branches) {
            $isSelected = $false
            if ($branch -in $selectedBranches) { $isSelected = $true }

            Write-Host ("[" + ($isSelected ? "x" : " ") + "]") -NoNewline -ForegroundColor Yellow
            Write-Host (" $index. $branch") -ForegroundColor Green
            $index++
        }

        Write-Host ""
        Write-Host "Selected Branches:" -ForegroundColor Cyan
        foreach ($branch in $selectedBranches) {
            Write-Host "  $branch"
        }

        Write-Host ""
        $choice = Read-Host -Prompt "Type the number of a branch to select/deselect, 'n' for Next, 'd' to delete selection, or 'c' to cancel"

        if ($selectedBranches.Count -gt 0 -and $choice -eq 'n') {
            $selected = $true
        }
        elseif ($choice -eq 'd') {
            $selectedBranches.Clear()
        }
        elseif ($choice -eq 'c') {
            return $null
        }
        else {
            $branchIndex = $choice - 1
            if ($branchIndex -ge 0 -and $branchIndex -lt $branches.Count) {
                $selectedBranch = $branches[$branchIndex]
                if ($selectedBranches.Contains($selectedBranch)) {
                    $selectedBranches.Remove($selectedBranch)
                }
                else {
                    $selectedBranches.Add($selectedBranch)
                }
            }
        }
    }

    return $selectedBranches
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

if ($search) {
    # comment
    Write-Host "some selected branches"
    $selectedBranches = Select-Branch -Prompt $search
}
else {
    Write-Host "no selected branches"
    $selectedBranches = @()
}


Assert-CleanWorkingDirectory
$allBranches = Select-Branches -config $config
#filter out all branches with names "main" and "_upstream
$allBranches = $allBranches | Where-Object { $_.branch -ne 'main' -and $_.branch -ne '_upstream' }
Write-Host "All branches:"
foreach ($branch in $allBranches) {
    Write-Host "  $($branch.branch)"
}
if ($selectedBranches.Count -eq 0) {
    Write-Host "No selected branches here"
    

    #TODO: This is where to start. We are selected from $selected Branches, we need to select from all branches minus selected
    $selectedBranches = [PSObject[]]$allBranches
}
else {
    #output selected branches before
    Write-Host "selected branches before"
    foreach ($branch in $selectedBranches) {
        Write-Host "  $($branch.branch)"
    }

    $selectedBranches = [PSObject[]]($allBranches | Where-Object { $_.branch -in $selectedBranches })
    #output selected branches after
    Write-Host "selected branches after"
    foreach ($branch in $selectedBranches) {
        Write-Host "  $($branch.branch)"
    }
}
Write-Host "Here now"
if ($selectedBranches.Count -gt 0) {
    Write-Host "Here now 2"
    #write the count of selected branches
    Write-Host "Selected branches: $($selectedBranches.Count)"
    $deleteMenuItems = @{}
    foreach ($branch in $selectedBranches) {
        $deleteMenuItems[$branch.branch] = $branch.branch
    }
    $deleteMenuItems.Add('Done', 'd')
    $deleteMenuItems.Add('Cancel', 'c')
    while ($true) {
        Write-Host "Available Branches:" -ForegroundColor Cyan
        foreach ($branch in $selectedBranches) {
            Write-Host "  $($branch.branch)"
        }
    
        $choice = Show-Menu -Prompt "Select branch to merge, 'n' to proceed to next step, or 'x' to cancel:" -MenuItems $deleteMenuItems
    
        if ($choice -eq 'd') {
            break
        }
        elseif ($choice -eq 'c') {
            throw "Branch selection canceled."
        }
        else {
            $selectedBranches = $selectedBranches | Where-Object { $_.branch -ne $choice }

            if ($null -ne $deleteMenuItems) {
                $deleteMenuItems.Remove($choice)
            }
            

        }
    }
}

$upstreamBranches = [string[]]($selectedBranches | Foreach-Object { ConvertTo-BranchName $_ -includeRemote }) | Select-Object -Unique

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName
    

    while ($true) {
        Write-Host "Selected Branches:" -ForegroundColor Cyan
        foreach ($branch in $selectedBranches) {
            Write-Host "  $($branch.branch)"
        }

        $choice = Show-Menu -Prompt "Select branch to delete, or 'd' to continue, or 'c' to cancel:" -MenuItems $deleteMenuItems

        if ($choice -eq 'd') {
            break
        }
        elseif ($choice -eq 'c') {
            throw "Branch selection canceled."
        }
        else {
            $selectedBranches = $selectedBranches | Where-Object { $_.branch -ne $choice }
            
            if ($deleteMenuItems -ne $null) {
                $deleteMenuItems.Remove($choice)
            }
            

        }
    }
}

$upstreamBranches = [string[]]($selectedBranches | Foreach-Object { ConvertTo-BranchName $_ -includeRemote }) | Select-Object -Unique

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName

    $(Invoke-MergeBranches ($upstreamBranches | select -skip 1)).ThrowIfInvalid()

    $commitMessage = Coalesce $commitMessage "Add branch $branchName"

    Set-UpstreamBranches $branchName $selectedBranches -m $commitMessage -config $config

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

Write-Host ""
Write-Host "New Branch: $branchName" -ForegroundColor Cyan
Write-Host "Upstream Branches: $($upstreamBranches -join ', ')" -ForegroundColor Cyan
Write-Host "Selected Branches:" -ForegroundColor Cyan
foreach ($branch in $selectedBranches) {
    Write-Host " $branch.branch"
}
$(Invoke-MergeBranches ($upstreamBranches | select -skip 1)).ThrowIfInvalid()

$commitMessage = Coalesce $commitMessage "Add branch $branchName"

Set-UpstreamBranches $branchName $selectedBranches -m $commitMessage -config $config

if ($config.remote -ne $nil) {
    $params = $force ? @('--force') : @()
    git push $config.remote "$($branchName):refs/heads/$($branchName)" @params
    if ($global:LASTEXITCODE -ne 0) {
        throw "Unable to push $branchName to $($config.remote)"
    }
}
$(Invoke-MergeBranches ($upstreamBranches | select -skip 1)).ThrowIfInvalid()

$commitMessage = Coalesce $commitMessage "Add branch $branchName"

Set-UpstreamBranches $branchName $selectedBranches -m $commitMessage -config $config

if ($config.remote -ne $nil) {
    $params = $force ? @('--force') : @()
    git push $config.remote "$($branchName):refs/heads/$($branchName)" @params
    if ($global:LASTEXITCODE -ne 0) {
        throw "Unable to push $branchName to $($config.remote)"
    }

} -cleanup {
    if ($config.remote -ne $nil) {
        git branch -D $branchName 2> $nil
    }
}
    
Write-Host ""
Write-Host "New Branch: $branchName" -ForegroundColor Cyan
Write-Host "Upstream Branches: $($upstreamBranches -join ', ')" -ForegroundColor Cyan
Write-Host "Selected Branches:" -ForegroundColor Cyan
foreach ($branch in $selectedBranches) {
    Write-Host " $branch.branch"
}


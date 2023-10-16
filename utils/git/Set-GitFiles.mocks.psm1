Import-Module -Scope Local "$PSScriptRoot/Set-GitFiles.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteBlob.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"

function Initialize-SetGitFiles(
    [Parameter()][AllowNull()][PSObject]$files,
    [Parameter()][Alias('m')][Alias('message')][AllowNull()][String]$commitMessage,
    [Parameter()][Alias('branchName')][Alias('commitish')][AllowNull()][String]$initialCommitish
) {
    Invoke-MockGitModule -ModuleName Set-GitFiles "rev-parse --verify $initialCommitish -q" { $global:LASTEXITCODE = 128 }
    Invoke-MockGitModule -ModuleName Set-GitFiles "rev-parse --verify $initialCommitish^{tree} -q" { $global:LASTEXITCODE = 128 }
    
    $treeHash = Initialize-SetGitFilesTree (ConvertTo-FileTree $files) $null $null

    Invoke-MockGitModule -ModuleName Set-GitFiles "commit-tree $treeHash -m $commitMessage"
}

function ConvertTo-FileTree([Parameter(Position=1, Mandatory)][PSObject]$files) {
    $grouped = $files.Keys | Group-Object -Property { $_ -match '/' ? $_.Split('/')[0] : $_ } -AsHashTable
    $result = $grouped.Keys | ConvertTo-HashMap -getValue {
        if ($files[$_] -ne $nil) { return $files[$_] }
        $grouped[$_] | ConvertTo-HashMap `
            -getKey { ($_.Split('/') | Select-Object -Skip 1) -join '/' } `
            -getValue { $files[$_] }
    }
    return $result;
}

function New-MockSha {
    -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
}

function Initialize-SetGitFilesTree($alterations, $treeEntriesByName, $oldTreeHash) {
    if ($null -eq $alterations) { return $oldTreeHash }

    $treeEntriesByName = $treeEntriesByName ?? @{}

    $alterations.Keys | ForEach-Object {
        if ($alterations[$_] -is [String]) {
            # just write the file
            $mockFileSha = New-MockSha
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes($alterations[$_])) $mockFileSha
            $treeEntriesByName[$_] = "100644 blob $mockFileSha`t$_"
        } else {
            if ($null -ne $treeEntriesByName[$_]) {
                # existing file
                throw 'TODO: not yet supported'
            } else {
                $oldTreeSha = $null
            }
            $newTreeSha = Initialize-SetGitFilesTree $alterations[$_] $treeEntriesByName[$_] $oldTreeSha
            $treeEntriesByName[$_] = $null -ne $newTreeSha ? "040000 tree $newTreeSha`t$_" : $null
        }
    }
    $entries = [String[]]($treeEntriesByName.Values | Where-Object { $_ -ne $null })
    if ($entries.Length -eq 0) { return $null }
    $result = New-MockSha
    Initialize-WriteTree $entries $result
    return $result
}

Export-ModuleMember -Function Initialize-SetGitFiles

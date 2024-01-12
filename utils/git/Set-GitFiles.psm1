Import-Module -Scope Local "$PSScriptRoot/../core/ConvertTo-HashMap.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteBlob.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.psm1"

function Set-GitFiles(
    [Parameter(Position=1, Mandatory)][Hashtable]$files,
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage,
    [Parameter(Mandatory)][Alias('branchName')][String]$initialCommitish
) {
    # Verify that folders/files do not conflict
    $files.Keys | ForEach-Object {
        $parts = $_.split('/')
        if ($null -ne $files[$_] -AND $files[$_] -isnot [string]) {
            throw "File $_ must have string contents"
        }
        if ($_ -match '/') {
            (1..($parts.Length - 1)) | ForEach-Object {
                $folder = ($parts | Select-Object -First $_) -join '/'
                if ($files.Keys -contains $folder) {
                    throw "Files cannot be nested inside $folder since it is also a file"
                }
            }
        }
    }

    $treeSuffix = '^{tree}'

    $parentCommit = git rev-parse --verify $initialCommitish -q 2> $null
    $oldTree = git rev-parse --verify ($initialCommitish + $treeSuffix) -q 2> $null

    $newTree = Update-Tree (ConvertTo-Alterations $files) $oldTree

    if ($null -eq $newTree) {
        $newTree = Invoke-WriteTree @()
    }

    $parentSwitch = $null -eq $parentCommit ? @() : @('-p', $parentCommit)
    $newCommitHash = git commit-tree $newTree -m $commitMessage @parentSwitch
    if ($Global:LASTEXITCODE -ne 0) {
        throw "git-commit-tree exited with non-zero exit code: $($Global:LASTEXITCODE)"
    } elseif ($null -eq $newCommitHash -OR -not $newCommitHash -is [string]) {
        # If it returned multiple lines, would not be a string
        throw "Invalid hash returned from git-commit-tree: '$newCommitHash'"
    }

    return $newCommitHash
}

function ConvertTo-Alterations([Parameter(Position=1, Mandatory)][PSObject]$files) {
    $grouped = $files.Keys | Group-Object -Property { $_ -match '/' ? $_.Split('/')[0] : $_ } -AsHashTable
    $result = $grouped.Keys | ConvertTo-HashMap -getValue {
        if ($null -ne $files[$_]) { return $files[$_] }
        $grouped[$_] | ConvertTo-HashMap `
            -getKey { ($_.Split('/') | Select-Object -Skip 1) -join '/' } `
            -getValue { $files[$_] }
    }
    return $result;
}

function Update-Tree($alterations, $treeHash) {
    $treeEntries = $null -eq $treeHash ? @() : (git ls-tree $treeHash 2> $null)

    $treeEntriesByName = $treeEntries | ConvertTo-HashMap { $_.Split("`t")[1] }

    if ($null -eq $alterations) { return $treeHash }

    $alterations.Keys | ForEach-Object {
        if ($alterations[$_] -is [String]) {
            # just write the file
            $fileSha = Invoke-WriteBlob ([Text.Encoding]::UTF8.GetBytes($alterations[$_]))
            $treeEntriesByName[$_] = "100644 blob $fileSha`t$_"
        } else {
            if ($null -ne $treeEntriesByName[$_]) {
                # existing file
                $parts = $treeEntriesByName[$_].Split("`t")[0].Split(' ')
                if ($parts[1] -eq 'tree') {
                    $oldTreeSha = $parts[2]
                } else {
                    # it was not a tree, so we ignore it
                    $oldTreeSha = $null
                }
            } else {
                $oldTreeSha = $null
            }
            $newTreeSha = Update-Tree $alterations[$_] $oldTreeSha
            $treeEntriesByName[$_] = $null -ne $newTreeSha ? "040000 tree $newTreeSha`t$_" : $null
        }
    }
    $entries = [String[]]($treeEntriesByName.Values | Where-Object { $_ -ne $null })
    if ($entries.Length -eq 0) { return $null }
    $result = Invoke-WriteTree $entries
    return $result
}

Export-ModuleMember -Function Set-GitFiles

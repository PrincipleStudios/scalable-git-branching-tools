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
        if ($files[$_] -ne $nil -AND $files[$_] -isnot [string]) {
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

    $parentCommit = git rev-parse --verify $initialCommitish -q 2> $nil
    $oldTree = git rev-parse --verify ($initialCommitish + $treeSuffix) -q 2> $nil

    $newTree = Update-Tree (ConvertTo-Alterations $files) $oldTree

    if ($newTree -eq $nil) {
        $newTree = Invoke-WriteTree @()
    }

    $parentSwitch = $parentCommit -eq $nil ? @() : @('-p', $parentCommit)
    $newCommitHash = git commit-tree $newTree -m $commitMessage @parentSwitch

    return $newCommitHash
}

function ConvertTo-Alterations([Parameter(Position=1, Mandatory)][PSObject]$files) {
    $grouped = $files.Keys | Group-Object -Property { $_ -match '/' ? $_.Split('/')[0] : $_ } -AsHashTable
    $result = $grouped.Keys | ConvertTo-HashMap -getValue {
        if ($files[$_] -ne $nil) { return $files[$_] }
        $grouped[$_] | ConvertTo-HashMap `
            -getKey { ($_.Split('/') | Select-Object -Skip 1) -join '/' } `
            -getValue { $files[$_] }
    }
    return $result;
}

function Update-Tree($alterations, $treeHash) {
    $treeEntries = $treeHash -eq $nil ? @() : (git ls-tree $treeHash 2> $nil)

    $treeEntriesByName = $treeEntries | ConvertTo-HashMap { $_.Split("`t")[1] }

    if ($alterations -eq $nil) { return $treeHash }

    $alterations.Keys | ForEach-Object {
        if ($alterations[$_] -is [String]) {
            # just write the file
            $fileSha = Invoke-WriteBlob ([Text.Encoding]::UTF8.GetBytes($alterations[$_]))
            $treeEntriesByName[$_] = "100644 blob $fileSha`t$_"
        } else {
            if ($treeEntriesByName[$_] -ne $nil) {
                # existing file
                $parts = $treeEntriesByName[$_].Split("`t")[0].Split(' ')
                if ($parts[1] -eq 'tree') {
                    $oldTreeSha = $parts[2]
                } else {
                    # it was not a tree, so we ignore it
                    $oldTreeSha = $nil
                }
            } else {
                $oldTreeSha = $nil
            }
            $newTreeSha = Update-Tree $alterations[$_] $oldTreeSha
            $treeEntriesByName[$_] = $newTreeSha -ne $nil ? "040000 tree $newTreeSha`t$_" : $nil
        }
    }
    $entries = [String[]]($treeEntriesByName.Values | Where-Object { $_ -ne $nil })
    if ($entries.Length -eq 0) { return $nil }
    $result = Invoke-WriteTree $entries
    return $result
}

Export-ModuleMember -Function Set-GitFiles

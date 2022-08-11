. $PSScriptRoot/../core/ArrayToHash.ps1
. $PSScriptRoot/Invoke-WriteTree.ps1

function Set-GitFiles(
    [Parameter(Position=1, Mandatory)][PSObject]$files,
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage,
    [Parameter(Mandatory)][String]$branchName,
    [Parameter()][String]$remote,
    [switch]$dryRun
) {
    # Verify that folders/files do not conflict
    $files.Keys | ForEach-Object {
        $parts = $_.split('/')
        if ($files[$_] -ne $nil -AND $files[$_] -isnot [string]) {
            throw "File $_ must have string contents"
        }
        if ($_ -match '/') {
            (1..($parts.Length - 1)) | ForEach-Object {
                $folder = ($parts | Select -First $_) -join '/'
                if ($files.Keys -contains $folder) {
                    throw "Files cannot be nested inside $folder since it is also a file"
                }
            }
        }
    }

    $fullBranchName = (@($remote, $branchName) | Where-Object {$_}) -join '/'
    $treeSuffix = '^{tree}'

    $parentCommit = git rev-parse --verify $fullBranchName -q 2> $nil
    $oldTree = git rev-parse --verify ($fullBranchName + $treeSuffix) -q 2> $nil

    $newTree = Update-Tree (ConvertTo-Alterations $files) $oldTree

    $parentSwitch = $parentCommit -eq $nil ? @() : @('-p', $parentCommit)
    $newCommitHash = git commit-tree $newTree -m $commitMessage @parentSwitch

    if (-not $dryRun -AND $remote -ne $nil) {
        git push $remote "$($newCommitHash):$($branchName)"
    }
    return $newCommitHash
}

function ConvertTo-Alterations([Parameter(Position=1, Mandatory)][PSObject]$files) {
    $grouped = $files.Keys | Group-Object -Property { $_ -match '/' ? $_.Split('/')[0] : $_ } -AsHashTable
    $result = $grouped.Keys | ArrayToHash -getValue { 
        if ($files[$_] -ne $nil) { return $files[$_] }
        $grouped[$_] | ArrayToHash `
            -getKey { ($_.Split('/') | Select-Object -Skip 1) -join '/' } `
            -getValue { $files[$_] }
    }
    return $result;
}

function Update-Tree($alterations, $treeHash) {
    $treeEntries = git ls-tree $treeHash 2> $nil

    $treeEntriesByName = $treeEntries | ArrayToHash { $_.Split("`t")[1] }


    $alterations.Keys | ForEach-Object {
        if ($alterations[$_] -is [String]) {
            # just write the file
            $fileSha = ($alterations[$_] | git hash-object -w --stdin)
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
            $treeEntriesByName[$_] = "040000 tree $newTreeSha`t$_"
        }
    }
    $result = Invoke-WriteTree $treeEntriesByName.Values
    return $result
}

function Get-GitFileNames(
    [Parameter(Mandatory)][string]$branchName,
    [Parameter()][String]$remote
) {
    $fullBranchName = (@($remote, $branchName) | Where-Object {$_}) -join '/'
    $treeSuffix = '^{tree}'

    $tree = git rev-parse --verify ($fullBranchName + $treeSuffix) -q 2> $nil

    function Get-GitFileNamesFromTree($tree, $prefix) {
        return git ls-tree $tree | ForEach-Object {
            $fileName = $_.Split("`t")[1]
            $fileName = ($prefix -eq '' ? $fileName : "$prefix/$fileName")
            $parts = $_.Split("`t")[0].Split(' ')
            if ($parts[1] -eq 'tree') {
                $oldTreeSha = $parts[2]
                return Get-GitFileNamesFromTree -tree $parts[2] -prefix $fileName
            } else {
                return $fileName
            }
        } | ForEach-Object { $_ }
    }

    return Get-GitFileNamesFromTree -tree $tree -prefix ''
}
Export-ModuleMember -Function Get-GitFileNames

Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Select-Branches() {
    $remote = $(Get-Configuration).remote
    [string[]]$temp = $remote -eq $nil ? (git branch) : (git branch -r)
    return $temp | Foreach-Object {
        if ($null -eq $temp) { return $null }
        if ($remote -eq $nil) {
            $branchName = $_.Trim()
        } else {
            $split = $_.Trim().Split('/')
            if ($remote -ne $split[0]) {
                return $nil
            }
            $branchName = $split[1..($split.Length-1)] -join '/'
            if ($branchName -eq "") {
                return $nil
            }
        }

        return $branchName
    } | Where-Object { $_ -ne $nil }
}
Export-ModuleMember -Function Select-Branches

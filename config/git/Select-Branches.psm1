Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Select-Branches() {
    $remote = $(Get-Configuration).remote
    $temp = $remote -eq $nil ? (git branch) : (git branch -r)
    return $temp | Foreach-Object { $_.split("`n") } | Foreach-Object {
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

        return @{ remote = $remote; branch = $branchName }
    } | Where-Object { $_ -ne $nil }
}
Export-ModuleMember -Function Select-Branches

. $PSScriptRoot/../Variables.ps1
. $PSScriptRoot/../parsing/ConvertTo-BranchInfo.ps1

function List-Branches() {
    return (git branch -r) | Foreach-Object {
        $split = $_.Trim().Split('/')
        $branchName = $split[1..($split.Length-1)] -join '/'

        $info = ConvertTo-BranchInfo $branchName
        if ($info -eq $nil) {
            return $nil
        }
        $info.remote = $split[0]
        $info.branch = $branchName
        return $info
    } | Where-Object { $_ -ne $nil } | Select Branch,Remote,Type,Ticket,Tickets,Parents,Comment
}

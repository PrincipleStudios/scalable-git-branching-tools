. $PSScriptRoot/../validation/Assert-TicketName.ps1
. $PSScriptRoot/../validation/Assert-BranchType.ps1
. $PSScriptRoot/../branch-types.ps1

function Format-BranchName {
    Param (
        [String] $type,
        [String[]] $ticketNames,
        [String] $comment
    )

    $ticketNames = $ticketNames | Where-Object { $_ -ne '' }
    if ($ticketNames -ne $nil) {
        $ticketNames | ForEach-Object { Assert-TicketName $_ }
    }
    Assert-BranchType $type

    $typeName = Get-BranchType $type

    $branchName = & $branchTypes[$typeName].build $type $ticketNames $comment
    if ((& $branchTypes[$typeName].toInfo $branchName) -eq $nil) {
        throw "Invalid arguments for branch of type $typeName."
    }

    return $branchName
}

. $PSScriptRoot/coalesce.ps1
. $PSScriptRoot/to-kebab.ps1

function Format-Branch {
    Param(
        [Parameter(Mandatory, Position=0)][ValidateLength(1,25)][String] $type,
        [Parameter(Position=1)][System.Object[]] $tickets,
        [Parameter()][Alias('m')][Alias('message')][ValidateLength(0,25)][String] $comment
    )

    $ticketPart = ($tickets.where{$_ -ne '' -AND $_ -ne ''} -join '_').ToUpper()
    $commentPart = To-Kebab $comment
    $separator = ($comment -ne '' -AND $ticketPart -ne '') ? '-' : '';

    return "$type/$ticketPart$separator$commentPart"
}

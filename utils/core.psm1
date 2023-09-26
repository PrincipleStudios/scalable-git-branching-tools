Import-Module -Scope Local "$PSScriptRoot/core/ConvertTo-HashMap.psm1"
Import-Module -Scope Local "$PSScriptRoot/core/ConvertTo-Hashtable.psm1"
Import-Module -Scope Local "$PSScriptRoot/core/Invoke-PipeToProcess.psm1"

Export-ModuleMember -Function ConvertTo-HashMap `
    ,ConvertTo-Hashtable `
    ,Invoke-PipeToProcess
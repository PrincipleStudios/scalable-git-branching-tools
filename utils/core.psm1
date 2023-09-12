Import-Module -Scope Local "$PSScriptRoot/core/ConvertTo-HashMap.psm1"
Import-Module -Scope Local "$PSScriptRoot/core/Invoke-PipeToProcess.psm1"

Export-ModuleMember -Function ConvertTo-HashMap `
    ,Invoke-PipeToProcess
Import-Module -Scope Local "$PSScriptRoot/scripting/ConvertFrom-ParameterizedScript.psm1"
Import-Module -Scope Local "$PSScriptRoot/scripting/ConvertFrom-ParameterizedArray.psm1"

Export-ModuleMember -Function ConvertFrom-ParameterizedScript `
    , ConvertFrom-ParameterizedArray

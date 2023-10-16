Import-Module -Scope Local "$PSScriptRoot/scripting/Invoke-Script.psm1"
Export-ModuleMember -Function Invoke-Script

Import-Module -Scope Local "$PSScriptRoot/scripting/Invoke-JsonScript.psm1"
Export-ModuleMember -Function Invoke-JsonScript

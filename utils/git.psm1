Import-Module -Scope Local "$PSScriptRoot/git/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteBlob.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteTree.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Set-GitFiles.psm1"

Export-ModuleMember -Function Get-GitFile `
    , Invoke-WriteBlob `
    , Invoke-WriteTree `
    , Set-GitFiles

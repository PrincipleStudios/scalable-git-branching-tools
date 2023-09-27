Import-Module -Scope Local "$PSScriptRoot/git/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteBlob.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/git/Invoke-WriteTree.mocks.psm1"

Export-ModuleMember -Function Initialize-OtherGitFilesAsBlank, Initialize-GitFile `
    , Lock-InvokeWriteBlob, Initialize-WriteBlob `
    , Lock-InvokeWriteTree, Initialize-WriteTree `

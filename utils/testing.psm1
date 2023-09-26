Import-Module -Scope Local "$PSScriptRoot/testing/Assert-ShouldBeObject.psm1"
Import-Module -Scope Local "$PSScriptRoot/../config/testing/Invoke-VerifyMock.psm1"
Import-Module -Scope Local "$PSScriptRoot/../config/testing/Invoke-MockGit.psm1"
Import-Module -Scope Local "$PSScriptRoot/../config/testing/Invoke-MockGitModule.psm1"

Export-ModuleMember -Function Assert-ShouldBeObject `
    ,New-VerifiableMock, Invoke-VerifyMock, Invoke-WrapMock `
    ,Invoke-MockGit `
    ,Invoke-MockGitModule


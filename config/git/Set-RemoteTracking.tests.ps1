BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-RemoteTracking.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-RemoteTracking.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Set-RemoteTracking' {
    BeforeEach{
        Initialize-ToolConfiguration
    }

    It 'tracks feature/FOO-123' {
        $verifiable = Initialize-SetRemoteTracking 'feature/123'
        Set-RemoteTracking 'feature/123'
        Invoke-VerifyMock $verifiable -Times 1
    }
}

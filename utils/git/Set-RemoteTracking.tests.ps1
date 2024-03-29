BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-RemoteTracking.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-RemoteTracking.psm1"
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

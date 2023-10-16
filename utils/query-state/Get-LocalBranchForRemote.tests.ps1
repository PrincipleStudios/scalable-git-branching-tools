BeforeAll {
    . "$PSScriptRoot/../../utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-LocalBranchForRemote.psm1"
}

Describe 'Get-LocalBranchForRemote' {
    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'provides the specified local branch' {
            $mocks = Initialize-GetLocalBranchForRemote 'my-remote' 'foo'
            $result = Get-LocalBranchForRemote 'my-remote'

            $result | Should -Be 'foo'
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can result in a null response' {
            $mocks = Initialize-GetLocalBranchForRemote 'my-remote' $null
            $result = Get-LocalBranchForRemote 'my-remote'

            $result | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'no remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        It 'works without remote' {
            $mocks = Initialize-GetLocalBranchForRemote 'my-remote' 'my-remote'
            $result = Get-LocalBranchForRemote 'my-remote'

            $result | Should -Be 'my-remote'
            $mocks | Should -BeNullOrEmpty
        }

        It 'does not require initialization for local' {
            $result = Get-LocalBranchForRemote 'my-remote'

            $result | Should -Be 'my-remote'
        }
    }
}

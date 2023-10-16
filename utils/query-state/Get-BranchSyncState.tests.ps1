BeforeAll {
    . "$PSScriptRoot/../../utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-BranchSyncState.psm1"
}

Describe 'Get-BranchSyncState' {
    It 'prevents using the mocks if configuration is local' {
        Initialize-ToolConfiguration -noRemote
        { Initialize-RemoteBranchBehind 'my-branch' } | Should -Throw
    }

    It 'reports in-sync if the branch is local' {
        Initialize-ToolConfiguration -noRemote
        { Initialize-RemoteBranchBehind 'my-branch' } | Should -Throw
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'reports when the branch is behind' {
            Initialize-RemoteBranchBehind 'my-branch'

            $result = Get-BranchSyncState 'my-branch'
            $result | Should -Be '<'
        }

        It 'reports when the branch is ahead' {
            Initialize-RemoteBranchAhead 'my-branch'

            $result = Get-BranchSyncState 'my-branch'
            $result | Should -Be '>'
        }

        It 'reports when the branch is up-to-date' {
            Initialize-RemoteBranchInSync 'my-branch'

            $result = Get-BranchSyncState 'my-branch'
            $result | Should -Be '='
        }

        It 'reports when the branch is not tracked' {
            Initialize-RemoteBranchNotTracked 'my-branch'

            $result = Get-BranchSyncState 'my-branch'
            $result | Should -BeNullOrEmpty
        }

        It 'reports when the branch is out of sync' {
            Initialize-RemoteBranchAheadAndBehind 'my-branch'

            $result = Get-BranchSyncState 'my-branch'
            $result | Should -Be '<>'
        }
    }
}

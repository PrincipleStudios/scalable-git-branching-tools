BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-RemoteBranchRef.psm1"
}

Describe 'Get-RemoteBranchRef' {
    It 'resolves a branch with no remote' {
        Initialize-ToolConfiguration -noRemote

        $result = Get-RemoteBranchRef 'feature/my-branch'
        $result | Should -Be 'feature/my-branch'
    }

    It 'resolves a branch with default remote' {
        Initialize-ToolConfiguration

        $result = Get-RemoteBranchRef 'feature/my-branch'
        $result | Should -Be 'origin/feature/my-branch'
    }

    It 'resolves a branch with a custom remote' {
        Initialize-ToolConfiguration -remote 'azure'

        $result = Get-RemoteBranchRef 'feature/my-branch'
        $result | Should -Be 'azure/feature/my-branch'
    }

    It 'allows passing a manual config object' {
        $result = Get-RemoteBranchRef 'feature/my-branch' -configuration @{ remote = 'azure' }
        $result | Should -Be 'azure/feature/my-branch'
    }
}

BeforeAll {
    . $PSScriptRoot/Get-BranchType.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'Get-BranchType' {
    It 'finds the corresponding branch type' {
        Get-BranchType 'main' | Should -Be 'serviceLine'
        Get-BranchType 'rc' | Should -Be 'rc'
        Get-BranchType 'feature' | Should -Be 'feature'
        Get-BranchType 'bugfix' | Should -Be 'feature'
        Get-BranchType 'infra' | Should -Be 'infrastructure'
        Get-BranchType 'integrate' | Should -Be 'integration'
    }
    It 'returns null for missing branch types' {
        Get-BranchType 'foo' | Should -Be $nil
    }
}

BeforeAll {
    . $PSScriptRoot/ConvertTo-BranchName.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'ConvertTo-BranchName' {
    It 'returns only the branch name if remote is not requested' {
        ConvertTo-BranchName @{ remote = 'origin'; branch = 'main' } | Should -Be 'main'
    }
    It 'returns the remote and branch name if remote is requested' {
        ConvertTo-BranchName @{ remote = 'origin'; branch = 'main' } -includeRemote | Should -Be 'origin/main'
    }
    It 'returns only the branch name if there is no remote' {
        ConvertTo-BranchName @{ remote = $nil; branch = 'main' } -includeRemote | Should -Be 'main'
    }
}

BeforeAll {
    . $PSScriptRoot/Assert-BranchType.ps1
}

Describe 'Assert-BranchType' {
    It 'returns successfully for a valid feature type' {
        { Assert-BranchType 'feature' } | Should -Not -Throw
        { Assert-BranchType 'bugfix' } | Should -Not -Throw
        { Assert-BranchType 'rc' } | Should -Not -Throw
        { Assert-BranchType 'main' } | Should -Not -Throw
        { Assert-BranchType 'sl' } | Should -Not -Throw
        { Assert-BranchType 'infra' } | Should -Not -Throw
        { Assert-BranchType 'infrastructure' } | Should -Not -Throw
    }
    
    It 'errors for an invalid feature type' {
        { Assert-BranchType 'feat' } | Should -Throw
    }
    
    It 'errors for empty strings' {
        { Assert-BranchType '' } | Should -Throw
    }
    
    It 'returns successfully for empty strings when flagged with optional' {
        { Assert-BranchType '' -optional } | Should -Not -Throw
    }
}
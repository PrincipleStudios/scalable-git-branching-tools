BeforeAll {
    . $PSScriptRoot/validate-featuretype.ps1
}

Describe 'Validate-FeatureType' {
    It 'returns successfully for a valid feature type' {
        { Validate-FeatureType 'feature' } | Should -Not -Throw
        { Validate-FeatureType 'bugfix' } | Should -Not -Throw
    }
    
    It 'errors for an invalid feature type' {
        { Validate-FeatureType 'feat' } | Should -Throw
    }
    
    It 'errors for empty strings' {
        { Validate-FeatureType '' } | Should -Throw
    }
    
    It 'returns successfully for empty strings when flagged with optional' {
        { Validate-FeatureType '' -optional } | Should -Not -Throw
    }
}
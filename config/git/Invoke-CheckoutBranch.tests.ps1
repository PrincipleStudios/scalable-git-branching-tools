BeforeAll {
    . $PSScriptRoot/Invoke-CheckoutBranch.ps1
}

Describe 'Invoke-CheckoutBranch' {
    It 'throws if exit code is non-zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout some-branch --quiet' } { $Global:LASTEXITCODE = 1 }
            
        { Invoke-CheckoutBranch some-branch -quiet } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout some-branch --quiet' } { $Global:LASTEXITCODE = 0 }
        
        Invoke-CheckoutBranch some-branch -quiet
    }
}

BeforeAll {
    . $PSScriptRoot/Invoke-CreateBranch.ps1
}

Describe 'Invoke-CreateBranch' {
    It 'throws if exit code is non-zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch some-branch source --quiet' } { $Global:LASTEXITCODE = 1 }
            
        { Invoke-CreateBranch some-branch source } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch some-branch source --quiet' } { $Global:LASTEXITCODE = 0 }
        
        Invoke-CreateBranch some-branch source
    }
}

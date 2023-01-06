BeforeAll {
    . $PSScriptRoot/Invoke-CreateBranch.ps1
    
    Mock git {
        throw "Unmocked git command: $args"
    }
}

Describe 'Invoke-CreateBranch' {
    It 'throws if exit code is non-zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch some-branch source --quiet --no-track' } { $Global:LASTEXITCODE = 1 }
            
        { Invoke-CreateBranch some-branch source } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch some-branch source --quiet --no-track' } { $Global:LASTEXITCODE = 0 }
        
        Invoke-CreateBranch some-branch source
    }
}

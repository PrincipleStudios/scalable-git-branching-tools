Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"

function Initialize-CleanWorkingDirectory() {
    Invoke-WrapMock `
        $(
            New-VerifiableMock `
                -ModuleName Assert-CleanWorkingDirectory `
                -CommandName git `
                -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' }
        ) `
        -MockWith {
            $Global:LASTEXITCODE = 0
        }
    Invoke-WrapMock `
        $(
            New-VerifiableMock `
                -ModuleName Assert-CleanWorkingDirectory `
                -CommandName git `
                -ParameterFilter { ($args -join ' ') -eq 'clean -n' }
        ) `
        -MockWith {
            $Global:LASTEXITCODE = 0
        }
}

function Initialize-DirtyWorkingDirectory() {
    Invoke-WrapMock `
        $(
            New-VerifiableMock `
                -ModuleName Assert-CleanWorkingDirectory `
                -CommandName git `
                -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' }
        ) `
        -MockWith {
            $Global:LASTEXITCODE = 1
        }
}

function Initialize-UntrackedFiles() {
    Invoke-WrapMock `
        $(
            New-VerifiableMock `
                -ModuleName Assert-CleanWorkingDirectory `
                -CommandName git `
                -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' }
        ) `
        -MockWith {
            $Global:LASTEXITCODE = 0
        }
    Invoke-WrapMock `
        $(
            New-VerifiableMock `
                -ModuleName Assert-CleanWorkingDirectory `
                -CommandName git `
                -ParameterFilter { ($args -join ' ') -eq 'clean -n' }
        ) `
        -MockWith {
            "Would remove <some-file>"
            $Global:LASTEXITCODE = 0
        }
}

Export-ModuleMember -Function Initialize-CleanWorkingDirectory, Initialize-DirtyWorkingDirectory, Initialize-UntrackedFiles

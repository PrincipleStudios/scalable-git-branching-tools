Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"

function Invoke-MockGit([string] $gitCli, [scriptblock] $MockWith) {
    $result = New-VerifiableMock `
        -ModuleName 'Assert-CleanWorkingDirectory' `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq '$gitCli'"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            if ($MockWith -ne $nil) {
                & $MockWith
            }
        }.GetNewClosure()
    return $result
}

function Initialize-CleanWorkingDirectory() {
    Invoke-MockGit 'diff --stat --exit-code --quiet'
    Invoke-MockGit 'clean -n'
}

function Initialize-DirtyWorkingDirectory() {
    Invoke-MockGit 'diff --stat --exit-code --quiet' { $Global:LASTEXITCODE = 1 }
}

function Initialize-UntrackedFiles() {
    Invoke-MockGit 'diff --stat --exit-code --quiet'
    Invoke-MockGit 'clean -n' { "Would remove <some-file>" }
}

Export-ModuleMember -Function Initialize-CleanWorkingDirectory, Initialize-DirtyWorkingDirectory, Initialize-UntrackedFiles

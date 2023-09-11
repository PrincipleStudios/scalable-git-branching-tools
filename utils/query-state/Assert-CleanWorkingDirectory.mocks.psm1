Import-Module -Scope Local "$PSScriptRoot/../../config/testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Assert-CleanWorkingDirectory' @PSBoundParameters
}

function Initialize-CleanWorkingDirectory() {
    Invoke-MockGit 'diff --stat --exit-code' { $Global:LASTEXITCODE = 0 }
    Invoke-MockGit 'clean -n' { $Global:LASTEXITCODE = 0 }
}

function Initialize-DirtyWorkingDirectory() {
    Invoke-MockGit 'clean -n' { $Global:LASTEXITCODE = 0 }
    Invoke-MockGit 'diff --stat --exit-code' { $Global:LASTEXITCODE = 1 }
}

function Initialize-UntrackedFiles() {
    Invoke-MockGit 'diff --stat --exit-code'
    Invoke-MockGit 'clean -n' { "Would remove <some-file>" }
}

Export-ModuleMember -Function Initialize-CleanWorkingDirectory, Initialize-DirtyWorkingDirectory, Initialize-UntrackedFiles

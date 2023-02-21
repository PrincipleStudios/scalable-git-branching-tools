Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Assert-CleanWorkingDirectory' @PSBoundParameters
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

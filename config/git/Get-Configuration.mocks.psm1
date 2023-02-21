Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Invoke-MockGit([string] $gitCli, [scriptblock] $MockWith) {
    $result = New-VerifiableMock `
        -ModuleName 'Get-Configuration' `
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

function Initialize-ToolConfiguration(
    [switch]$noRemote,
    [string]$remote = 'origin',
    [string]$defaultServiceLine = 'main',
    [string]$upstreamBranchName = '_upstream',
    [switch]$noAtomicPush
) {
    if ($noRemote) {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
    } else {
        Invoke-MockGit 'config scaled-git.remote' { $remote }.GetNewClosure()
    }

    Invoke-MockGit 'config scaled-git.upstreamBranch' { $upstreamBranchName }.GetNewClosure()
    Invoke-MockGit -ParameterFilter 'config scaled-git.defaultServiceLine' -MockWith { $defaultServiceLine }.GetNewClosure()
    Invoke-MockGit -ParameterFilter 'config scaled-git.atomicPushEnabled' -MockWith { -not $noAtomicPush }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-ToolConfiguration

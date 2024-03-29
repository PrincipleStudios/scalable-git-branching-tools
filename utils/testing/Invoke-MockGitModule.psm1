Import-Module -Scope Local "$PSScriptRoot/Invoke-VerifyMock.psm1"

function Invoke-MockGitModule([string] $ModuleName, [string] $gitCli, [object] $MockWith) {
    if ($gitCli.StartsWith('git ')) {
        throw "Incorrect use of Invoke-MockGitModule - do not include 'git' at the beginning"
    }
    $gitCli = $gitCli.Replace("'", "''")
    $result = New-VerifiableMock `
        -ModuleName $ModuleName `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq '$gitCli'"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            if ($MockWith -is [scriptblock]) {
                & $MockWith
            } elseif ($MockWith -ne $nil) {
                $MockWith
            }
        }.GetNewClosure()
    return $result
}

Export-ModuleMember -Function Invoke-MockGitModule

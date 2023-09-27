Import-Module -Scope Local "$PSScriptRoot/Invoke-VerifyMock.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith, [switch] $fail) {
    $result = New-VerifiableMock `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq '$gitCli'"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = $fail ? 1 : 0
            if ($MockWith -is [scriptblock]) {
                & $MockWith
            } elseif ($MockWith -ne $nil) {
                $MockWith
            }
        }.GetNewClosure()
    return $result
}

Export-ModuleMember -Function Invoke-MockGit

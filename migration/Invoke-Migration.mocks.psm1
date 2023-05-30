Import-Module -Scope Local "$PSScriptRoot/../config/testing/Invoke-VerifyMock.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-Migration.psm1"

function Initialize-RunNoMigrations([Parameter(Mandatory)][string] $from) {
    $result = New-VerifiableMock `
        -ModuleName 'Invoke-Migration' `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ').StartsWith('rev-list --count ^$from ')"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            return 0
        }.GetNewClosure()
    return $result
}

function Initialize-RunMigration([Parameter(Mandatory)][string] $from, [Parameter(Mandatory)][string] $target) {
    $result = New-VerifiableMock `
        -ModuleName 'Invoke-Migration' `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq 'rev-list --count ^$from $target'"))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            return 1
        }.GetNewClosure()
    return $result
}

Export-ModuleMember -Function Initialize-RunNoMigrations, Initialize-RunMigration

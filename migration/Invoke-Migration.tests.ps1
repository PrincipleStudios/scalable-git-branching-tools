BeforeAll {
    . "$PSScriptRoot/../utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-Migration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-Migration.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host -ModuleName 'Invoke-Migration' { throw 'Ran something it shouldn''t have' }
    Mock -CommandName Write-Debug -ModuleName 'Invoke-Migration' {}
}

Describe 'Invoke-Migration' {
    It 'runs no migrations unless configured' {
        $commit = 'baadf00d'
        $mock = Initialize-RunNoMigrations $commit

        Invoke-Migration -from $commit

        Invoke-VerifyMock $mock -Times 1
    }

    It 'runs a migration if newer' {
        $commit = 'baadf00d'
        $mock = Initialize-RunNoMigrations $commit
        Initialize-RunMigration $commit 'cd9b27ecd32526716f7b374ba05780ce49366cc8'

        $paramFilter = { $object -eq 'Running migration, such as updating local configuration.' }
        Mock -CommandName Write-Host -ModuleName 'Invoke-Migration' -ParameterFilter $paramFilter

        Invoke-Migration -from $commit

        Invoke-VerifyMock $mock -Times 1
        Should -Invoke -CommandName Write-Host -ModuleName 'Invoke-Migration' -ParameterFilter $paramFilter -Times 1
    }
}

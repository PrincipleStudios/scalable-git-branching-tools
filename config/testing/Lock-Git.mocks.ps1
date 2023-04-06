# Not a module because `Mock git` doesn't apply to non-module code when inside a module.

Mock git { throw "Unmocked git command: $args" }

Get-ChildItem -Path "$PSScriptRoot/.." -Include "*.psm1" -Exclude "*.mocks.psm1" -Recurse | ForEach-Object {
    Import-Module -Scope Local $_.FullName
    $moduleName = ([System.IO.Path]::GetFileNameWithoutExtension($_.Name))

    Mock -CommandName git -ModuleName $moduleName `
        -MockWith $([scriptblock]::Create("throw `"Unmocked git command in module $($moduleName): `$args`""))
}

# Prevent accidentally invoking a real process for most tests
Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-PipeToProcess.psm1"
Mock -CommandName New-Object -ModuleName Invoke-PipeToProcess { throw 'Process was being created; make sure you use a mock for Invoke-PipeToProcess'}

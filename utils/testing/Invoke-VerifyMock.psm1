function New-VerifiableMock([string] $ModuleName, [string] $commandName, [scriptblock] $parameterFilter
) {
    return @{
        ModuleName = $ModuleName;
        commandName = $commandName;
        parameterFilter = $parameterFilter;
    }
}

function Invoke-WrapMock([Object] $verifiableMock,
    [ScriptBlock] $MockWith
) {
    Mock -ModuleName $verifiableMock.ModuleName -CommandName $verifiableMock.commandName -ParameterFilter $verifiableMock.parameterFilter -MockWith $MockWith
}

function Invoke-VerifyMock([Object] $verifiableMock,
    [int] $Times
) {
    $verifiableMock | ForEach-Object {
        if ($null -eq $_) { return }
        $info = "ModuleName = $($_.ModuleName), CommandName = $($_.commandName), ParameterFilter = $($_.parameterFilter)"
        try {
            Should -ModuleName $_.ModuleName -Invoke -CommandName $_.commandName -ParameterFilter $_.parameterFilter -Times $Times
        } catch {
            Write-Host "Exception encountered while verifying mocks; $info"
            throw
        }
    }
}

Export-ModuleMember New-VerifiableMock, Invoke-VerifyMock, Invoke-WrapMock

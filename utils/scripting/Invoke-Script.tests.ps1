Describe 'Invoke-Script' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../actions.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-Script.psm1"
        . "$PSScriptRoot/../testing.ps1"
    }

    BeforeEach {
        Register-Framework

        Mock -CommandName Invoke-LocalAction -ModuleName Invoke-Script -MockWith { throw 'Unmocked local action' }
        Mock -CommandName Invoke-FinalizeAction -ModuleName Invoke-Script -MockWith { throw 'Unmocked finalize action' }

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = New-Diagnostics
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = Register-Diagnostics -throwInsteadOfExit
    }

    It 'runs local and finalize scripts' {
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { @{ 'part1' = 'complete' } }
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' } -MockWith { @{ 'part2' = 'complete' } }
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '3' } -MockWith { @{ 'part3' = 'complete' } }
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '4' } -MockWith { @{ 'part4' = 'complete' } }

        Invoke-Script ('{
            "local": [
                { "type": "1" },
                { "type": "2" }
            ],
            "finalize": [
                { "type": "3" },
                { "type": "4" }
            ]
        }' | ConvertFrom-Json) -diagnostics $diag
        Get-HasErrorDiagnostic $diag | Should -Be $false

        Should -InvokeVerifiable
    }
    It 'allows parameterization from external sources' {
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' -AND $actionDefinition.parameters.item -eq 'foo' } { @{ 'part1' = 'complete' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' -AND $actionDefinition.parameters.item -eq 'bar' } { @{ 'part2' = 'complete' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '3' -AND $actionDefinition.parameters.item -eq 'baz' } { @{ 'part3' = 'complete' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '4' } { @{ 'part4' = 'complete' } }

        $params = @{
            foo = 'foo'
            bar = 'bar'
            baz = 'baz'
        }
        Invoke-Script ('{
            "local": [
                { "type": "1", "parameters": { "item": "$($params.foo)" } },
                { "type": "2", "parameters": { "item": "$($params.bar)" } }
            ],
            "finalize": [
                { "type": "3", "parameters": { "item": "$($params.baz)" } },
                { "type": "4" }
            ]
        }' | ConvertFrom-Json) $params -diagnostics $diag
        Get-HasErrorDiagnostic $diag | Should -Be $false

        Should -InvokeVerifiable
    }
    It 'allows parameterization from other actions' {
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { @{ 'part1' = 'foo' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' -AND $actionDefinition.parameters.item -eq 'foo' } -MockWith { @{ 'part2' = 'bar' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '3' -AND $actionDefinition.parameters.item -eq 'bar' } -MockWith { @{ 'part3' = 'baz' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '4' -AND $actionDefinition.parameters.item -eq 'bar' } -MockWith { @{ 'part4' = 'complete' } }

        Invoke-Script ('{
            "local": [
                { "id": "1", "type": "1" },
                { "id": "2", "type": "2", "parameters": { "item": "$($actions[\"1\"].outputs[\"part1\"])" } }
            ],
            "finalize": [
                { "id": "3", "type": "3", "parameters": { "item": "$($actions[\"2\"].outputs[\"part2\"])" } },
                { "id": "4", "type": "4", "parameters": { "item": "$($actions[\"2\"].outputs[\"part2\"])" } }
            ]
        }' | ConvertFrom-Json) -diagnostics $diag
        Get-HasErrorDiagnostic $diag | Should -Be $false

        Should -InvokeVerifiable
    }
    It 'does not allow parameters from within finalize stage' {
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { @{ 'part1' = 'foo' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' -AND $actionDefinition.parameters.item -eq 'foo' } -MockWith { @{ 'part2' = 'bar' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { }

        {
            Invoke-Script ('{
                "local": [
                    { "id": "1", "type": "1" },
                    { "id": "2", "type": "2", "parameters": { "item": "$($actions[\"1\"].outputs[\"part1\"])" } }
                ],
                "finalize": [
                    { "id": "3", "type": "3", "parameters": { "item": "$($actions[\"2\"].outputs[\"part2\"])" } },
                    { "id": "4", "type": "4", "parameters": { "item": "$($actions[\"3\"].outputs[\"part3\"])" } }
                ]
            }' | ConvertFrom-Json) -diagnostics $diag
        } | Should -Throw 'Fake Exit-DueToAssert'
        Get-HasErrorDiagnostic $diag | Should -Be $true
        $output | Should -contain "WARN: Unable to evaluate script: '`$(`$actions[`"3`"].outputs[`"part3`"])'"
        $output | Should -contain 'ERR:  Could not apply parameters for finalize actions; see above errors.'

        Should -InvokeVerifiable
    }
    It 'halts if an error is encountered within local before moving to finalize' {
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' } -MockWith { Add-ErrorDiagnostic $diag 'Stop here' }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { }

        {
            Invoke-Script ('{
                "local": [
                    { "type": "1" },
                    { "type": "2" }
                ],
                "finalize": [
                    { "type": "3" },
                    { "type": "4" }
                ]
            }' | ConvertFrom-Json) -diagnostics $diag
        } | Should -Throw 'Fake Exit-DueToAssert'
        Get-HasErrorDiagnostic $diag | Should -Be $true
        $output | Should -Contain 'ERR:  Stop here'

        Should -InvokeVerifiable
        Should -Invoke -CommandName Invoke-FinalizeAction -ModuleName Invoke-Script -Times 0
    }
    It 'allows other local actions to process even if an error is encountered' {
        
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { throw 'Cannot run 1' }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' } -MockWith { @{ 'part2' = 'bar' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { }

        {
            Invoke-Script ('{
                "local": [
                    { "type": "1" },
                    { "type": "2" }
                ],
                "finalize": [
                    { "type": "3" },
                    { "type": "4" }
                ]
            }' | ConvertFrom-Json) -diagnostics $diag
        } | Should -Throw 'Fake Exit-DueToAssert'
        Get-HasErrorDiagnostic $diag | Should -Be $true
        $output | Should -Contain 'ERR:  Encountered error while running local action #1 (1-based): See the following error.'
        $entry = ($output | Where-Object { $_.StartsWith('ERR:  Cannot run 1') })
        $entry.Count | Should -Be 1

        Should -InvokeVerifiable
        Should -Invoke -CommandName Invoke-FinalizeAction -ModuleName Invoke-Script -Times 0
    }
    It 'does not process local actions out of order' {
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { @{ 'part1' = 'foo' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' -AND $actionDefinition.parameters.item -eq 'foo' } -MockWith { @{ 'part2' = 'bar' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '3' -AND $actionDefinition.parameters.item -eq 'bar' } -MockWith { @{ 'part3' = 'baz' } }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '4' -AND $actionDefinition.parameters.item -eq 'baz' } -MockWith { @{ 'part4' = 'complete' } }

        {
            Invoke-Script ('{
                "local": [
                    { "id": "2", "type": "2", "parameters": { "item": "$($actions[\"1\"].outputs[\"part1\"])" } },
                    { "id": "1", "type": "1" }
                ],
                "finalize": [
                    { "id": "3", "type": "3", "parameters": { "item": "$($actions[\"2\"].outputs[\"part2\"])" } },
                    { "id": "4", "type": "4", "parameters": { "item": "$($actions[\"3\"].outputs[\"part3\"])" } }
                ]
            }' | ConvertFrom-Json) -diagnostics $diag
        } | Should -Throw 'Fake Exit-DueToAssert'
        Get-HasErrorDiagnostic $diag | Should -Be $true
        $output | Should -Contain 'ERR:  Could not apply parameters to local action 2; see above errors.'

        Should -InvokeVerifiable
    }
    It 'does not process finalize actions after one fails' {
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '1' } -MockWith { @{ 'part1' = 'complete' } }
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-LocalAction { $actionDefinition.type -eq '2' } -MockWith { @{ 'part2' = 'complete' } }
        Mock -Verifiable -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '3' } -MockWith { throw 'Cannot run 3' }
        Mock -ModuleName Invoke-Script -CommandName Invoke-FinalizeAction { $actionDefinition.type -eq '4' } -MockWith { @{ 'part4' = 'complete' } }

        {
            Invoke-Script ('{
                "local": [
                    { "type": "1" },
                    { "type": "2" }
                ],
                "finalize": [
                    { "type": "3" },
                    { "type": "4" }
                ]
            }' | ConvertFrom-Json) -diagnostics $diag
        } | Should -Throw 'Fake Exit-DueToAssert'
        Get-HasErrorDiagnostic $diag | Should -Be $true
        $output | Should -Contain 'ERR:  Encountered error while running finalize action #1 (1-based): See the following error.'
        $entry = ($output | Where-Object { $_.StartsWith('ERR:  Cannot run 3') })
        $entry.Count | Should -Be 1

        Should -InvokeVerifiable
        Should -Invoke -CommandName Invoke-FinalizeAction -ModuleName Invoke-Script -ParameterFilter { $actionDefinition.type -eq '4' } -Times 0
    }
}

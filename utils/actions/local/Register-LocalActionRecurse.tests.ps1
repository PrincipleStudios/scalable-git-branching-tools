Describe 'local action "recurse"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        Initialize-ToolConfiguration

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "recurse",
            "parameters": {
                "inputParameters": [{
                    "target": "10"
                }, {
                    "target": "20"
                }],
                "path": "mock-script"
            }
        }' | ConvertFrom-Json)

        function Get-InnerScript([string] $mode) {
            return '{
                "recursion": {
                    "mode": "' + $mode + '",
                    "paramScript": "$actions.children.outputs | Where-Object { $null -ne $_ -AND $_ -notin ($previous | ForEach-Object { $_.target }) } | ForEach-Object { @{ target = $_ } }",
                    "map": "$actions.handled.outputs",
                    "reduceToOutput": "$mapped -join \" \""
                },
                "prepare": [{
                    "id": "children",
                    "type": "get-children",
                    "parameters": {
                        "target": "$params.target"
                    }
                }],
                "act": [{
                    "id": "handled",
                    "type": "handle-target",
                    "parameters": {
                        "target": "$params.target"
                    }
                }]
            }'
        }
    }

    Context 'depth-first' {
        BeforeEach {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $innerScript = Get-InnerScript "depth-first"
        }

        It 'processes output in the correct order' {
            Initialize-LocalActionRecurseSuccess -ScriptName "mock-script" -ScriptContents $innerScript
            Initialize-FakeLocalAction "get-children" {
                param($target)
                if ($target -eq '10') { return @('11', '12') }
                if ($target -eq '20') { return @('21', '22') }
            } 
            Initialize-FakeLocalAction "handle-target" {
                param($target)
                if ($target -eq '11') { return '1' }
                if ($target -eq '12') { return '2' }
                if ($target -eq '10') { return '3' }
                if ($target -eq '21') { return '4' }
                if ($target -eq '22') { return '5' }
                if ($target -eq '20') { return '6' }
            }

            $output = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
            $output | Should -Be '1 2 3 4 5 6'

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
    }

    Context 'breadth-first' {
        BeforeEach {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $innerScript = Get-InnerScript "breadth-first"
        }

        It 'processes output in the correct order' {
            Initialize-LocalActionRecurseSuccess -ScriptName "mock-script" -ScriptContents $innerScript
            Initialize-FakeLocalAction "get-children" {
                param($target)
                if ($target -eq '10') { return @('11', '12') }
                if ($target -eq '20') { return @('21', '22') }
            } 
            Initialize-FakeLocalAction "handle-target" {
                param($target)
                if ($target -eq '10') { return '1' }
                if ($target -eq '20') { return '2' }
                if ($target -eq '11') { return '3' }
                if ($target -eq '12') { return '4' }
                if ($target -eq '21') { return '5' }
                if ($target -eq '22') { return '6' }
            }

            $output = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
            $output | Should -Be '1 2 3 4 5 6'

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
    }
}

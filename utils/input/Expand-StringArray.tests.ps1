Describe 'Expand-StringArray' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/Expand-StringArray.psm1"
    }

    It 'handles a single value' {
        $result = Expand-StringArray 'one'
        $result | Should -BeExactly @('one')
    }

    It 'handles a single value as an array' {
        $result = Expand-StringArray @('one')
        Should -BeExactly @('one') -ActualValue $result
    }

    It 'handles correctly-formatted array input' {
        $result = Expand-StringArray @('one','two','three')
        $result | Should -BeExactly @('one','two','three')
    }

    It 'handles input with a single comma-delimited string' {
        $result = Expand-StringArray 'one,two,three'
        $result | Should -BeExactly @('one','two','three')
    }

    It 'handles input with a single comma-delimited string in an array' {
        $result = Expand-StringArray @('one,two,three')
        $result | Should -BeExactly @('one','two','three')
    }

    It 'handles input with a mixed array' {
        $result = Expand-StringArray @('one,two','three')
        $result | Should -BeExactly @('one','two','three')
    }

    It 'handles input with a string' {
        $result = Expand-StringArray 'one,two','three'
        $result | Should -BeExactly @('one','two','three')
    }

    It 'allows null' {
        $result = Expand-StringArray $nil
        Should -ActualValue $result.GetType().FullName -Match '.*\[]'
        Should -ActualValue $result.Length -BeExactly 0
    }
}
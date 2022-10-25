BeforeAll {
    . $PSScriptRoot/to-kebab.ps1
}

Describe 'To-Kebab' {
    It 'lower-cases and skewers' {
        To-Kebab 'Services: update API' | Should -BeExactly 'services-update-api'
    }
    It 'Removes leading and trailing characters' {
        To-Kebab '@Services:' | Should -BeExactly 'services'
    }
    It 'preserves existing formats' {
        To-Kebab 'services-update-api' | Should -BeExactly 'services-update-api'
    }
    It 'handles digits' {
        To-Kebab '1 2 3' | Should -BeExactly '1-2-3'
    }
    It 'preserves periods except at the end' {
        To-Kebab 'Ends with a period.  ' | Should -BeExactly 'ends-with-a-period'
        To-Kebab 'Period .In. Middle' | Should -BeExactly 'period.in.middle'
        To-Kebab '2022-07-14.1' | Should -BeExactly '2022-07-14.1'
    }
}
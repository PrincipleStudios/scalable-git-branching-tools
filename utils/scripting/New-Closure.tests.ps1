Describe 'New-Closure' {
    BeforeAll {
        . "$PSScriptRoot/../testing.ps1"
    }

    It 'allows a script to bind custom variables' {
        $resultScript = New-Closure { $one + $two } -variables @{ one = 1; two = 2 }
        $actual = Invoke-Command $resultScript
        $actual | Should -Be 3
    }
    
    It 'allows a script to bind custom variables, even nested' {
        $resultScript = New-Closure { $one.deep + $two } -variables @{ one = @{ deep = 1 }; two = 2 }
        $actual = Invoke-Command $resultScript
        $actual | Should -Be 3
    }
    
    It 'allows a script to update the original object references, if nested' {
        $data = @{ one = 1; two = 2 }
        $resultScript = New-Closure { $data.three = $data.one + $data.two } -variables @{ data = $data }
        $actual = Invoke-Command $resultScript
        $data.three | Should -Be 3
        $actual | Should -Be $null
    }
    
    It 'disallows access to the root variables' {
        $resultScript = New-Closure {
            Set-StrictMode -Version 3.0;
            $variables.one
        } -variables @{ one = 1; two = 2 }
        { Invoke-Command $resultScript } | Should -Throw "The variable '`$variables' cannot be retrieved because it has not been set."
    }
    
    It 'disallows access to the root script' {
        $resultScript = New-Closure {
            Set-StrictMode -Version 3.0;
            $sourceScript
        } -variables @{ one = 1; two = 2 }
        { Invoke-Command $resultScript } | Should -Throw "The variable '`$sourceScript' cannot be retrieved because it has not been set."
    }
    
}

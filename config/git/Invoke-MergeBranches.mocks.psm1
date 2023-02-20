Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"

$abortFilter = New-VerifiableMock `
    -ModuleName Invoke-MergeBranches `
    -CommandName git `
    -ParameterFilter { ($args -join ' ') -eq 'merge --abort' }

function Initialize-InvokeMergeSuccess([String] $branch) {
    $result = New-VerifiableMock `
        -ModuleName Invoke-MergeBranches `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq 'merge $branch --quiet --commit --no-edit --no-squash'"))
    Invoke-WrapMock $result -MockWith { $Global:LASTEXITCODE = 0 }

    return $result
}

function Initialize-InvokeMergeFailure([String] $branch, [Switch] $noAbort) {
    $result = New-VerifiableMock `
        -ModuleName Invoke-MergeBranches `
        -CommandName git `
        -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq 'merge $branch --quiet --commit --no-edit --no-squash'"))
    Invoke-WrapMock $result {
        Write-Output "CONFLICT (content): Merge conflict in <some-file>"
        Write-Output "Automatic merge failed; fix conflicts and then commit the result."
        $Global:LASTEXITCODE = 1
    }
    if (-not $noAbort) {
        Invoke-WrapMock $abortFilter -MockWith {$Global:LASTEXITCODE = 0 }
    }

    return $result
}

function Get-MergeAbortFilter() {
    return $abortFilter
}

function Initialize-QuietMergeBranches() {
    Mock -ModuleName Invoke-MergeBranches -CommandName Write-Host {}
}

Export-ModuleMember -Function Initialize-InvokeMergeSuccess, Initialize-InvokeMergeFailure, Get-MergeAbortFilter, Initialize-QuietMergeBranches

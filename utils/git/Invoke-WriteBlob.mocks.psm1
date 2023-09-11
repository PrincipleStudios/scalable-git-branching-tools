Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-PipeToProcess.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteBlob.psm1"

function Lock-InvokeWriteBlob() {
    Mock -ModuleName Invoke-WriteBlob -CommandName Invoke-PipeToProcess -MockWith {
        throw "Invoke-WriteBlob was not set up for this test"
    }
}

function VerifyBlobEntries([System.Byte[]] $inputBytes, [scriptblock]$action) {
    $StdIn = New-Object System.IO.MemoryStream
    $StdOut = New-Object System.IO.MemoryStream
    $StdErr = New-Object System.IO.MemoryStream
    try {
        & $action `
            -StdinStream $StdIn `
            -StdoutStream $StdOut `
            -StderrStream $StdErr | Out-Null

        $inputResult = $StdIn.ToArray()
    } finally {
        $StdIn.Dispose()
        $StdOut.Dispose()
        $StdErr.Dispose()
    }

    return (ConvertTo-Json $inputResult) -eq (ConvertTo-Json $inputBytes)
}

function Initialize-WriteBlob([System.Byte[]] $inputBytes, [String]$resultSha) {
    $filter = $([scriptblock]::Create("`VerifyBlobEntries -inputBytes @($(($inputBytes | ForEach-Object { "$_" }) -join ', ')) -action `$action"))

    Mock -ModuleName Invoke-WriteBlob -CommandName Invoke-PipeToProcess -ParameterFilter $filter -MockWith {
        return $resultSha
    }.GetNewClosure()
}

Export-ModuleMember -Function Lock-InvokeWriteBlob, Initialize-WriteBlob

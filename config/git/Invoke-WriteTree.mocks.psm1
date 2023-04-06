Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-PipeToProcess.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.psm1"

function Lock-InvokeWriteTree() {
    Mock -ModuleName Invoke-WriteTree -CommandName Invoke-PipeToProcess -MockWith {
        throw "Invoke-WriteTree was not set up for this test"
    }
}

function VerifyTreeEntries([String[]]$treeEntries, [scriptblock]$action) {
    $StdIn = New-Object System.IO.MemoryStream
    $StdOut = New-Object System.IO.MemoryStream
    $StdErr = New-Object System.IO.MemoryStream
    try {
        & $action `
            -StdinStream $StdIn `
            -StdoutStream $StdOut `
            -StderrStream $StdErr | Out-Null

        $inputResult = [Text.Encoding]::UTF8.GetString($StdIn.ToArray()).Split("`n")
    } finally {
        $StdIn.Dispose()
        $StdOut.Dispose()
        $StdErr.Dispose()
    }

    $results = @(
        $treeEntries | ForEach-Object { $inputResult -contains $_ }
        $inputResult | ForEach-Object { $treeEntries -contains $_ }
    )
    $result = -not ($results -contains $false)

    return $result
}

function Initialize-WriteTree([String[]]$treeEntries, [String]$resultSha) {
    $filter = $([scriptblock]::Create("`VerifyTreeEntries -treeEntries @($(($treeEntries | ForEach-Object { "'$_'" }) -join ', ')) -action `$action"))

    Mock -ModuleName Invoke-WriteTree -CommandName Invoke-PipeToProcess -ParameterFilter $filter -MockWith {
        return $resultSha
    }.GetNewClosure()
}

Export-ModuleMember -Function Lock-InvokeWriteTree, Initialize-WriteTree

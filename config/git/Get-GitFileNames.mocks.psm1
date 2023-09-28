Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFileNames.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-GitFileNames' @PSBoundParameters
}

function Initialize-GitFileNames([string]$branch, [string[]] $files) {
    Invoke-MockGit "rev-parse --verify $($branch)^{tree} -q" "$($branch)@/"

    function RegisterPrefix($prefix, $paths) {
        $groups = $paths `
            | Group-Object -Property {$_.Split('/', 2)[0]}
        $data = $groups `
            | ForEach-Object {
                $_.Count -eq 1 -AND $_.Group[0] -eq $_.Name `
                    ? "100644 blob $($branch)@$($prefix)/$($_.Name)`t$($_.Name)" `
                    : "040000 tree $($branch)@$($prefix)/$($_.Name)`t$($_.Name)"
            }
        $prefixes = $groups | ForEach-Object { $(@($prefix, $_.Name) | Where-Object { $_ }) -join '/' }

        Invoke-MockGit "ls-tree $($branch)@/$($prefix)" $data
        $groups | ForEach-Object {
            if ($_.Count -ne 1 -OR $_.Group[0] -ne $_.Name) {
                $nextPrefix = $prefix -eq '' ? $_.Name : "$($prefix)/$($_.Name)"
                $name = $_.Name
                RegisterPrefix $nextPrefix $($_.Group | Foreach-Object { $_.Substring($name.length + 1)})
            }
        }
    }

    RegisterPrefix '' $files
}

Export-ModuleMember -Function Initialize-GitFileNames

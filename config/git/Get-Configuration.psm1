. $PSScriptRoot/../core/coalesce.ps1

function Get-Configuration() {
    $remote = Get-ConfiguredRemote
    return @{
        remote = $remote
        upstreamBranch = Get-ConfiguredUpstreamBranch
        defaultServiceLine = Get-ConfiguredDefaultServiceLine -remote $remote
        atomicPushEnabled = Get-ConfiguredAtomicPushEnabled
    }
}

function Get-ConfiguredRemote() {
    $result = git config scaled-git.remote
    if ($result -ne $nil) { return $result }
    return git remote | Select-Object -First 1
}

function Get-ConfiguredUpstreamBranch() {
    $result = git config scaled-git.upstreamBranch
    if ($result -ne $nil) {
        return $result;
    }
    return '_upstream'
}

function Get-ConfiguredDefaultServiceLine([string]$remote) {
    $result = git config scaled-git.defaultServiceLine
    if ($result -ne $nil) { return $result }

    $commitish = git rev-parse --verify ($remote -eq $nil -OR $remote -eq '' ? 'main' : "$($remote)/main") -q 2> $nil
    if ($LASTEXITCODE -eq 0) {
        return "main"
    }
    return $nil
}

function Get-ConfiguredAtomicPushEnabled() {
	$result = git config scaled-git.atomicPushEnabled
	if ($result -ne $nil) { return [bool]::Parse($result) }
	return $true
}

Export-ModuleMember -Function Get-Configuration

function Get-CurrentBranch() {
    return (git branch --show-current)
}
Export-ModuleMember -Function Get-CurrentBranch

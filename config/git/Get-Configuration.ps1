function Get-Configuration() {
    return @{
        remote = git config scaled-git.remote
    }
}

function Invoke-LockGitTestHelper {
    git branch --show-current
}
Export-ModuleMember -Function Invoke-LockGitTestHelper

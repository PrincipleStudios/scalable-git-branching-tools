
function Assert-CleanWorkingDirectory() {
    git diff --stat --exit-code --quiet 2> $nil
    if ($LASTEXITCODE -ne 0 -OR (git clean -n) -ne $nil) {
        throw 'Git working directory is not clean.'
    }
}

Export-ModuleMember -Function Assert-CleanWorkingDirectory

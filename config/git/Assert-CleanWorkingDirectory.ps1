
function Assert-CleanWorkingDirectory() {
    git diff --stat --exit-code --quiet 2> $nil
    if ($LASTEXITCODE -ne 0) {
        throw 'Git working directory is not clean.'
    }
}

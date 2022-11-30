
function To-Kebab($comment) {
    return ($comment -replace '[^a-z0-9\.]+', '-' -replace '-*\.-*', '.' -replace '[^a-z0-9]+$', '-' -replace '^-',''  -replace '-$','').ToLower()
}

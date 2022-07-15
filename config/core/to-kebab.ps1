
function To-Kebab($comment) {
    return ($comment -replace '[^a-z]+', '-' -replace '^-',''  -replace '-$','').ToLower()
}

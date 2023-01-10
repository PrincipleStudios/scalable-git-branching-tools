
function Get-AtomicFlag($enabled) {
    return $enabled ? '--atomic' : ''
}

function ConvertTo-PushBranchList([Parameter(Mandatory)][Hashtable] $branches) {
    $result = $branches.Keys | Sort-Object | Foreach-Object {
        "$($branches[$_]):refs/heads/$($_)"
    }
    return $result
}

# Not to be re-exported; used for testing
Export-ModuleMember -Function ConvertTo-PushBranchList

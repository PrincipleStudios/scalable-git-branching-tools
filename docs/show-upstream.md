# `git show-upstream`

Shows what the upstream branches are of the current (or specified) branch.

Usage:

    git-show-upstream.ps1 [-target <string>] [-recurse] [-includeRemote] [-noFetch] [-quiet]

## Parameters

### `[-target] <string>` (Optional)

The name of the branch to list upstream branches. If not specified, use the current branch.

### `-recurse` (Optional)

If specified, list all upstream branches recursively.

### `-includeRemote` (Optional)

If specified, include the remote name (if any) in the output branch list. For
example, if the remote is `origin`, all branches listed would start with
`origin/`.

## `-noFetch` (Optional)

By default, all scripts fetch the latest before processing. To skip this (which
was the old behavior), include `-noFetch`.

## `-quiet` (Optional)

Suppress unnecessary output. Useful when a tool is designed to consume the
output of this script via git rather than via PowerShell.

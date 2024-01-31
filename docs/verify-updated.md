# `git verify-updated`

Verifies that a branch is up-to-date with its upstream branches.

Usage:

    git-verify-updated.ps1 [-target <string>] [-recurse] [-noFetch] [-quiet]

## Parameters

### `[-target] <string>` (Optional)

The branch name to check. If not specified, use the current branch.

### `-recurse` (Optional)

If specified, recursively check upstream branches. If not specified, will only
check the first level of upstream branches.

## `-noFetch` (Optional)

By default, all scripts fetch the latest before processing. To skip this,
include `-noFetch`.

## `-quiet` (Optional)

Suppress unnecessary output. Useful when a tool is designed to consume the
output of this script via git rather than via PowerShell.

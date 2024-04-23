# `git release`

Usage:

    git-release.ps1 [-source] <string> [-target] <string>
        [-comment <string>] [-preserve <string[]>] [-cleanupOnly] [-force]
        [-noFetch] [-dryRun] [-quiet]

## Parameters

### `[-source] <string>` (Mandatory)

The name of the branch to "release".

### `[-target] <string>` (Mandatory)

The name of the branch that will be updated with the released branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, overrides the commit message added to the upstream tracking
branch.

### `-preserve <string[]>` (Optional)

A comma delimited list of branches to preserve in addition to those upstream

### `-cleanupOnly` (Optional)

Use this flag when the released branch (from `-branchName`) was already merged
to the target branch (`-target`) to clean up the included branches.

### `-force` (Optional)

Bypasses up-to-date checks for the source, target, and all branches being
removed.

## `-noFetch` (Optional)

By default, all scripts fetch the latest before processing. To skip this (which
was the old behavior), include `-noFetch`.

### `-dryRun` (Optional)

If specified, changes to branches will be displayed but no actual changes will
be applied.

## `-quiet` (Optional)

Suppress unnecessary output. Useful when a tool is designed to consume the
output of this script via git rather than via PowerShell.

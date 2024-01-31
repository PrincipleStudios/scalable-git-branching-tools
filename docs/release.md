# `git release`

Usage:

    git-release.ps1 [-sourceBranch] <string> [-target] <string> [-comment <string>] [-preserve <string[]>] [-dryRun] [-cleanupOnly]

## Parameters

### `[-sourceBranch] <string>` (Mandatory)

The name of the branch to "release".

### `[-target] <string>` (Mandatory)

The name of the branch that will be updated with the released branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, overrides the commit message added to the upstream tracking branch.

### `-preserve <string[]>` (Optional)

A comma delimited list of branches to preserve in addition to those upstream

### `-dryRun` (Optional)

If specified, changes to branches will be displayed but no actual changes will be applied.

### `-cleanupOnly` (Optional)

Use this flag when the released branch (from `-branchName`) was already merged to the target branch (`-target`) to clean up the included branches.

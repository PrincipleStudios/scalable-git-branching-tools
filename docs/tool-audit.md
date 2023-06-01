# `git tool-audit`

Audits git-tool's configuration. Without any flags, makes no changes.

Usage:

    git tool-audit [-all] [-prune] [-simplify]

## Parameters:

### `[-all]` (Optional)

Apply all audit fixes

### `[-prune]` (Optional)

If specified, removes branches that no longer exist on the remote. This removes them from both upstream of existing branches and their own configuration.

### `[-simplify]` (Optional)

If specified, simplifies upstream branches to remove rendundant ancestors. For legacy versions of git-tools, this is important to run to reduce the overall number of merge conflicts for deep branch trees.

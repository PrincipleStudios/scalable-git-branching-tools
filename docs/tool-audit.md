# `git tool-audit`

Audits git-tool's configuration. Without any flags, runs all audits but does not
apply any changes.

Usage:

    git tool-audit [-apply] [-prune] [-simplify]

## Parameters:

### `-apply` (Optional)

Must be specified to apply changes. Without this flag, runs the specified audits
(or all audits if none are specified) but does not make any changes.

### `-prune` (Optional)

If specified, removes branches that no longer exist on the remote. This removes
them from both upstream of existing branches and their own configuration.

### `-simplify` (Optional)

If specified, simplifies upstream branches to remove rendundant ancestors. For
legacy versions of git-tools, this is important to run to reduce the overall
number of merge conflicts for deep branch trees.

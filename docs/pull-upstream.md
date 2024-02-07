# `git pull-upstream`

Merges all the "upstream" branches into the current branch, or the specified one
if provided. Note that this doesn't ensure those branches are up-to-date, only
merges them into the current branch. If working with a remote, pushes the merge
to the remote.

Usage:

    git-pull-upstream.ps1 [-target <string>] [-recurse] [-dryRun]

## Parameters

### `[-target] <string>` (Optional)

If provided, the script will change branches to the named branch, and
pull-upstream for that branch. If it succeeds, `pull-upstream` will return to
the original branch. Otherwise, conflicts will be left uncommitted.

### `-recurse` (Optional)

If specified, will first attempt to merge branches further upstream. If any
merges fail, the propagation will be halted to prevent irrelevant conflicts from
being reported.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.

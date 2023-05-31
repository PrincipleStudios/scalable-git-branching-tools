# `git pull-upstream`

Merges all the "upstream" branches into the current branch, or the specified one if provided. Note that this doesn't ensure those branches are up-to-date, only merges them into the current branch. If working with a remote, pushes the merge to the remote.

Usage:

    git-pull-upstream.ps1 [[-branchName] <string>]

## Parameters

### `[-branchName] <string>` (Optional)

If provided, the script will change branches to the named branch, and pull-upstream for that branch. If it succeeds, `pull-upstream` will return to the original branch. Otherwise, conflicts will be left uncommitted.

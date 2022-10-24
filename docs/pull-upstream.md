# `git pull-upstream`

Merges all the "upstream" branches into the current branch. Note that this doesn't ensure those branches are up-to-date, only merges them into the current branch.

Usage:

    git-pull-upstream.ps1 [-noFetch]

## Parameters

### `-noFetch` (Optional)

If specified, do not fetch the latest from the remote (if any).

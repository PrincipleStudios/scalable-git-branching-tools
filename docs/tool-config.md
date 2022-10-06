# `git tool-config`

Sets configuration values used by git-tools.

Usage:

    git tool-config [[-remote] <string>] [[-upstreamBranch] <string>] `
        [[-defaultServiceLine] <string>]

## Parameters:

### `-remote <string>`

Sets the remote used where the upstream branch is tracked. Most commands will automatically fetch/push from this remote when set. If not set and the repository has a remote configured, the first remote will be used.

### `-upstreamBranch <string>`

Sets the branch name used to track upstream branches. Defaults to `_upstream`.

### `-defaultServiceLine <string>`

Sets the branch used as the default service line when creating new branches.

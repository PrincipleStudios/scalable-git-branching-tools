# `git tool-update`

Updates git-tools to the latest version based on your branch.

Usage:

    git tool-update [-sourceBranch <string>]

**Notice:** Old versions of git-tools did not update the git-tools. In those
cases, running `git tool-update` will produce no output. For old versions, `cd`
to the folder where git tools is installed, perform a `git pull` (and ensure
you're switched to the branch you want to track, like `main`), then switch back
to your project where you are using git-tools and run `git tool-update`.

## Parameters

### `[-sourceBranch] <string>`

Updates git-tools to the latest of the corresponding branch. If omitted,
defaults to the branch the tools directory has checked out, which is usually
main.

# Git shortcuts for implementing the scalable git branching model

## Prerequisites

- Powershell Core (7+)

## Installation

### Install Powershell tools for macOS

	https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.3

Alternatively, if you already have the .NET Core SDK installed, you can install PowerShell as a .NET Global tool.

	dotnet tool install --global PowerShell --tool-path ~/bin

### Install Git Shortcuts
In your terminal, navigate to the git directory in which you want to use the commands. Then run the `init.ps1`. For example:

    PS C:\Users\Matt\Source\MyProject> ..\git-tools\init.ps1

## Commands

[`git tool-update`](./docs/tool-update.md)

[`git tool-config`](./docs/tool-config.md)

[`git new`](./docs/new.md)

[`git pull-upstream`](./docs/pull-upstream.md)

[`git show-upstream`](./docs/show-upstream.md)

[`git add-upstream`](./docs/add-upstream.md)

[`git rc`](./docs/rc.md)

[`git verify-updated`](./docs/verify-updated.md)

[`git release`](./docs/release.md)

## Resolving Conflicts

Sometimes when merging an infra/feature/fix branch into an rc branch you'll get merge conflicts. Do *not* rebase the rc branch on to your branch to resolve the conflicts as this defeats the whole prupose of this merging strategy which is to be able to create rc branches from arbitrary sets of branches. Instead:

1. Use `git blame` or [Git Lens](https://gitlens.amod.io/) to find the conflicting commits.
2. If needed use [git name-rev](https://git-scm.com/docs/git-name-rev) to find the branch(es) with the conflicting commits.
3. Use `git new integrate/PS-###_PS-###_etc.` to create an integration branch named after the branches to be merged.
4. Use `git merge origin/<branch name>;git add-upstream <branch name>` to the branches to merge one by one.
5. Create a PR for your integrate branch against the rc branch and get it merged ASAP.

## Development

### Tests

Install the latest version of Pester:

    Install-Module Pester -Force
    Import-Module Pester -PassThru

From the git-tools folder, run:

    Invoke-Pester

There are also docker integration tests that actually run the git commands; run:

    docker build .

### Demo

If you want to test it locally, but don't have a git repository set up, you can use one of the samples via Docker! Run one of the following:

    docker build . -t git-tools-demo -f Dockerfile.demo
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=local
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote-release
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote-without-config
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote
    # build arg matches ./demos/demo-<arg>.ps1

Then take the resulting image SHA hash and run:

    docker run --rm -ti git-tools-demo

This will give you a PowerShell prompt in the repos directory; `cd local` and try out the commands!

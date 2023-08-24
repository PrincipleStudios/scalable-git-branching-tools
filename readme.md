# Git shortcuts for implementing the scalable git branching model

## Prerequisites

- Powershell Core (7+)

## Installation

### Install Powershell tools for macOS

	https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.3

Alternatively, if you already have the .NET Core SDK installed, you can install PowerShell as a .NET Global tool.

	dotnet tool install --global PowerShell --tool-path ~/bin

### Install Git Shortcuts

1. See the above prerequisites.
2. Clone this repository. If you are working on multiple projects and need specific versions of the tools, clone it once for each project (or use git workspaces).
3. In your terminal, navigate to the git directory in which you want to use the commands. Then run the `init.ps1` from this repository. For example, if this was cloned in `C:\Users\Matt\Source\git-tools` and you want to use them in "MyProject", run:

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


## Development

### Tests

Install the latest version of Pester:

    Install-Module Pester -Force
    Import-Module Pester -PassThru

From the git-tools folder, run:

    Invoke-Pester

There are also docker integration tests that actually run the git commands; run:

    docker build .

Note that, due to the use of `Import-Module`, PowerShell caches scripts in the local environment. This won't affect users when updating, since each git alias launches a new `pwsh` scope. However, for developers, you can use the following command to pick up changes in any `.psm1` files within this project:

    ./reset.ps1

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
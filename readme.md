# Git shortcuts for implementing the scalable git branching model

## Prerequisites

- Powershell Core (7+)

## Installation

In your terminal, navigate to the git directory in which you want to use the commands. Then run the `init.ps1`. For example:

    PS C:\Users\Matt\Source\MyProject> ..\git-tools\init.ps1

## Tests

Install the latest version of Pester:

    Install-Module Pester -Force
    Import-Module Pester -PassThru

From the git-tools folder, run:

    Invoke-Pester

There are also docker integration tests that actually run the git commands; run:

    docker build .

## Demo

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
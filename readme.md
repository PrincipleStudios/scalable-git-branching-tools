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
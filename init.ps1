#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/'

git config alias.new "!$dir/git-new.ps1"
git config alias.find-branch "!$dir/git-find-branch.ps1"

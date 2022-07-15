#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/'

git config alias.new "!$dir/git-new.ps1"

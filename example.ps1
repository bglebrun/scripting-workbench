#!/usr/bin/env cached-nix-shell
#!nix-shell -i pwsh -p powershell

Write-Host "Hello, World!"
Get-Date
Write-Host $PSVersionTable
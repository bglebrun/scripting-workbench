#!/usr/bin/env cached-nix-shell
#!nix-shell -i pwsh -p powershell
Param (
  [int]$a,
  [int]$b
)
process {
  return ($b -eq 0) ? $a : (./Get-GCD.ps1 -a $b -b ($a % $b))
}

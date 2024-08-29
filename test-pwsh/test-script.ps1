#!/usr/bin/env cached-nix-shell
#!nix-shell -i pwsh -p dotnet-sdk -p powershell -p glibc
#Requires -Version 7
$ErrorActionPreference = 'Stop'; Set-StrictMode -Off

# -- BEGIN: CUSTOMIZE THIS PART.
  # Name of the NuGet package to download.
  $pkgName = 'Vanara.PInvoke.Shell32'

  # If the package assemblies are .NET Standard assemblies, the 'netstandard'
  # assembly must also be referenced - comment out this statement if not needed.
  # Note: .NET Standards are versioned, but seemingly just specifying 'netstandard'
  #       is enough, in both PowerShell editions. If needed, specify the fully qualified,
  #       version-appropriate assembly name explicitly; e.g., for .NET Standard 2.0:
  #          'netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'
  #       In *PowerShell (Core) 7+* only, a shortened version such as 'netstandard, Version=2.0' works too.
  $netStandardAssemblyName = 'netstandard'

  # The target .NET framework to compile the helper .NET SDK project for.
  # Targeting a .NET Standard makes the code work in both .NET Framework and .NET (Core).  
  # If you uncomment this statement, the SDK's default is used, which is 'net5.0' as of this writing.
  $targetFrameworkArgs = '--framework', 'netstandard2.0'

  # Test command that uses the package from PowerShell.
  $testCmdFromPs = { [Vanara.PInvoke.User32]::GetForegroundWindow().DangerousGetHandle() }

  # C# source that uses the package, to be compiled ad-hoc.
  # Note: Modify only the designated locations.
  $csharpSourceCode = @'
    using System;
    // == Specify your `using`'s here.
    using Vanara.PInvoke;
    namespace demo {
      public static class Foo {
        // == Modify only this method; make sure it returns something, ideally the same thing as
        //    PowerShell test command.
        public static IntPtr Bar() { 
          return User32.GetForegroundWindow().DangerousGetHandle();
        }
      }
    }
'@

# -- END of customized part.

# Make sure the .NET SDK is installed.
$null = Get-command dotnet

# Helper function for invoking external programs.
function iu { $exe, $exeArgs = $args; & $exe $exeArgs; if ($LASTEXITCODE) { Throw "'$args' failed with exit code $LASTEXIDCODE." } }


# Create a 'NuGetFromPowerShellDemo' subdirectory in the TEMP directory and change to it.
Push-Location ($tmpDir = New-Item -Force -Type Directory ([IO.Path]::GetTempPath() + "/NuGetFromPowerShellDemo"))

try {
  
  # Create an aux. class-lib project that downloads the NuGet package of interest.
  if (Test-Path "bin\release\*\publish\$pkgName.dll") {
    Write-Verbose -vb "Reusing previously created aux. .NET SDK project for package '$pkgName'"
  }
  else {
    Write-Verbose -vb "Creating aux. .NET SDK project to download and unpack NuGet package '$pkgName'..."
    iu dotnet new classlib --force @targetFrameworkArgs >$null
    iu dotnet add package $pkgName >$null
    iu dotnet publish -c release >$null
  }

  # Determine the full paths of all the assemblies that were published (excluding the helper-project assembly).
  [array] $pkgAssemblyPaths = (Get-ChildItem bin\release\*\publish\*.dll -Exclude "$(Split-Path -Leaf $PWD).dll").FullName

  # Load the package assemblies into the session.
  # !! THIS IS NECESSARY EVEN IF YOU ONLY WANT TO REFERENCE THE PACKAGE
  # !! ALL YOU WANT DO TO IS TO USE THE PACKAGE TO AD HOC-COMPILE C# SOURCE CODE.
  # Write-Verbose -vb "Loading assembly file paths, from $($pkgAssemblyPaths[0] | Split-Path):`n$(($pkgAssemblyPaths | Split-Path -Leaf) -join "`n")"
  Add-Type -LiteralPath $pkgAssemblyPaths

  # Write-Verbose -vb 'Performing a test call FROM POWERSHELL...'
  & $testCmdFromPs

  # Determine the assemblies to pass to Add-Type -ReferencedAssemblies.
  # The NuGet package's assemblies.
  $requiredAssemblies = $pkgAssemblyPaths
  # Additionally, the approriate .NET Standard assembly may need to be referenced.
  if ($netStandardAssemblyName) { $requiredAssemblies += $netStandardAssemblyName }
  # Note: In *PowerShell (Core) 7+*, using -ReferencedAssemblies implicitly
  #       excludes the assemblies that are otherwise available by default, so you
  #       may have to specify additional assemblies, such as 'System.Console'.
  #       Caveat: In .NET (Core), types are often forwarded to other assemblies,
  #               in which case you must use the forwarded-to assembly; e.g.
  #               'System.Drawing.Primitives' rather than just 'System.Drawing' in
  #               order to use type System.Drawing.Point.
  #               What mitigates the problem is that failing to do so results in a 
  #               an error message that mentions the required, forwarded-to assembly.
  # E.g.:
  #  if ($IsCoreCLR) { $requiredAssemblies += 'System.Console' }

  Write-Verbose -vb 'Ad-hoc compiling C# CODE that uses the package assemblies...'
  Add-Type -ReferencedAssemblies $requiredAssemblies -TypeDefinition $csharpSourceCode
  
  Write-Verbose -vb 'Performing a test call FROM AD HOC-COMPILED C# CODE...'
  [demo.Foo]::Bar()

} 
finally {
  Pop-Location
  Write-Verbose -vb "To clean up the temp. dir, exit this session and run the following in a new session:`n`n  Remove-Item -LiteralPath '$tmpDir' -Recurse -Force"
}
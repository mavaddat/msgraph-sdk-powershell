﻿# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[CmdletBinding()]
Param(
    [string[]] $ModuleToGenerate = @(),
    [ValidateSet("v1.0", "beta")]
    $ApiVersion = @("v1.0", "beta"),
    [string] $ArtifactsLocation = (Join-Path $PSScriptRoot "..\artifacts\"),
    [switch] $SkipGeneration = $false,
    [switch] $Build,
    [switch] $Test,
    [switch] $Pack,
    [switch] $EnableSigning,
    [switch] $ExcludeExampleTemplates,
    [switch] $ExcludeNotesSection,
    [switch] $Isolated
)
$ErrorActionPreference = 'Stop'

if ($PSEdition -ne 'Core') {
    Write-Error 'This script requires PowerShell Core to execute. [Note] Generated cmdlets will work in both PowerShell Core or Windows PowerShell.'
}

if (-not $Isolated) {
    Write-Debug 'Creating isolated process...'
    $pwsh = [System.Diagnostics.Process]::GetCurrentProcess().Path
    & "$pwsh" -NonInteractive -NoLogo -NoProfile -File $MyInvocation.MyCommand.Path @PSBoundParameters -Isolated
    return
}

# Module import.
Import-Module PowerShellGet

# Install Powershell-yaml
if (!(Get-Module -Name powershell-yaml -ListAvailable)) {
    Install-Module powershell-yaml -Repository PSGallery -Scope CurrentUser -Force
}

$ScriptRoot = $PSScriptRoot
$ModulesSrc = Join-Path $ScriptRoot "..\src\"
$ModuleMappingPath = (Join-Path $PSScriptRoot "..\config\ModulesMapping.jsonc")
$GenerateServiceModulePS1 = Join-Path $ScriptRoot ".\GenerateServiceModule.ps1" -Resolve

if (-not (Test-Path $ArtifactsLocation)) {
    New-Item -Path $ArtifactsLocation -Type Directory | Out-Null
}

if (-not (Test-Path $ModuleMappingPath)) {
    Write-Error "Module mapping file not be found: $ModuleMappingPath."
}

# Build AutoREST.PowerShell submodule.
Set-Location (Join-Path $ScriptRoot "../autorest.powershell")
rush update --purge
rush build

$RequiredGraphModules = @()
$AuthModuleManifest = Join-Path $ModulesSrc "Authentication" "Authentication" "artifacts" "Microsoft.Graph.Authentication.psd1"
$LoadedAuthModule = Import-Module $AuthModuleManifest -PassThru -ErrorAction SilentlyContinue
if ($null -ne $LoadedAuthModule) {
    $RequiredGraphModules += @{ ModuleName = $LoadedAuthModule.Name ; RequiredVersion = $LoadedAuthModule.Version; PreRelease = $LoadedAuthModule.PrivateData.PSData.PreRelease }
}
else {
    Write-Warning "Module not found in $AuthModuleManifest."
}
if ($ModuleToGenerate.Count -eq 0) {
    [HashTable] $ModuleMapping = Get-Content $ModuleMappingPath | ConvertFrom-Json -AsHashTable
    $ModuleToGenerate = $ModuleMapping.Keys
}

#This is to ensure that the autorest temp folder is cleared before generating the modules
$TempPath = [System.IO.Path]::GetTempPath()
# Check if there is any folder with autorest in the name
$AutoRestTempFolder = Get-ChildItem -Path $TempPath -Recurse -Directory | Where-Object { $_.Name -match "autorest" }

# Go through each folder and forcefully delete autorest related files
$AutoRestTempFolder | ForEach-Object {
    $AutoRestTempFolder = $_
    #Delete files and folders if they exist
    if (Test-Path $AutoRestTempFolder.FullName) {
        #Check if each file in the folder exists
        Get-ChildItem -Path $AutoRestTempFolder.FullName -Recurse | ForEach-Object {
            $File = $_
            Write-Host "Removing cached file $File"
            if (Test-Path $File.FullName) {
                #Remove the file
                Remove-Item -Path $File.FullName -Force
            }
        }
    }
}

$Stopwatch = [system.diagnostics.stopwatch]::StartNew()
$ModuleToGenerate | ForEach-Object -Parallel {
    $Module = $_
    Write-Host -ForegroundColor Green "-------------'Generating $Module'-------------"
    $ServiceModuleParams = @{
        Module                  = $Module
        ModulesSrc              = $using:ModulesSrc
        ApiVersion              = $using:ApiVersion
        SkipGeneration          = $using:SkipGeneration
        Build                   = $using:Build
        Test                    = $using:Test
        Pack                    = $using:Pack
        EnableSigning           = $using:EnableSigning
        ExcludeExampleTemplates = $using:ExcludeExampleTemplates
        ExcludeNotesSection     = $using:ExcludeNotesSection
        ArtifactsLocation       = $using:ArtifactsLocation
        RequiredModules         = $using:RequiredGraphModules
    }
    & $using:GenerateServiceModulePS1 @ServiceModuleParams

    # Go through each folder and forcefully close any open files
    $AutoRestTempFolder | ForEach-Object {
        $AutoRestTempFolder = $_
        #Delete files and folders if they exist
        if (Test-Path $AutoRestTempFolder.FullName) {
            #Check if each file in the folder exists
            Get-ChildItem -Path $AutoRestTempFolder.FullName -Recurse | ForEach-Object {
                $File = $_
                if (Test-Path $File.FullName) {
                    #Check if the file is open and close it
                    try {
                        $FileStream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
                        $FileStream.Close()
                    }
                    catch {
                        Write-Host "Failed to close file: $File"
                    }
                }
            }
        }
    }
                


} -ThrottleLimit 1
$stopwatch.Stop()
Write-Host -ForegroundColor Green "Generated SDK in '$($Stopwatch.Elapsed.TotalMinutes)' minutes."

[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $false)]
    $ProjectName,
    [String] [Parameter(Mandatory = $false)]
    $BuildConfiguration = "Release",
    [String] [Parameter(Mandatory = $true)]
    $OutputFolder = ".\publish",
    [string] [Parameter(Mandatory = $true)]
    $PreRelease,
    [String] [Parameter(Mandatory = $false)]
    $WorkingFolder = "",
    [String] [Parameter(Mandatory = $false)]
    $SourceFolder = "",
    [String] [Parameter(Mandatory = $true)]
    $SpecificRuntime,
    [String] [Parameter(Mandatory = $true)]
    $UnstableRuntime
)

Write-Verbose "Entering script BuildNugetPackage.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

Function Main
{
    Import-Module "$(Split-Path -parent $PSCommandPath)\Common.psm1"

    if($BuildConfiguration.Trim() -eq "")
    {
        $BuildConfiguration = "Release"
    }

    $SourceFolder = Get-TrimedPath $SourceFolder

    $isPreRelease = [System.Convert]::ToBoolean($PreRelease)

    $OutputFolder = $OutputFolder.Trim('"')

    if($isPreRelease)
    {
        $prefix = "pre-"

        $VersionRegex = "\d+"
        $VersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$VersionRegex)
        $Env:DNX_BUILD_VERSION = $prefix + $VersionData[0]
    }

    Import-Module "$(Split-Path -parent $PSCommandPath)\InstallDNVM.psm1"

    $isSpecificRuntime = [System.Convert]::ToBoolean($SpecificRuntime)
    $isUnstableRuntime = [System.Convert]::ToBoolean($UnstableRuntime)

    Install-DNVM -SpecificRuntime $isSpecificRuntime -UnstableRuntime $isUnstableRuntime

    $projects = $ProjectName.Trim() -split(" ");

    if([string]::IsNullOrWhiteSpace($ProjectName) -Or $projects.Count -eq 0 )
    {
        Write-Output "No Projects specified, build all..."
        $projects = dir -Path "$SourceFolder*\*" -Filter project.json | % {
            $_.Directory.Name
        } | & {$input}
    }

    if($projects.Count -eq 0)
    {
        Write-Error "No projects found in Source Folder!"
        return
    }

    Write-Output "$($projects.Count) Projects to build"

    Write-Output "dnu restore for:"
    Write-Output $projects | % {"    ""$SourceFolder$($_.Trim('"'))""" }

    $projectList = $projects | % {"""$SourceFolder$($_.Trim('"'))""" } | & {"$input"}
    Invoke-Expression "& dnu restore $projectList --no-cache"

    pack($projectList)
}

Function pack($project)
{
    Write-Output "dnu pack for:"
    Write-Output $($project -split(" ") | % { "    $_" })
    Invoke-Expression "& dnu pack $project --configuration $BuildConfiguration --out ""$OutputFolder"""
}

Main

Write-Verbose "Leaving script BuildNugetPackage.ps1"
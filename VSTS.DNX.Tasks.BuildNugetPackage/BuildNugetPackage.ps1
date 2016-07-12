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
    [string] [Parameter(Mandatory = $true)]
    $SkipDotNetInstall
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
    $isSkipDotNetInstall = [System.Convert]::ToBoolean($SkipDotNetInstall)

    $OutputFolder = $OutputFolder.Trim('"')

    $versionSuffix = ""
    if($isPreRelease)
    {
        $prefix = "pre-"

        $VersionRegex = "\d+"
        $VersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$VersionRegex)
        $versionSuffix = "--version-suffix $prefix$($VersionData[0])"
    }

    if($isSkipDotNetInstall)
    {
        Import-Module "$(Split-Path -parent $PSCommandPath)\InstallDotnet.psm1"

        Install-Dotnet
    }

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

    Write-Output "dotnet restore for:"
    Write-Output $projects | % {"    ""$SourceFolder$($_.Trim('"'))""" }

    $projectList = $projects | % {"""$SourceFolder$($_.Trim('"'))""" } | & {"$input"}
    Invoke-Expression "& dotnet restore $projectList"

    Write-Output "dotnet build for:"
    Write-Output $($projectList -split(" ") | % { "    $_" })
    Invoke-Expression "& dotnet build $projectList -c $BuildConfiguration"

    foreach($project in $projects)
    {
        $p = "$SourceFolder$($project.Trim('"'))"
        Write-Output "dotnet pack for:"
        Write-Output "    $p"
        Invoke-Expression "& dotnet pack $p -c $BuildConfiguration -o ""$OutputFolder"" $versionSuffix"
    }
}

Main

Write-Verbose "Leaving script BuildNugetPackage.ps1"
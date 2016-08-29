[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $false)]
    $ProjectName,
    [String] [Parameter(Mandatory = $false)]
    $BuildConfiguration = "Release",
    [String] [Parameter(Mandatory = $true)]
    $OutputFolder = ".\publish",
    [string] [Parameter(Mandatory = $true)]
    $PublishSource,
    [String] [Parameter(Mandatory = $false)]
    $WorkingFolder = "",
    [String] [Parameter(Mandatory = $false)]
    $SourceFolder = "",
    [string] [Parameter(Mandatory = $true)]
    $SkipDotNetInstall
)

Write-Verbose "Entering script BuildWebPackage.ps1"

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

    $isSkipDotNetInstall = [System.Convert]::ToBoolean($SkipDotNetInstall)

    $OutputFolder = $OutputFolder.Trim('"')

    if(-Not $isSkipDotNetInstall)
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
    Write-Output "   Restore done."

    Write-Output "dotnet build for:"
    Write-Output $($projectList -split(" ") | % { "    $_" })
    Invoke-Expression "& dotnet build $projectList -c $BuildConfiguration"
    Write-Output "   Build done."

    foreach($project in $projects)
    {
        $p = "$SourceFolder$($project.Trim('"'))"
        $outDir = (Get-Item $p).Name
        Write-Output "dotnet publish for:"
        Write-Output "    $p"
        Invoke-Expression "& dotnet publish $p -c $BuildConfiguration -o ""$OutputFolder\$outDir"" --no-build"
        Write-Output "    Publish done for: $p"
    }
}

Main

Write-Verbose "Leaving script BuildWebPackage.ps1"
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
    $SourceFolder = ""
)

Write-Verbose "Entering script BuildWebPackage.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

Function Main
{
    if($BuildConfiguration.Trim() -eq "")
    {
        $BuildConfiguration = "Release"
    }

    $SourceFolder = $SourceFolder.Trim().Trim("""").Trim().Replace("/","\\").Trim("\")
    if($SourceFolder -ne "")
    {
        $SourceFolder = ".\" + $SourceFolder + "\"
    }
    else
    {
        $SourceFolder = ".\"
    }

    $isPublishSource = [System.Convert]::ToBoolean($PublishSource)

    $OutputFolder = $OutputFolder.Trim('"')

    Import-Module "$(Split-Path -parent $PSCommandPath)\InstallDNVM.psm1"

    Install-DNVM

    $Env:DNU_PUBLISH_AZURE = $true

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

    build($projectList)

    foreach($project in $projects)
    {
        $p = "$SourceFolder$($project.Trim('"'))"
        publish($p)
    }
}

Function build($project)
{
    Write-Output "dnu build for:"
    Write-Output $($project -split(" ") | % { "    $_" })
    Invoke-Expression "& dnu build $project --configuration $BuildConfiguration"
}

Function publish($project)
{
    $outDir = (Get-Item $project).Name
    $noSource = &{If(!$isPublishSource){"--no-source"}}

    Write-Output "dnu publish for:"
    Write-Output $($project -split(" ") | % { "    $_" })
    Invoke-Expression "& dnu publish $project --configuration $BuildConfiguration --out ""$OutputFolder\$outDir"" --runtime active $noSource"
}

Main

Write-Verbose "Leaving script BuildWebPackage.ps1"
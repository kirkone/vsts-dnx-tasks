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
    $WorkingFolder = ""
)

Write-Verbose "Entering script BuildWebPackasge.ps1"

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

    $isPublishSource = [System.Convert]::ToBoolean($PublishSource)

    Import-Module "$(Split-Path -parent $PSCommandPath)\InstallDNVM.psm1"

    Install-DNVM

    $Env:DNU_PUBLISH_AZURE = $true

    $projects = $ProjectName.Trim() -split(" ");

    if(![string]::IsNullOrWhiteSpace($projectNames) -And $projects.Length -gt 0 )
    {
        Write-Output "$($projects.Length) Projects to build"

        Write-Output "dnu restore for:"
        Write-Output $projects | % {"    "".\src\$($_.Trim('"'))""" }

        $projectList = $projects | % {""".\src\$($_.Trim('"'))""" } | & {"$input"}
        Invoke-Expression "& dnu restore $projectList --no-cache"

        Invoke-Expression "dnu build $projectList --configuration $BuildConfiguration"

        foreach($project in $projects)
        {
            $p = ".\src\$($project.Trim('"'))"
            build($p)
            publish($p)
        }
    }
    else
    {
        Write-Output "No Projects specified, build all..."

        Write-Output "dnu restore"
        Invoke-Expression "& dnu restore .\src"

        dir -Path .\src\*\* -Filter project.json | % {
            $p = $_.Directory.FullName
            build($p)
            publish($p)
        }
    }
}

Function build($project)
{
    Write-Output "dnu build for:"
    Write-Output "    $project"
    Invoke-Expression "& dnu build ""$project"" --configuration $BuildConfiguration"
}

Function publish($project)
{
    $outDir = (Get-Item $project).Name
    $noSource = &{If(!$isPublishSource){"--no-source"}}

    Write-Output "dnu publish for:"
    Write-Output "    $project"
    Write-Output "& dnu publish ""$project"" --configuration $BuildConfiguration --out ""$OutputFolder\$outDir"" --runtime active $noSource"
    Invoke-Expression "& dnu publish ""$project"" --configuration $BuildConfiguration --out ""$OutputFolder\$outDir"" --runtime active $noSource"
}

Main

Write-Verbose "Leaving script BuildWebPackasge.ps1"
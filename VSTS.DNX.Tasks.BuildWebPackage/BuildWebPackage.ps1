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

Write-Host "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ("    $key = $($PSBoundParameters[$key])")
}
Write-Host " "

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
        Write-Host "No Projects specified, build all..."
        $projects = dir -Path "$SourceFolder*\*" -Filter project.json | % {
            $_.Directory.Name
        } | & {$input}
    }

    if($projects.Count -eq 0)
    {
        Write-Host "No projects found in Source Folder!`n`r "
        Write-Host "##vso[task.complete result=Failed;]No projects found in Source Folder!"
        exit 1
    }

    Write-Host "    $($projects.Count) Projects to build`n`r "

    $projectList = $projects | % {"""$SourceFolder$($_.Trim('"'))""" } | & {"$input"}
    Write-Host "dotnet restore for:"
    Write-Host "    $($projectList -split(" ") | % { "$_" })`n`r "

    Invoke-Expression "& dotnet restore $projectList" 2>&1 | Format-Console

    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Restore failed.`n`r "
        Write-Host "##vso[task.complete result=Failed;]Restore Failed!"
        exit 1
    }
    Write-Host "    Restore done.`n`r "

    Write-Host "dotnet build for:"
    Write-Host "    $($projectList -split(" ") | % { "$_" })`n`r "
    Invoke-Expression "& dotnet build $projectList -c $BuildConfiguration --no-incremental" 2>&1 -ErrorVariable buildIssues | Format-Console

    $buildWarnings = $buildIssues|where{$_ -like "*: warning *"}
    $buildErrors = $buildIssues|where{$_ -like "*: error *"}

    if ($buildWarnings.Count -gt 0)
    {
        Write-Host "    Warnings:`n`r "
        $buildWarnings.ForEach({
            if ($_ -ne [string]::IsNullOrWhiteSpace($_))
            {
                Write-Host "##vso[task.logissue type=warning;]Warning: $_"
            }
        })
        Write-Host " `n`r "
    }

    if ($buildErrors.Count -gt 0)
    {
        Write-Host "    Errors:`n`r "
        $buildErrors.ForEach({
            if ($_ -ne [string]::IsNullOrWhiteSpace($_) -and
                -not ($_ -like "*dotnet-compile.rsp returned Exit Code 1*"))
            {
                Write-Host "##vso[task.logissue type=error;]Error: $_"
            }
        })
        Write-Host "##vso[task.complete result=Failed;]Build Failed!"
        Write-Host "    Build Failed!`n`r "
        Write-Host " "

        exit 1
    }

    Write-Host "    Build done.`n`r "

    foreach($project in $projects)
    {
        $p = "$SourceFolder$($project.Trim('"'))"
        $outDir = (Get-Item $p).Name
        Write-Host "dotnet publish for:"
        Write-Host "    ""$p""`n`r "
        Invoke-Expression "& dotnet publish $p -c $BuildConfiguration -o ""$OutputFolder\$outDir"" --no-build " 2>&1 -ErrorVariable publishIssues | Format-Console

        $publishWarnings = $publishIssues|where{$_ -like "*: warning *"}
        $publishErrors = $publishIssues|where{$_ -like "*: error *"}

        if ($publishWarnings.Count -gt 0)
        {
            Write-Host "    Warnings:`n`r "
            $publishWarnings.ForEach({
                if ($_ -ne [string]::IsNullOrWhiteSpace($_))
                {
                    Write-Host "##vso[task.logissue type=warning;]Warning: $_"
                }
            })
            Write-Host " `n`r "
        }

        if ($publishErrors.Count -gt 0)
        {
            Write-Host "    Errors:`n`r "
            $publishErrors.ForEach({
                if ($_ -ne [string]::IsNullOrWhiteSpace($_))
                {
                    Write-Host "##vso[task.logissue type=error;]Error: $_"
                }
            })
            Write-Host "##vso[task.complete result=Failed;]Publish Failed!"
            Write-Host "    Publish Failed!`n`r "
            Write-Host " "

            exit 1
        }
        Write-Host " `n`r    Publish done for: $p`n`r "
    }
}

Main

Write-Verbose "Leaving script BuildWebPackage.ps1"
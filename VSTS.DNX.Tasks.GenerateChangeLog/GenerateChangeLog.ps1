[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $false)]
    $OutputFile,
    [String] [Parameter(Mandatory = $true)]
    $CreateMdFile,
    [String] [Parameter(Mandatory = $true)]
    $IncludeLinks,
    [String] [Parameter(Mandatory = $true)]
    $AppendMdFile,
    [String] [Parameter(Mandatory = $true)]
    $CreateJsonFile
)

Write-Verbose "Entering script GenerateChangeLog.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

Function Main
{
    if([string]::IsNullOrWhiteSpace($env:SYSTEM_ACCESSTOKEN))
    {
        Write-Error "OAuth token is empty! please check if ""Allow Scripts to Access OAuth Token"" is enabled under ""Options"" in the build definition."
        Exit 1
    }

    [Boolean]$isCreateMdFile = [System.Convert]::ToBoolean($CreateMdFile)
    [Boolean]$isIncludeLinks = [System.Convert]::ToBoolean($IncludeLinks)
    [Boolean]$isAppendMdFile = [System.Convert]::ToBoolean($AppendMdFile)
    [Boolean]$isCreateJsonFile = [System.Convert]::ToBoolean($CreateJsonFile)

    Write-Output "Geting changes ..."

    $BuildId = $env:BUILD_BUILDID
    $BuildDefinitionName = $env:BUILD_DEFINITIONNAME
    $BuildNumber = $env:BUILD_BUILDNUMBER

    $headers = @{Authorization=("Bearer {0}" -f $env:SYSTEM_ACCESSTOKEN)}
    $urlChangeSets = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)/DefaultCollection/$($env:SYSTEM_TEAMPROJECT)/_apis/build/builds/$($buildId)/changes?api-version=2"

    $changes = ""
    Try{
        $changes = Invoke-RestMethod -Method Get -Uri $urlChangeSets -headers $headers -ErrorAction Stop
    }

    Catch{
        Write-Error "REST API return [$($_.Exception.Message)] getting changesets associated to build with id $($buildId)!"
        Exit 1
    }

    if($changes.GetType().Name -ne "PSCustomObject"){
        Write-Error "Response is not an object, maybe the authentication did not work."
        Write-Error $changes
        Exit 1
    }

    Write-Host "    Done."

    if($isCreateMdFile)
    {
        Write-Output "Writing markdown file ..."

        $result = "# Release notes for build **$($buildDefinitionName)**  "
        $result += "`r`n**Build Number** : $($buildNumber)  "
        $result += "`r`n"
        $result += "## Associated changes`r`n"

        $result += Foreach ($change in $changes.value){
            Write-Output "`r`n####"
            if($isIncludeLinks)
            {
                $commit = ""
                Try{
                    $commit = Invoke-RestMethod -Method Get -Uri $change.location -headers $headers -ErrorAction Stop
                }

                Catch{

                }
                if($commit.GetType().Name -eq "PSCustomObject"){
                    Write-Output "[$($commit.commitId.Substring(0,7))]($($commit.remoteUrl))"
                }
            }
            Write-Output "$("{0:dd/MM/yy HH:mm:ss}" -f [datetime]$change.timestamp) - _@$($change.author.displayName)_  "
            Write-Output "`r`n$($change.message)  "
            Write-Output "`r`n"
        }

        $outFileOptions = @{
            FilePath = $OutputFile
            Append = $isAppendMdFile
        }
        $result | Out-File @outFileOptions

        Write-Host "    Done."
    }

    if($isCreateJsonFile)
    {
        Write-Output "Writing json file ..."

        $changes | ConvertTo-Json | Out-File $($OutputFile -replace "\.([^\.]+)$", ".json" )

        Write-Host "    Done."
    }
}

Main

Write-Verbose "Leaving script GenerateChangeLog.ps1"
param(
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    [String] [Parameter(Mandatory = $false)]
    $WebSiteLocation,

    [String] [Parameter(Mandatory = $true)]
    $WebSiteName,
    [String] [Parameter(Mandatory = $false)]
    $SlotName,
    [String] [Parameter(Mandatory = $false)]
    $SourceFolder,
    [String] [Parameter(Mandatory = $true)]
    $StopBeforeDeploy,
    [String] [Parameter(Mandatory = $true)]
    $ForceRestart
)

Write-Verbose "Entering script PublishWebPackage.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

Function Main
{
    Write-Output "Starting publish of $WebsiteName $SlotName"

    $webIdentifier = if ([string]::IsNullOrWhiteSpace($SlotName))
    {
        @{Name = $WebsiteName}
    }
    else
    {
        @{Name = $WebsiteName; Slot = $SlotName}
    }

    $isStopBeforeDeploy = [System.Convert]::ToBoolean($StopBeforeDeploy)
    $isForceRestart = [System.Convert]::ToBoolean($ForceRestart)

    $website = Get-AzureWebsite @webIdentifier -ErrorAction SilentlyContinue 

    # Website not found -> cancel task with error!
    if(!$website)
    {
        Write-Error "Website not found! aborting..."
        return
    }

    # get the scm url to use with MSDeploy.  By default this will be the second in the array
    $msdeployurl = $website.EnabledHostNames -match 'scm.azurewebsites.net'

    $publishProperties = @{
        'WebPublishMethod'         = 'MSDeploy';
        'MSDeployServiceUrl'       = $msdeployurl;
        'DeployIisAppPath'         = $website.Name;
        'EnableMSDeployAppOffline' = $true;
        'SkipExtraFilesOnServer'   = $false;
        'MSDeployUseChecksum'      = $true;
        'Username'                 = $website.PublishingUsername;
        'Password'                 = $website.PublishingPassword
    }

    $publishScript = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\Publish\Scripts\default-publish.ps1"

    if($isStopBeforeDeploy)
    {
        Write-Output "Stop $WebsiteName $SlotName"
        Stop-AzureWebsite @webIdentifier
    }

    & $publishScript -publishProperties $publishProperties -packOutput $SourceFolder

    Write-Output "Finished publishing of $WebsiteName"

    if($isForceRestart)
    {
        Write-Output "Restart $WebsiteName $SlotName"
        Restart-AzureWebsite @webIdentifier
    }
}

Main

Write-Verbose "Leaving script PublishWebPackage.ps1"

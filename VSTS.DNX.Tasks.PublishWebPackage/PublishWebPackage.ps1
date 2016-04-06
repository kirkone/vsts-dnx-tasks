param(
	[string]$WebsiteName,
	[string]$PackOutput,
	[string]$SlotName,
	[switch]$NoStopBeforeDeploy,
	[switch]$NoForceRestart
)

Write-Output "Starting publish of $WebsiteName $SlotName"

$webIdentifier = if ([string]::IsNullOrWhiteSpace($SlotName))
{
	@{Name = $WebsiteName}
}
else
{
	@{Name = $WebsiteName; Slot = $SlotName}
}

$website = Get-AzureWebsite @webIdentifier

# get the scm url to use with MSDeploy.  By default this will be the second in the array
$msdeployurl = $website.EnabledHostNames -match 'scm.azurewebsites.net'

$publishProperties = @{'WebPublishMethod'='MSDeploy';
						'MSDeployServiceUrl'=$msdeployurl;
						'DeployIisAppPath'=$website.Name;
						'EnableMSDeployAppOffline'=$true;
						'SkipExtraFilesOnServer'=$false;
						'MSDeployUseChecksum'=$true;
						'Username'=$website.PublishingUsername;
						'Password'=$website.PublishingPassword}

$publishScript = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\Publish\Scripts\default-publish.ps1"

if(-not $NoStopBeforeDeploy)
{
	Write-Output "Stop $WebsiteName $SlotName"
	Stop-AzureWebsite @webIdentifier
}

& $publishScript -publishProperties $publishProperties -packOutput $PackOutput -verbose

Write-Output "Finished publish of $WebsiteName" -foreground "green"

if(-not $NoForceRestart)
{
	Write-Output "Restart $WebsiteName $SlotName"
	Restart-AzureWebsite @webIdentifier
}
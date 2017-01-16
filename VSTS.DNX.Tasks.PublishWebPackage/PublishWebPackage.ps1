param(
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    [String] [Parameter(Mandatory = $false)]
    $WebSiteLocation,

    [String] [Parameter(Mandatory = $true)]
    $WebSiteName,
    [String] [Parameter(Mandatory = $false)]
    $SlotName,
    [String] [Parameter(Mandatory = $true)]
    $Source,
    [String] [Parameter(Mandatory = $true)]
    $Destination,
    [String] [Parameter(Mandatory = $true)]
    $UseAppOffline,
    [String] [Parameter(Mandatory = $false)]
    $AppOfflineFile,
    [String] [Parameter(Mandatory = $true)]
    $StopBeforeDeploy,
    [String] [Parameter(Mandatory = $true)]
    $CleanBeforeDeploy,
    [String] [Parameter(Mandatory = $true)]
    $ForceRestart
)

Write-Verbose "Entering script PublishWebPackage.ps1"

Write-Host "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ("    $key = $($PSBoundParameters[$key])")
}

Function JoinParts {
    param ([string[]] $Parts, [string] $Separator = '/')

    $search = '(?<!:)' + [regex]::Escape($Separator) + '+'
    ($Parts | Where-Object {$_ -and $_.Trim().Length}) -join $Separator -replace $search, $Separator
}

Function Main
{
    Write-Host "Starting publish of $WebSiteName $SlotName"
    [int]$timeout = 600

    $webIdentifier = if ([string]::IsNullOrWhiteSpace($SlotName))
    {
        @{Name = $WebSiteName}
    }
    else
    {
        @{Name = $WebSiteName; Slot = $SlotName}
    }

    $isUseAppOffline = [System.Convert]::ToBoolean($UseAppOffline)
    $isStopBeforeDeploy = [System.Convert]::ToBoolean($StopBeforeDeploy)
    $isCleanBeforeDeploy = [System.Convert]::ToBoolean($CleanBeforeDeploy)
    $isForceRestart = [System.Convert]::ToBoolean($ForceRestart)

    $Destination = $Destination.Trim().Replace("\\","/").Trim("/")

    $website = Get-AzureWebsite @webIdentifier -ErrorAction SilentlyContinue

    # Website not found -> cancel task with error!
    if(!$website)
    {
        Write-Error "Website not found! aborting...`n`r "
        Write-Host "##vso[task.complete result=Failed;]Website not found!"
        exit 1
    }

    $username = $website.PublishingUsername
    $password = $website.PublishingPassword
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    $authHeader = @{Authorization=("Basic {0}" -f $base64Auth);"If-Match"="*"}

    $baseUri = ($website.SiteProperties.Properties | Where-Object { $_.Name -eq "RepositoryUri" } | Select-Object -First 1).Value
    $apiUserAgent = "powershell/1.0"

    $commandApiUri = JoinParts ($baseUri, "/api/command")
    $vfsApiUri = JoinParts ($baseUri, "/api/vfs", $Destination)
    $deployApiUri = JoinParts ($baseUri, "api/zip/", $Destination)

    $publishZip = $Source
    if(Test-Path $Source -pathtype container)
    {
        Write-Host "Source is no .zip file, create .zip..."
        $publishZip = [System.IO.Path]::Combine($env:TMP, ([System.IO.Path]::GetRandomFileName()))

        if (Test-Path $publishZip)
        {
            Remove-Item $publishZip
        }

        Add-Type -Assembly "System.IO.Compression.FileSystem"
        [System.IO.Compression.ZipFile]::CreateFromDirectory("$Source", "$publishZip")
        Write-Host "    Done."
    }

    if($isUseAppOffline){
        Write-Host "Placing app_offline.htm"
        if([string]::IsNullOrWhiteSpace($AppOfflineFile))
        {
            Write-Host "    No App_Offline.htm specified, using default"
            $AppOfflineFile = "$(Split-Path -parent $PSCommandPath)\app_offline.htm"
        }
        Invoke-RestMethod -Uri "$vfsApiUri/app_offline.htm" -Headers $authHeader -UserAgent $userAgent -Method PUT -InFile $AppOfflineFile -ContentType "multipart/form-data" -TimeoutSec $timeout | Out-Null
        Write-Host "    Done."
    }

    if($isStopBeforeDeploy -and -not $isUseAppOffline)
    {
        Write-Host "Stop $WebSiteName $SlotName"
        Stop-AzureWebsite @webIdentifier
        Write-Host "    Done."
    }

    if($isCleanBeforeDeploy)
    {
        $commandBody = @{
            command = "powershell Remove-Item -recurse .\* -exclude app_offline.htm"
            dir = $Destination.Replace("/","\\")
        }

        Write-Host "Cleaning folder `"$Destination`"..."
        Invoke-RestMethod -Uri $commandApiUri -Headers $authHeader -UserAgent $userAgent -Method POST -ContentType "application/json" -Body (ConvertTo-Json $commandBody) -TimeoutSec $timeout | Out-Null
        Write-Host "    Done."
    }

    Write-Host ("Publishing to URI '{0}'..." -f $deployApiUri)
    Invoke-RestMethod -Uri "$deployApiUri/" -Headers $authHeader -UserAgent $userAgent -Method PUT -InFile $publishZip -ContentType "multipart/form-data" -TimeoutSec $timeout | Out-Null

    Write-Host "    Finished publishing of $WebSiteName"

    if($isForceRestart -and -not $isUseAppOffline)
    {
        Write-Host "Restart $WebSiteName $SlotName"
        Restart-AzureWebsite @webIdentifier
        Write-Host "    Done."
    }

    if($isUseAppOffline){
        Write-Host "Removing app_offline.htm"
        Invoke-RestMethod -Uri "$vfsApiUri/app_offline.htm" -Headers $authHeader -UserAgent $userAgent -Method DELETE -TimeoutSec $timeout | Out-Null
        Write-Host "    Done."

    }
}

Main

Write-Verbose "Leaving script PublishWebPackage.ps1"

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
    $StopBeforeDeploy,
    [String] [Parameter(Mandatory = $true)]
    $CleanBeforeDeploy,
    [String] [Parameter(Mandatory = $true)]
    $ForceRestart
)

Write-Verbose "Entering script PublishWebPackage.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

Function JoinParts {
    param ([string[]] $Parts, [string] $Separator = '/')

    $search = '(?<!:)' + [regex]::Escape($Separator) + '+'
    ($Parts | Where-Object {$_ -and $_.Trim().Length}) -join $Separator -replace $search, $Separator
}

Function Main
{
    Write-Output "Starting publish of $WebSiteName $SlotName"
    [int]$timeout = 600

    $webIdentifier = if ([string]::IsNullOrWhiteSpace($SlotName))
    {
        @{Name = $WebSiteName}
    }
    else
    {
        @{Name = $WebSiteName; Slot = $SlotName}
    }

    $isStopBeforeDeploy = [System.Convert]::ToBoolean($StopBeforeDeploy)
    $isCleanBeforeDeploy = [System.Convert]::ToBoolean($CleanBeforeDeploy)
    $isForceRestart = [System.Convert]::ToBoolean($ForceRestart)

    $Destination = $Destination.Trim().Replace("\\","/").Trim("/")

    $website = Get-AzureWebsite @webIdentifier -ErrorAction SilentlyContinue

    # Website not found -> cancel task with error!
    if(!$website)
    {
        Write-Error "Website not found! aborting..."
        return
    }

    $username = $website.PublishingUsername
    $password = $website.PublishingPassword
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    $authHeader = @{Authorization=("Basic {0}" -f $base64Auth)}

    $baseUri = ($website.SiteProperties.Properties | Where-Object { $_.Name -eq "RepositoryUri" } | Select-Object -First 1).Value

    $publishZip = $Source
    if(Test-Path $Source -pathtype container)
    {
        Write-Output "Source is no .zip file, create .zip..."
        $publishZip += "/publish.zip"
        Compress-Archive -Path "$Source/*" -DestinationPath $publishZip -Force
        Write-Output "    Done."
    }

    if($isStopBeforeDeploy)
    {
        Write-Output "Stop $WebSiteName $SlotName"
        Stop-AzureWebsite @webIdentifier
        Write-Output "    Done."
    }

    if($isCleanBeforeDeploy)
    {
        $commandApiUri = JoinParts ($baseUri, "/api/command")
        $commandBody = @{
            command = "del /f /s /q .\ > nul & for /d %i in (*) do rmdir /s /q `"%i`""
            dir = $Destination.Replace("/","\\")
        }

        Write-Output "Cleaning folder `"$Destination`"..."
        Invoke-RestMethod -Uri $commandApiUri -Headers $authHeader -Method POST -ContentType "application/json" -Body (ConvertTo-Json $commandBody) -TimeoutSec $timeout | Out-Null
        Write-Output "    Done."
    }

    $deployApiUri = JoinParts ($baseUri, "api/zip/", $Destination) '/'
    Write-Output ("Publishing to URI '{0}'..." -f $deployApiUri)
    Invoke-RestMethod -Uri $deployApiUri -Headers $authHeader -Method PUT -InFile $publishZip -ContentType "multipart/form-data" -TimeoutSec $timeout | Out-Null

    Write-Output "    Finished publishing of $WebSiteName"

    if($isForceRestart)
    {
        Write-Output "Restart $WebSiteName $SlotName"
        Restart-AzureWebsite @webIdentifier
        Write-Output "    Done."
    }
}

Main

Write-Verbose "Leaving script PublishWebPackage.ps1"

[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    [String] [Parameter(Mandatory = $true)]
    $WebAppName,
    [String] [Parameter(Mandatory = $false)]
    $DeployToSlotFlag,
    [String] [Parameter(Mandatory = $false)]
    $ResourceGroupName,
    [String] [Parameter(Mandatory = $false)]
    $SlotName,

    [String] [Parameter(Mandatory = $true)]
    $VirtualApplicationName
)

Write-Verbose "Entering script AddVirtualApp.ps1"

Write-Host " "
Write-Host "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ("    $key = $($PSBoundParameters[$key])")
}
Write-Host " "

Function JoinParts {
    param ([string[]] $Parts, [string] $Separator = '/')

    $search = '(?<!:)' + [regex]::Escape($Separator) + '+'
    ($Parts | Where-Object {$_ -and $_.Trim().Length}) -join $Separator -replace $search, $Separator
}

Function Main
{
    $ResourceType = "Microsoft.Web/sites{0}" -f ("/slots","")[[string]::IsNullOrWhiteSpace($SlotName)]
    $ResourceName = "$WebAppName{0}" -f ("/$SlotName","")[[string]::IsNullOrWhiteSpace($SlotName)]

    $newApp = @"
{
    "virtualPath": "/$VirtualApplicationName",
    "physicalPath": "site\\$VirtualApplicationName",
    "preloadEnabled": false,
    "virtualDirectories": null
}
"@ | ConvertFrom-Json

    Write-Host "Adding virtual application..."

    $web = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType/config -ResourceName $ResourceName/web -ApiVersion 2015-08-01

    if(-Not( $web.properties.virtualApplications.virtualPath -contains $newApp.virtualPath) )
    {
        $web.properties.virtualApplications += $newApp | select *
        Set-AzureRmResource -PropertyObject $web.properties -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType/config -ResourceName $ResourceName/web -ApiVersion 2015-08-01 -Force
        Write-Host "    Done."
    }
    else
    {
        Write-Host "    Virtual application allready exists."
    }

    $publishingcredentials = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType/config -ResourceName $ResourceName/publishingcredentials -Action list -ApiVersion 2015-08-01 -Force

    # Website not found -> cancel task with error!
    if(!$publishingcredentials)
    {
        Write-Error "Publishing credentials not found! aborting...`n`r "
        Write-Host "##vso[task.complete result=Failed;]Publishing credentials not found!"
        exit 1
    }

    $username = $publishingcredentials.properties.publishingUserName
    $password = $publishingcredentials.properties.publishingPassword
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    $authHeader = @{Authorization=("Basic {0}" -f $base64Auth);"If-Match"="*"}

    $slot = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType -ResourceName $ResourceName -ApiVersion 2015-08-01

    $baseUri = ($slot.properties.EnabledHostNames | Where-Object { $_ -like "*.scm.*"} | Select-Object -First 1)
    $apiUserAgent = "powershell/1.0"

    $vfsApiUri = JoinParts ("https://", $baseUri, "/api/vfs/site", $VirtualApplicationName, "/")

    Write-Host " "
    Write-Host "Checking folder for virtual application..."
    try
    {
        Invoke-RestMethod -Uri $vfsApiUri -Headers $authHeader -UserAgent $userAgent -Method GET | Out-Null
    }
    catch
    {
        if($_.Exception.Response.StatusCode -eq "NotFound")
        {
            Write-Host "    Folder does not exist, creating..."
            try
            {
                Invoke-RestMethod -Uri $vfsApiUri -Headers $authHeader -UserAgent $userAgent -Method PUT | Out-Null
            }
            catch
            {
                Write-Host ($_.Exception.Response | Format-List | Out-String)
            }
        }
        else
        {
            Write-Host ($_.Exception.Response| Format-List | Out-String)
            Write-Error "Can not create Folder $VirtualApplicationName! aborting...`n`r "
            Write-Host "##vso[task.complete result=Failed;]Can not create Folder $VirtualApplicationName!"
            exit 1
        }
    }
    
    Write-Host "    Done."
}

Main

Write-Verbose "Leaving script BuildWebPackage.ps1"
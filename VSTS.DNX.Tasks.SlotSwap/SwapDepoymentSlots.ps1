[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,

    [String] [Parameter(Mandatory = $true)]
    $WebSiteName,
    [String] [Parameter(Mandatory = $true)]
    $From,
    [String] [Parameter(Mandatory = $true)]
    $To
)

Write-Verbose "Entering script SwapDeploymentSlots.ps1"

Write-Output "WebSiteName: $WebSiteName"
Write-Output "From: $From"
Write-Output "To: $To"


. Switch-AzureWebsiteSlot -Name $WebSiteName -Slot1 $From -Slot2 $To -Force -Verbose

Write-Verbose "Leaving script SwapDeploymentSlots.ps1"
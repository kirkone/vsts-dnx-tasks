[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    [String] [Parameter(Mandatory = $false)]
    $WebSiteLocation,

    [String] [Parameter(Mandatory = $true)]
    $WebSiteName,
    [String] [Parameter(Mandatory = $true)]
    $From,
    [String] [Parameter(Mandatory = $true)]
    $To
)

Write-Verbose "Entering script SwapDeploymentSlots.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

. Switch-AzureWebsiteSlot -Name $WebSiteName -Slot1 $From -Slot2 $To -Force -Verbose

Write-Verbose "Leaving script SwapDeploymentSlots.ps1"
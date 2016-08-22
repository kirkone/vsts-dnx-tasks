[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [String] [Parameter(Mandatory = $false)]
    $NugetPath
)

Write-Verbose "Entering script ClearNugetCache.ps1"

Write-Output "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Output ("    $key = $($PSBoundParameters[$key])")
}

$usedNugetPath = ""

Write-Output "Deleting Cache..."

if(!([string]::IsNullOrWhitespace("$NugetPath")) -and (Test-Path "$NugetPath"))
{
    $usedNugetPath = "$NugetPath"
}
elseif( !([string]::IsNullOrWhitespace("$env:NUGET_PACKAGES")) -and (Test-Path "$env:NUGET_PACKAGES") )
{
    $usedNugetPath = "$env:NUGET_PACKAGES"
}
elseif( !([string]::IsNullOrWhitespace("$env:USERPROFILE\.nuget\packages")) -and (Test-Path "$env:USERPROFILE\.nuget\packages") )
{
    $usedNugetPath = "$env:USERPROFILE\.nuget\packages"
}
else
{
    Write-Error "No NuGet Cache folder found!"
    return
}

Write-Output "        Nuget cache folder:"
Write-Output "            $usedNugetPath"
Write-Output "        Items to remove: $(( Get-ChildItem "$usedNugetPath" ).Count)"


Remove-Item -Recurse -Force "$usedNugetPath"
mkdir $usedNugetPath | Out-Null

Write-Output "    Done"

Write-Verbose "Leaving script ClearNugetCache.ps1"
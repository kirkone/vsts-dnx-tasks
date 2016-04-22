function Install-Dnvm
{
    param (
        [bool] [Parameter(Mandatory = $false)]
        $SpecificRuntime = $false,
        [bool] [Parameter(Mandatory = $false)]
        $UnstableRuntime = $false
    )

    Write-Verbose "Entering Method Install-Dnvm"

    $dnvm = Get-Command "dnvm" -ErrorAction SilentlyContinue
    $dnvmPath = ".\Tools\dnvm.ps1"

    if ($dnvm -ne $null)
    {
        Write-Output "DNVM found:"
        Write-Output "    $($dnvm.Path)"
        $dnvmPath = $dnvm.Path
    }
    else
    {
        Write-Output "DNVM not found, instlling..."

        $dnvmPs1Path = "$PSScriptRoot\Tools"
        if (-not (Test-Path -PathType Container $dnvmPs1Path))
        {
            New-Item -ItemType Directory -Path $dnvmPs1Path
        }

        $dnvmPs1Path = "$dnvmPs1Path\dnvm.ps1"

        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
        $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        Write-Output "Downloading DNVM.ps1 to $dnvmPs1Path"
        $webClient.DownloadFile("https://raw.githubusercontent.com/aspnet/Home/dev/dnvm.ps1", $dnvmPs1Path)

        $dnvmPath = $dnvmPs1Path
    }

    $globalJson = Get-Content -Path .\global.json -Raw -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore

    if($globalJson)
    {
        Write-Output "Take DNX version from global.json."
        $dnxVersion = $globalJson.sdk.version
        $dnxParams = ""
        if($SpecificRuntime)
        {
            $dnxRuntime = $globalJson.sdk.runtime
            $dnxArch = $globalJson.sdk.architecture
            $dnxParams = "-r $dnxRuntime -a $dnxArch"
        }
    }
    else
    {
        Write-Output "Unable to locate global.json to determine using 'latest'"
        $dnxVersion = "latest"
    }

    $dnxUnstable = &{If($UnstableRuntime){"-u"}}

    Write-Output "Calling: $dnvmPath install $dnxParams $dnxVersion -Persistent"
    & $dnvmPath install $dnxParams "$dnxVersion" -Persistent $dnxUnstable

    Write-Verbose "Leaving script Install-Dnvm"
}
function Install-Dotnet
{
    param (
    )

    Write-Verbose "Entering Method Install-Dotnet"

    $dotnet = Get-Command "dotnet" -ErrorAction SilentlyContinue
    $dotnetPath = ""

    if ($dotnet -ne $null)
    {
        Write-Output "Dotnet found:"
        Write-Output "    $($dotnet.Path)"
        $dotnetPath = $dotnet.Path
    }
    else
    {
        Write-Output "Dotnet not found, installing..."

        $dotnetPs1Path = "$PSScriptRoot\Tools"
        if (-not (Test-Path -PathType Container $dotnetPs1Path))
        {
            New-Item -ItemType Directory -Path $dotnetPs1Path
        }

        $dotnetPs1Path = "$dotnetPs1Path\dotnet-install.ps1"

        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
        $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        Write-Output "Downloading dotnet-install.ps1 to $dotnetPs1Path"
        $webClient.DownloadFile("https://raw.githubusercontent.com/dotnet/cli/rel/1.0.0/scripts/obtain/dotnet-install.ps1", $dotnetPs1Path)

        $dotnetPath = $dotnetPs1Path

        Write-Output "Calling: $dotnetPath"
        & "$dotnetPath"
    }

    Write-Verbose "Leaving Method Install-Dotnet"
}

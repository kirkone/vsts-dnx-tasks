function Trim-Path
{
    param (
    [String] [Parameter(Mandatory = $true)]
    $Path = ""
)

    Write-Verbose "Entering Method Trim-Path"

    $Path = $Path.Trim().Trim("""").Trim().Replace("/","\\").Trim("\")
    if($Path -ne "")
    {
        $Path = ".\" + $Path + "\"
    }
    else
    {
        $Path = ".\"
    }

    Write-Verbose "Leaving script Trim-Path"

    return $Path
}
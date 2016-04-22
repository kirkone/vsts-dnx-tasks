function Get-TrimedPath
{
    param (
    [String] [Parameter(Mandatory = $true)]
    $Path = ""
)

    Write-Verbose "Entering Method Get-TrimedPath"

    $Path = $Path.Trim().Trim("""").Trim().Replace("/","\\").Trim("\")
    if($Path -ne "")
    {
        $Path = ".\" + $Path + "\"
    }
    else
    {
        $Path = ".\"
    }

    Write-Verbose "Leaving script Get-TrimedPath"

    return $Path
}
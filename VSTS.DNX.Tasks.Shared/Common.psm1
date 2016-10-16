function Get-TrimedPath
{
    param (
    [String] [Parameter(Mandatory = $false)]
    $Path = ""
)

    Write-Verbose "Entering Method Get-TrimedPath"

    $Path = $Path.Trim().Trim("""").Trim().Replace("/","\\").Trim("\")
    if($Path -ne "")
    {
        if(-not [System.IO.Path]::IsPathRooted($Path))
        {
            $Path = ".\" + $Path + "\"
        }
        else
        {
            $Path = $Path + "\"
        }
    }
    else
    {
        $Path = ".\"
    }

    Write-Verbose "Leaving script Get-TrimedPath"

    return $Path
}
Function Test-ValidWin32DevicePath
{
    Param
    (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String] $Path
    )

    return $Path -match "\\\\\.\\[^$]"
}

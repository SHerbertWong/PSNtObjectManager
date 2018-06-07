Function ConvertTo-NtNamespacePath
{
    Param
    (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String] $Win32DevicePath
    )

    if (-not (Test-ValidWin32DevicePath -Path $Win32DevicePath))
    {
        throw "`"$Win32DevicePath`" is not valid Win32-namespace device path"
    }

    return $Win32DevicePath -replace "^\\\\\.\\","\GLOBAL??\"
}

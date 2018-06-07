Function Get-NtSymbolicLinkObjectTargetName
{
    Param
    (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String] $LinkName
    )

    if (-not (Test-ValidNtNamespacePath -Path $LinkName))
    {
        $LinkName = ConvertTo-NtNamespacePath -Win32DevicePath $LinkName
    }

    $ObjectAttributesObject = New-Object -TypeName OBJECT_ATTRIBUTES -ArgumentList $LinkName, 0
    $LinkHandle = $NULL

    [NtStatus] $NtStatus = [PInvoke.WinNT.Userspace.NtSymbolicLinkObject]::NtOpenSymbolicLinkObject([ref] $LinkHandle, [ACCESS_MASK]::GENERIC_READ, [ref] $ObjectAttributesObject)
    if ($NtStatus -ne [NtStatus]::SuccessOrWait0)
    {
        throw "NtOpenSymbolicLinkObject failed: $NtStatus"
    }

    $LinkTargetNameStruct = [UNICODE_STRING] ([UInt16] [UNICODE_STRING]::MaximumCharLimit)
    $ReturnedLength = $NULL
    [NtStatus] $NtStatus = [PInvoke.WinNT.Userspace.NtSymbolicLinkObject]::NtQuerySymbolicLinkObject($LinkHandle, [ref] $LinkTargetNameStruct, [ref] $ReturnedLength)
    if ($NtStatus -ne [NtStatus]::SuccessOrWait0)
    {
        throw "NtQuerySymbolicLinkObject failed: $NtStatus"
    }

    return $LinkTargetNameStruct.ToString()
}

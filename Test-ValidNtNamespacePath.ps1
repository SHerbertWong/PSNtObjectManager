Function Test-ValidNtNamespacePath
{
    Param
    (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String] $Path
    )

    return $Path -match "^\\(?:[^\\]|$)"
}

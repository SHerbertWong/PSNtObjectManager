#REQUIRES -version 2.0

if ($__Module__PSNtObjectManager) {exit}

Import-Module "$PSScriptRoot\..\PSNtStatus"

# For pinvoke references, see:
# - ACCESS_MASK: https://www.pinvoke.net/default.aspx/Enums.ACCESS_MASK
# - UNICODE_STRING: https://www.pinvoke.net/default.aspx/Structures.UNICODE_STRING
# - OBJECT_ATTRIBUTES: https://www.pinvoke.net/default.aspx/Structures/OBJECT_ATTRIBUTES.html
# - NtOpenSymbolicLinkObject(): https://www.pinvoke.net/default.aspx/ntdll.ntopensymboliclinkobject
# - NtQuerySymbolicLinkObject(): https://www.pinvoke.net/default.aspx/ntdll.ntquerysymboliclinkobject
# For NT API references, see:
# - ACCESS_MASK: https://msdn.microsoft.com/en-us/library/aa374892(v=vs.85).aspx
# - UNICODE_STRING: https://msdn.microsoft.com/en-us/library/windows/desktop/aa380518(v=vs.85).aspx
# - OBJECT_ATTRIBUTES: https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/content/wudfwdm/ns-wudfwdm-_object_attributes
# - NtOpenSymbolicLinkObject(): https://msdn.microsoft.com/en-us/library/bb470236(v=vs.85).aspx
# - NtQuerySymbolicLinkObject(): https://msdn.microsoft.com/en-us/library/bb470238(v=vs.85).aspx
# For documentations on NT/Win32 namespaces, see:
# - "Naming Files, Paths, and Namespaces": https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx

Add-Type -TypeDefinition `
@"
using Microsoft.Win32.SafeHandles;
using System;
using System.Runtime.InteropServices;

[Flags]
public enum ACCESS_MASK : uint
{
	DELETE = 0x00010000,
	READ_CONTROL = 0x00020000,
	WRITE_DAC = 0x00040000,
	WRITE_OWNER = 0x00080000,
	SYNCHRONIZE = 0x00100000,

	STANDARD_RIGHTS_REQUIRED = 0x000F0000,

	STANDARD_RIGHTS_READ = 0x00020000,
	STANDARD_RIGHTS_WRITE = 0x00020000,
	STANDARD_RIGHTS_EXECUTE = 0x00020000,

	STANDARD_RIGHTS_ALL = 0x001F0000,

	SPECIFIC_RIGHTS_ALL = 0x0000FFFF,

	ACCESS_SYSTEM_SECURITY = 0x01000000,

	MAXIMUM_ALLOWED = 0x02000000,

	GENERIC_READ = 0x80000000,
	GENERIC_WRITE = 0x40000000,
	GENERIC_EXECUTE = 0x20000000,
	GENERIC_ALL = 0x10000000,

	DESKTOP_READOBJECTS = 0x00000001,
	DESKTOP_CREATEWINDOW = 0x00000002,
	DESKTOP_CREATEMENU = 0x00000004,
	DESKTOP_HOOKCONTROL = 0x00000008,
	DESKTOP_JOURNALRECORD = 0x00000010,
	DESKTOP_JOURNALPLAYBACK = 0x00000020,
	DESKTOP_ENUMERATE = 0x00000040,
	DESKTOP_WRITEOBJECTS = 0x00000080,
	DESKTOP_SWITCHDESKTOP = 0x00000100,

	WINSTA_ENUMDESKTOPS = 0x00000001,
	WINSTA_READATTRIBUTES = 0x00000002,
	WINSTA_ACCESSCLIPBOARD = 0x00000004,
	WINSTA_CREATEDESKTOP = 0x00000008,
	WINSTA_WRITEATTRIBUTES = 0x00000010,
	WINSTA_ACCESSGLOBALATOMS = 0x00000020,
	WINSTA_EXITWINDOWS = 0x00000040,
	WINSTA_ENUMERATE = 0x00000100,
	WINSTA_READSCREEN = 0x00000200,

	WINSTA_ALL_ACCESS = 0x0000037F
}

[StructLayout(LayoutKind.Sequential)]
public struct UNICODE_STRING : IDisposable
{
	public static int MaximumCharLimit = 32766;

	public ushort Length;
	public ushort MaximumLength;
	private IntPtr buffer;

	public UNICODE_STRING(ushort length) : this(new string('x', length)) {}

	public UNICODE_STRING(string s)
	{
		if (s.Length > MaximumCharLimit)
		{
			throw new ArgumentOutOfRangeException("s exceeds the character limit of " + MaximumCharLimit);
		}

		Length = (ushort)(s.Length * 2);
		MaximumLength = (ushort)(Length + 2);
		buffer = Marshal.StringToHGlobalUni(s);
	}

	public void Dispose()
	{
		Marshal.FreeHGlobal(buffer);
		buffer = IntPtr.Zero;
	}

	public override string ToString()
	{
		return Marshal.PtrToStringUni(buffer);
	}
}

[StructLayout(LayoutKind.Sequential)]
public struct OBJECT_ATTRIBUTES : IDisposable
{
	public int Length;
	public IntPtr RootDirectory;
	private IntPtr objectName;
	public uint Attributes;
	public IntPtr SecurityDescriptor;
	public IntPtr SecurityQualityOfService;

	public OBJECT_ATTRIBUTES(string name, uint attrs)
	{
		Length = 0;
		RootDirectory = IntPtr.Zero;
		objectName = IntPtr.Zero;
		Attributes = attrs;
		SecurityDescriptor = IntPtr.Zero;
		SecurityQualityOfService = IntPtr.Zero;

		Length = Marshal.SizeOf(this);
		ObjectName = new UNICODE_STRING(name);
	}

	public UNICODE_STRING ObjectName
	{
		get
		{
			return (UNICODE_STRING)Marshal.PtrToStructure(
			objectName, typeof(UNICODE_STRING));
		}

		set
		{
			bool fDeleteOld = objectName != IntPtr.Zero;
			if (!fDeleteOld)
			objectName = Marshal.AllocHGlobal(Marshal.SizeOf(value));
			Marshal.StructureToPtr(value, objectName, fDeleteOld);
		}
	}

	public void Dispose()
	{
		if (objectName != IntPtr.Zero)
		{
			Marshal.DestroyStructure(objectName, typeof(UNICODE_STRING));
			Marshal.FreeHGlobal(objectName);
			objectName = IntPtr.Zero;
		}
	}
}

namespace System.PInvoke.WinNT.Userspace
{
	public class NtSymbolicLinkObject
	{
		[DllImport("ntdll.dll")]
		public static extern int NtQuerySymbolicLinkObject
		(
			SafeFileHandle LinkHandle,
			ref UNICODE_STRING LinkTarget,
			out int ReturnedLength
		);
		
		[DllImport("ntdll.dll")]
		public static extern int NtOpenSymbolicLinkObject
		(
			out SafeFileHandle LinkHandle,
			uint DesiredAccess,
			ref OBJECT_ATTRIBUTES ObjectAttributes
		);
	}
}
"@

Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object {. $_.FullName}
New-Variable -Name '__Module__PSNtObjectManager' -Value $TRUE -Option Constant -Scope Global -Force

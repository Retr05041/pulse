# Credentials.psm1
#
# Windows Credential Manager integration for Pulse.
#
# Stores SpaceTraders agent tokens as Windows Generic Credentials.
#
# Windows only.

Set-StrictMode -Version Latest

$script:CredentialPrefix = "Pulse.SpaceTraders."

# ---------------------------------------------------------------------------
# Windows Credential Manager native implementation
# ---------------------------------------------------------------------------

$nativeTypeName = "Pulse.CredentialManager"

$script:CredentialManagerType = $null

# Look for an already-loaded version of our type.
foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
    $existingType = $assembly.GetType(
        $nativeTypeName,
        $false
    )

    if ($null -ne $existingType) {
        $script:CredentialManagerType = $existingType
        break
    }
}

# Only compile the type if it isn't already loaded.
if ($null -eq $script:CredentialManagerType) {

    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace Pulse
{
    public static class CredentialManager
    {
        private const uint CRED_TYPE_GENERIC = 1;

        private const uint CRED_PERSIST_LOCAL_MACHINE = 2;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct CREDENTIAL
        {
            public uint Flags;
            public uint Type;

            public IntPtr TargetName;
            public IntPtr Comment;

            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;

            public uint CredentialBlobSize;
            public IntPtr CredentialBlob;

            public uint Persist;

            public uint AttributeCount;
            public IntPtr Attributes;

            public IntPtr TargetAlias;
            public IntPtr UserName;
        }

        [DllImport(
            "advapi32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true
        )]
        private static extern bool CredWrite(
            ref CREDENTIAL Credential,
            uint Flags
        );

        [DllImport(
            "advapi32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true
        )]
        private static extern bool CredRead(
            string TargetName,
            uint Type,
            uint Flags,
            out IntPtr Credential
        );

        [DllImport(
            "advapi32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true
        )]
        private static extern bool CredDelete(
            string TargetName,
            uint Type,
            uint Flags
        );

        [DllImport(
            "advapi32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true
        )]
        private static extern bool CredEnumerate(
            string Filter,
            uint Flags,
            out uint Count,
            out IntPtr Credentials
        );

        [DllImport(
            "advapi32.dll",
            SetLastError = true
        )]
        private static extern void CredFree(
            IntPtr Buffer
        );

        public static void Save(
            string targetName,
            string userName,
            string secret
        )
        {
            if (string.IsNullOrWhiteSpace(targetName))
                throw new ArgumentException("Target name is required.");

            if (string.IsNullOrWhiteSpace(secret))
                throw new ArgumentException("Secret is required.");

            byte[] secretBytes =
                Encoding.UTF8.GetBytes(secret);

            IntPtr targetPointer = IntPtr.Zero;
            IntPtr userNamePointer = IntPtr.Zero;
            IntPtr blobPointer = IntPtr.Zero;

            try
            {
                targetPointer =
                    Marshal.StringToHGlobalUni(targetName);

                userNamePointer =
                    Marshal.StringToHGlobalUni(userName);

                blobPointer =
                    Marshal.AllocHGlobal(secretBytes.Length);

                Marshal.Copy(
                    secretBytes,
                    0,
                    blobPointer,
                    secretBytes.Length
                );

                CREDENTIAL credential = new CREDENTIAL();

                credential.Flags = 0;
                credential.Type = CRED_TYPE_GENERIC;
                credential.TargetName = targetPointer;
                credential.Comment = IntPtr.Zero;
                credential.CredentialBlobSize =
                    (uint)secretBytes.Length;
                credential.CredentialBlob = blobPointer;
                credential.Persist =
                    CRED_PERSIST_LOCAL_MACHINE;
                credential.AttributeCount = 0;
                credential.Attributes = IntPtr.Zero;
                credential.TargetAlias = IntPtr.Zero;
                credential.UserName = userNamePointer;

                if (!CredWrite(ref credential, 0))
                {
                    throw new InvalidOperationException(
                        "CredWrite failed. Windows error code: " +
                        Marshal.GetLastWin32Error()
                    );
                }
            }
            finally
            {
                if (targetPointer != IntPtr.Zero)
                    Marshal.FreeHGlobal(targetPointer);

                if (userNamePointer != IntPtr.Zero)
                    Marshal.FreeHGlobal(userNamePointer);

                if (blobPointer != IntPtr.Zero)
                    Marshal.FreeHGlobal(blobPointer);

                Array.Clear(
                    secretBytes,
                    0,
                    secretBytes.Length
                );
            }
        }

        public static string Read(
            string targetName
        )
        {
            IntPtr credentialPointer = IntPtr.Zero;

            if (!CredRead(
                targetName,
                CRED_TYPE_GENERIC,
                0,
                out credentialPointer
            ))
            {
                int errorCode =
                    Marshal.GetLastWin32Error();

                // ERROR_NOT_FOUND
                if (errorCode == 1168)
                    return null;

                throw new InvalidOperationException(
                    "CredRead failed. Windows error code: " +
                    errorCode
                );
            }

            try
            {
                CREDENTIAL credential =
                    (CREDENTIAL)Marshal.PtrToStructure(
                        credentialPointer,
                        typeof(CREDENTIAL)
                    );

                if (credential.CredentialBlobSize == 0)
                    return null;

                byte[] secretBytes =
                    new byte[credential.CredentialBlobSize];

                Marshal.Copy(
                    credential.CredentialBlob,
                    secretBytes,
                    0,
                    (int)credential.CredentialBlobSize
                );

                try
                {
                    return Encoding.UTF8.GetString(
                        secretBytes
                    );
                }
                finally
                {
                    Array.Clear(
                        secretBytes,
                        0,
                        secretBytes.Length
                    );
                }
            }
            finally
            {
                CredFree(credentialPointer);
            }
        }

        public static bool Delete(
            string targetName
        )
        {
            if (CredDelete(
                targetName,
                CRED_TYPE_GENERIC,
                0
            ))
            {
                return true;
            }

            int errorCode =
                Marshal.GetLastWin32Error();

            // ERROR_NOT_FOUND
            if (errorCode == 1168)
                return false;

            throw new InvalidOperationException(
                "CredDelete failed. Windows error code: " +
                errorCode
            );
        }

        public static string[] Enumerate(
            string prefix
        )
        {
            IntPtr credentialsPointer = IntPtr.Zero;
            uint count = 0;

            if (!CredEnumerate(
                null,
                0,
                out count,
                out credentialsPointer
            ))
            {
                int errorCode =
                    Marshal.GetLastWin32Error();

                // No credentials exist.
                if (errorCode == 1168)
                    return new string[0];

                throw new InvalidOperationException(
                    "CredEnumerate failed. Windows error code: " +
                    errorCode
                );
            }

            try
            {
                List<string> results =
                    new List<string>();

                int pointerSize =
                    IntPtr.Size;

                for (
                    int i = 0;
                    i < count;
                    i++
                )
                {
                    IntPtr credentialPointer =
                        Marshal.ReadIntPtr(
                            credentialsPointer,
                            i * pointerSize
                        );

                    if (
                        credentialPointer ==
                        IntPtr.Zero
                    )
                    {
                        continue;
                    }

                    CREDENTIAL credential =
                        (CREDENTIAL)Marshal.PtrToStructure(
                            credentialPointer,
                            typeof(CREDENTIAL)
                        );

                    if (
                        credential.TargetName ==
                        IntPtr.Zero
                    )
                    {
                        continue;
                    }

                    string targetName =
                        Marshal.PtrToStringUni(
                            credential.TargetName
                        );

                    if (
                        targetName != null &&
                        targetName.StartsWith(
                            prefix,
                            StringComparison.Ordinal
                        )
                    )
                    {
                        results.Add(
                            targetName.Substring(
                                prefix.Length
                            )
                        );
                    }
                }

                return results.ToArray();
            }
            finally
            {
                CredFree(credentialsPointer);
            }
        }
    }
}
'@ -ErrorAction Stop

    # Retrieve the newly-created type.
    foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
        $existingType = $assembly.GetType(
            $nativeTypeName,
            $false
        )

        if ($null -ne $existingType) {
            $script:CredentialManagerType = $existingType
            break
        }
    }
}

if ($null -eq $script:CredentialManagerType) {
    throw "Unable to load Pulse.CredentialManager."
}

# ---------------------------------------------------------------------------
# Save-AgentToken
# ---------------------------------------------------------------------------

function Save-AgentToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentSymbol,

        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    if ([string]::IsNullOrWhiteSpace($AgentSymbol)) {
        throw "Agent symbol is required."
    }

    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw "Token is required."
    }

    $targetName =
        "$($script:CredentialPrefix)$AgentSymbol"

    $saveMethod =
        $script:CredentialManagerType.GetMethod("Save")

    $saveMethod.Invoke(
        $null,
        @(
            $targetName,
            $AgentSymbol,
            $Token
        )
    ) | Out-Null
}

# ---------------------------------------------------------------------------
# Get-AgentToken
# ---------------------------------------------------------------------------

function Get-AgentToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentSymbol
    )

    if ([string]::IsNullOrWhiteSpace($AgentSymbol)) {
        return $null
    }

    $targetName =
        "$($script:CredentialPrefix)$AgentSymbol"

    $readMethod =
        $script:CredentialManagerType.GetMethod("Read")

    return $readMethod.Invoke(
        $null,
        @($targetName)
    )
}

# ---------------------------------------------------------------------------
# Get-SavedAgentSymbols
# ---------------------------------------------------------------------------

function Get-SavedAgentSymbols {

    $enumerateMethod =
        $script:CredentialManagerType.GetMethod("Enumerate")

    $results =
        $enumerateMethod.Invoke(
            $null,
            @($script:CredentialPrefix)
        )

    foreach ($symbol in $results) {
        $symbol
    }
}

# ---------------------------------------------------------------------------
# Remove-AgentToken
# ---------------------------------------------------------------------------

function Remove-AgentToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentSymbol
    )

    if ([string]::IsNullOrWhiteSpace($AgentSymbol)) {
        return
    }

    $targetName =
        "$($script:CredentialPrefix)$AgentSymbol"

    $deleteMethod =
        $script:CredentialManagerType.GetMethod("Delete")

    $deleteMethod.Invoke(
        $null,
        @($targetName)
    ) | Out-Null
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

Export-ModuleMember -Function `
    Save-AgentToken, `
    Get-AgentToken, `
    Get-SavedAgentSymbols, `
    Remove-AgentToken
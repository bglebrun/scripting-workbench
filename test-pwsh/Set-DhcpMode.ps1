[CmdletBinding()]
param (
[ValidateSet('on', 'off', ignorecase = $True)]
[parameter(Position=0)]
[string]$EndpointMode
)

Process {

    $allAdapters = Get-NetAdapter -Physical

    $wirelessAdapter = $allAdapters |
    Where-Object { $_.status -ne "Not Present" -and $_.Name -ne "Ethernet" } |
    Select-Object -ExpandProperty Name

    function Set-DhcpStatus {
        param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('Enabled', 'Disabled')]
            [string]$EnableDhcp
        )

        foreach ($adapter in $allAdapters) {
                # Enable DHCP
                Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -Dhcp Enabled-Macro($EnableDhcp)
        }
    }

    # Example usage:
    # To enable DHCP
    Set-DhcpStatus -EnableDhcp $true

    # To disable DHCP
    Set-DhcpStatus -EnableDhcp $false

    function Release-IPAddresses {
        foreach ($adapter in $allAdapters) {
            # Release the IP address
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress 0.0.0.0 -PrefixLength 0
        }
    }
}

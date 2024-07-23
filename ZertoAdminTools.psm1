# Required Modules Test
Import-Module -Name ZertoApiWrapper -RequiredVersion 2.0.0
Import-Module -Name CredentialManager

<#
 .Synopsis
  Displays a list of datastore usage on a particular site or for a specific customer on that site.

.Description
  Displays a list of datastore usage. This function can show data for all the Zerto datastores on a site or filter them by customer Zorg.

.Parameter ZVM
  The IP address or FQDN of the Zerto Virtual Manager.

.Parameter Credential
  Input a stored credential or get prompted to enter credentials.

.Parameter Zorg
  The Zorg of the customer to check datastore usage for.

.Example
   # Get datastore usage for an entire site.
   Get-ZertoDatastoreUsage -ZVM 1.2.3.4 -Credential $MyCreds

.Example
   # Get datastore usage for a specific customer.
   Get-ZertoDatastoreUsage -ZVM 1.2.3.4 -Credential $MyCreds -Zorg CustomerZorg

#>
function Get-ZertoDatastoreUsage {
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$ZVM,
        [Parameter(Mandatory, Position=1)]
        [pscredential]$Credential,
        [Parameter(Position=2)]
        [string]$Zorg
    )

    Connect-ZertoServer -zertoServer $ZVM -credential $Credential -AutoReconnect

    $ZertoDatastores = Get-ZertoDatastore
    $ZertoVRAs = Get-ZertoVra

    $ResourceReportStartTime = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-1).ToString('yyyy-MM-ddTHH:mm:ss')
    $ResourceReportEndTime = (Get-Date -Hour 0 -Minute 0 -Second 0).ToString('yyyy-MM-ddTHH:mm:ss')

    if ($PSBoundParameters.ContainsKey('Zorg')) {
        $CustomerResourceReport = Get-ZertoResourcesReport -zorgName $Zorg -startTime $ResourceReportStartTime -endTime $ResourceReportEndTime
    } else {
        $CustomerResourceReport = Get-ZertoResourcesReport -startTime $ResourceReportStartTime -endTime $ResourceReportEndTime
    }

    $CustomerDatastoreNames = ($CustomerResourceReport | Select-Object -ExpandProperty RecoverySite | Select-Object -ExpandProperty Storage | Select-Object -ExpandProperty DatastoreName).Split(',') | Sort-Object -Unique

    $CustomerDatastores = foreach ($Name in $CustomerDatastoreNames) {
        $ZertoDatastores | Where-Object { $_.datastorename -eq $Name }
    }

    $CustomerDatastores = $CustomerDatastores | Select-Object datastorename,
        @{n='used'; e={$_.stats.usage.datastore.usedinbytes}},
        @{n='capacity'; e={$_.stats.usage.datastore.capacityinbytes}},
        @{n='percent'; e={[math]::Round($_.stats.usage.datastore.usedinbytes / $_.stats.usage.datastore.capacityinbytes * 100)}}

    $CustomerVRAsNames = ($CustomerResourceReport | Select-Object -ExpandProperty RecoverySite | Select-Object -ExpandProperty Compute | Select-Object -ExpandProperty VraName) | Sort-Object -Unique

    $CustomerVRAs = foreach ($VRAName in $CustomerVRAsNames) {
        $ZertoVRAs | Where-Object { $_.VRAName -eq $VRAName }
    }

    $CustomerVRAs = $CustomerVRAs | Select-Object VraName, @{n='VMs'; e={@($_.RecoveryCounters.Vms)}}, @{n='VPGs'; e={@($_.RecoveryCounters.Vpgs)}},@{n='Volumes'; e={@($_.RecoveryCounters.Volumes)}}

    Disconnect-ZertoServer -ErrorAction SilentlyContinue

    return [PSCustomObject]@{
        Datastores = $CustomerDatastores
        VRAs       = $CustomerVRAs
    }
}
Export-ModuleMember -Function Get-ZertoDatastoreUsage
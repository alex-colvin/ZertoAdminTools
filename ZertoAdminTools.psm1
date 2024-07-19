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
Function Get-ZertoDatastoreUsage
{
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZVM,
        [Parameter(Mandatory,Position=1)]
        [string]$Credential,
        [Parameter(Position=2)]
        [string]$Zorg
    )
    Connect-ZertoServer -zertoServer $ZVM -credential $Credential -AutoReconnect
    $ZertoDatastores = Get-ZertoDatastore
    $ZertoVRAs = Get-ZertoVra
    $ResourceReportStartTime = (Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(-1) | Get-Date -Format yyyy-MM-ddTHH:mm:ss
    $ResourceReportEndTime = Get-Date -Hour 0 -Minute 00 -Second 00 -Format yyyy-MM-ddTHH:mm:ss
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'Zorg')))
    {
        $CustomerResourceReport = Get-ZertoResourcesReport -zorgName $Zorg -startTime $ResourceReportStartTime -endTime $ResourceReportEndTime
        } else {
        $CustomerResourceReport = Get-ZertoResourcesReport -startTime $ResourceReportStartTime -endTime $ResourceReportEndTime
    }
    $CustomerDatastoreNamesRaw = $CustomerResourceReport | Select-Object @{n='DatastoreName';e={$_.RecoverySite.Storage.DatastoreName}}
    $CustomerDatastoreNames = $CustomerDatastoreNamesRaw.datastorename -split "," | Sort-Object | Get-Unique
    $CustomerDatastores = foreach ($Name in $CustomerDatastoreNames){$ZertoDatastores | where datastorename -eq $Name}
    $CustomerDatastores | select-object datastorename,@{n='used';e={$_.stats.usage.datastore.usedinbytes}},@{n='capacity';e={$_.stats.usage.datastore.capacityinbytes}},@{n='percent';e={[math]::Round($_.stats.usage.datastore.usedinbytes/$_.stats.usage.datastore.capacityinbytes*100)}}
    $CustomerVRAsNamesRaw = $CustomerResourceReport | Select-Object @{n='VRAName';e={$_.RecoverySite.Compute.VraName}}
    $CustomerVRAsNames = $CustomerVRAsNamesRaw.VRAName | Get-Unique
    $CustomerVRAs = foreach ($VRA in $CustomerVRAsNames){$ZertoVRAs | where vraname -eq $VRA}
    #$CustomerVRAs | Select-Object VraName,@{n='VPGs'}

    Disconnect-ZertoServer

}
Export-ModuleMember -Function Get-ZertoDatastoreUsage
#Test for ANA 9-13-24
# Required Modules Test
Import-Module -Name ZertoApiWrapper -RequiredVersion 2.0.0
Import-Module -Name CredentialManager

<#function Add-RecoveryCentralCustomer
{
    param(
            [Parameter(Mandatory)]
            [string]$CustomerName,
            [Parameter(Mandatory)]
            [string]$TierpointID,
            [Parameter(Mandatory)]
            [string]$CRMID,
            [Parameter(Mandatory)]
            [string]$Zorg
        )
    
    Send-SqlQuery -Connection $db_connection -sqlquery "INSERT INTO dbo.zerto_customers (zerto_customer_name, zerto_customer_tierpoint_id, zerto_customer_zorg, zerto_customer_status, customer_oversubscribed_status_id, CRMID)
VALUES ('$CustomerName', '$TierpointID', '$Zorg', 'Active', '9', '$CRMID')"
}

function Get-CustomerDRStorageReport
{
    param(
    [Parameter(Mandatory)]
    [ValidateNotNullorEmpty()]
    [string]$ZVM,
    [Parameter()]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials,
    [Parameter()]
    [string]$Zorg
)

    Connect-ZertoServer -zertoServer $ZVM -credential $Credentials -AutoReconnect
    $TodaysDate = Get-Date -Format yyyy-MM-dd -Verbose
    $CustomerResourcesReport = Get-ZertoResourcesReport -zorgName $Zorg -startTime $TodaysDate -endTime $TodaysDate -Verbose


    $CustomerDRStorageReport = $CustomerResourcesReport | Select-Object @{n='VPGName';e={$_.Vpg.VpgName}},@{n='Storage';e={$_.recoverysite.storage.volumesprovisionedStorageInGB}},@{n='Journal';e={[math]::Round($_.recoverysite.storage.journalusedstorageinGB)}},@{n='JournalPercent';e={[math]::Round($_.recoverysite.storage.journalusedstorageinGB/$_.recoverysite.storage.volumesprovisionedStorageInGB*100)}}
    $CustomerDRStorageReport
    Disconnect-ZertoServer
}

Set-Alias -Name drs -Value Get-CustomerDRStorageReport
#>

<#
.SYNOPSIS
    Retrieves and exports settings for VPGs from a Zerto Virtual Manager (ZVM) v9.7 and below.

.DESCRIPTION
    This function connects to a Zerto Virtual Manager (ZVM) and retrieves settings for Virtual Protection Groups (VPGs) based on specified criteria. The retrieved settings are exported to a CSV file for further analysis.

.PARAMETER ZVM
    The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER Credentials
    The credentials to connect to the Zerto Virtual Manager. 

.PARAMETER Zorg
    The Zorg identifier of the customer to check settings for.

.PARAMETER VPGName
    The name of the VPG to filter the results.

.PARAMETER RecoverySite
    The name of the recovery site to filter the results.

.PARAMETER ProtectedSite
    The name of the protected site to filter the results.

.PARAMETER RecoveryVPGType
    The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ProtectedVPGType
    The type of protected VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ExportPath
    The directory path where the CSV file will be exported. Default is "~/ZertoScripts".

.PARAMETER Port
    The port to connect to the ZVM. Default is 443.

.EXAMPLE
    # Get network settings for all VPGs in a specific site and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter"

.EXAMPLE
    # Get network settings for a specific customer and export to a specified path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "VCD" -Zorg "CustomerZorg" -ExportPath "C:\Exports"

.EXAMPLE
    # Get network settings for a specific VPG and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter" -VPGName "VPG1"

#>
<#function Export-ZertoVPGSettings9 {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter()]
        [string]$Zorg,
        [Parameter()]
        [string]$VPGName,
        [Parameter()]
        [string]$RecoverySite,
        [Parameter()]
        [string]$ProtectedSite,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$RecoveryVPGType,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$ProtectedVPGType,
        [Parameter()]
        [ValidateScript({
                if (!($_ | Test-Path -PathType Container))
                {
                    throw "The path argument must be a directory not a file"
                }
                return $true
            })]
        [string]$ExportPath="~/ZertoScripts",
        [Parameter()]
        [string]$Port="9669"

    )

    if (-not (Test-Path $ExportPath))
    {
        $ExportPath = New-Item $ExportPath -ItemType Directory
    }

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref
    $typeHash = @{
        vCenter = "0"
        VCD     = "2"
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'recoveryvpgtype')))
    {

        $RecoverySiteType = $typeHash[$RecoveryVpgType]
    }

    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedvpgtype')))
    {
        $ProtectedSiteType = $typeHash[$ProtectedVpgType]
    }

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref

    Function Invoke-WebWrapper($Core,$Uri,$Method,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType
            }
        }
        catch
        {
            if ([string]$_.Exception.Response.StatusCode.value__ -eq "401")
            {
                throw("Unauthorized, Invalid credentials")
            }
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    Function Invoke-RestWrapper($Core,$Uri,$Method,$Body,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType
            }
        }
        catch
        {
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    if ($PSVersionTable.PSVersion.Major -gt 6) {$TurboCore = $true} else {$TurboCore = $false}
    if (-not $TurboCore)
    {
        try
        {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        catch
        {
            Write-Host "Already ignoring SSL cert errors"
        }
    }

    $ZertoUser = $Credentials.UserName
    $ZertoPassword = $Credentials.GetNetworkCredential().Password
    $BaseURL = "https://" + $ZVM + ":" + "$Port" + "/v1/"
    $GUIBaseURL = "https://" + $ZVM + ":" + "$Port" + "/GuiServices/v1/VisualQueryProvider/"
    $ZertoSessionURL = $BaseURL + "session/add"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoUser+":"+$ZertoPassword))}
    $Type = "application/json"

    # Auth
    $ZertoSessionResponse = Invoke-WebWrapper -Core $TurboCore -Uri $ZertoSessionURL -Method Post -Headers $Header -ContentType $Type 
    $ZertoSession = $ZertoSessionResponse.headers.get_item("x-zerto-session")
    $ZertoSessionHeader = @{"Accept" ="application/json"
        "x-zerto-session"            ="$ZertoSession"
    }
    $DSRemoteSession = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoSession))
    $GUISessionHeader = @{"Accept" ="application/json"
        DSRemoteCredentials        = $DSRemoteSession
    }
    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    # Gather Site ID's so we can relay information and filter based on that 
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')) -or ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
    {
        $VirtualizationSitesURL = $BaseURL+"virtualizationsites"
        $VirtualizationSiteList = Invoke-RestWrapper -Core $TurboCore -Uri $VirtualizationSitesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
        # Only set requested values
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite'))
        {
            $ProtectedSiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $ProtectedSite}  | select -ExpandProperty SiteIdentifier
        }
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite'))
        {
            $RecoverySiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $RecoverySite}  | select -ExpandProperty SiteIdentifier
        } 
        # If values are not found warn user
        if (($null -eq $RecoverySiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
        {
            Write-Host "Could not find site information for $RecoverySite" -ForegroundColor Red
        }
        if (($null -eq $ProtectedSiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')))
        {
            Write-Host "Could not find site information for $ProtectedSite" -ForegroundColor Red
        }
    }
    # Get Zorgs if requested
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'zorg')))
    {
        $ZorgURL = $BaseURL+"zorgs"
        $ZorgList = Invoke-RestWrapper -Core $TurboCore -Uri $ZorgURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
        $ZorgIdentifier = $ZorgList | Where-Object {$_.ZorgName -eq $Zorg} | select -ExpandProperty ZorgIdentifier
    }
    # Get Service Profiles
    $ServiceProfilesURL = $BaseURL+"serviceprofiles"
    $ServiceProfileList = Invoke-RestWrapper -Core $TurboCore -Uri $ServiceProfilesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 

    #Array lists fast
    $VPGArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoverySiteArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoveryOrgVDCArray = New-Object -TypeName "System.Collections.ArrayList"

    # Doing filter in the URL to lighten load on ZVM, but since it doesnt support wildcards, we ommit VPGName and sort that later
    # Then make sure its encoded properly since users might enter shenanigans

    $VPGListUrl = $BaseURL+"vpgs?zorgIdentifier=$ZorgIdentifier&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=" +
    "$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    Add-Type -AssemblyName System.Web
    $EncodedVPGListUrl = [System.Web.HttpUtility]::UrlPathEncode($VPGListUrl)
    Write-Host "Filtering VPGS: $EncodedVPGListUrl"
    $VPGList = Invoke-RestWrapper -Core $TurboCore -Uri $VPGListUrl -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
    if ([bool]($MyInvocation.BoundParameters.Keys -match 'vpgname'))
    {
        $VPGList = $VPGList | Where-Object {$_.vpgName -like "*${VPGName}*"}
    }
    Write-Host "Found $($VPGList.count) VPGs to process" -ForegroundColor Yellow
    Start-Sleep 2

    ForEach ($VPG in $VPGList)
    {   
        $VPGID = $VPG.VpgIdentifier
        $VPGName = $VPG.VpgName
        Write-Host "Starting $VPGName" -ForegroundColor Yellow
        $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
        # Posting the VPG JSON Request to the API to get a settings ID (like clicking edit on a VPG in the GUI)
        $EditVPGURL = $BaseURL+"vpgSettings"
        $VPGSettingsID = Invoke-RestWrapper -Core $TurboCore -Uri $EditVPGURL -Method Post -Body $VPGJSON -ContentType $Type -Headers $ZertoSessionHeader   
        if ($?) {$ValidVPGSettingsID = $true} else {$ValidVPGSettingsID = $false}
        # Getting VPG settings from API
        # Skipping if unable to obtain valid VPG setting identifier
        if ($ValidVPGSettingsID)
        {
            # Getting VPG settings
            $VPGSettingsURL = $BaseURL+"vpgSettings/"+$VPGSettingsID
            $VPGSettings = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader   
            $VPGName = $VPGSettings.Basic.Name
            $VPGRecoverySiteID = $VPGSettings.Basic.RecoverySiteIdentifier
            $VPGRpoInSeconds = $VPGSettings.Basic.RpoInSeconds
            $VPGTestIntervalInMinutes = $VPGSettings.Basic.TestIntervalInMinutes
            $VPGJournalHistoryInHours = $VPGSettings.Basic.JournalHistoryInHours
            $VPGPriority = $VPGSettings.Basic.Priority
            $VPGDescription = $VPG.VPGDescription
            # Get RecoverySite details only if havent before
            if (-not ($VPGRecoverySiteArray.Contains($VPGRecoverySiteID)))
            {
                Write-Host "Discovering new recovery site " -NoNewline -ForegroundColor Cyan
                $null = $VPGRecoverySiteArray.Add($VPGRecoverySiteID)
                $DatastoresURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/datastores"
                Write-Host "datastores, " -NoNewline -ForegroundColor Cyan
                $DatastoreList += Invoke-RestWrapper -Core $TurboCore -Uri $DatastoresURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $FoldersURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/folders"
                Write-Host "folders, " -NoNewline -ForegroundColor Cyan
                $FolderList += Invoke-RestWrapper -Core $TurboCore -Uri $FoldersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $HostclustersURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/hostclusters"
                Write-Host "clusters, " -NoNewline -ForegroundColor Cyan
                $HostclusterList += Invoke-RestWrapper -Core $TurboCore -Uri $HostclustersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $HostsURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/hosts"
                Write-Host "hosts, " -NoNewline -ForegroundColor Cyan
                $HostList += Invoke-RestWrapper -Core $TurboCore -Uri $HostsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $ResourcePoolsURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/resourcepools"
                Write-Host "resource pools, " -NoNewline -ForegroundColor Cyan
                $ResourcePoolsList += Invoke-RestWrapper -Core $TurboCore -Uri $ResourcePoolsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $VPGPortGroupsURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/networks"
                Write-Host "networks." -ForegroundColor Cyan
                $VPGPortGroups += Invoke-RestWrapper -Core $TurboCore -Uri $VPGPortGroupsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type   
            }
            $VPGArrayLine = New-Object PSObject
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDesc" -Value $VPGDescription
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "RpoInSeconds" -Value $VPGRpoInSeconds
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "TestIntervalInMinutes" -Value $VPGTestIntervalInMinutes
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHistoryInHours" -Value $VPGJournalHistoryInHours
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "Priority" -Value $VPGPriority
            if ($null -ne $VPGSettings.Recovery.VCD)
            {
                # VCD only
                Write-Host "Recovery site is VCD"
                $VPGRecoveryOrgVDC = $VPGSettings.Recovery.VCD.OrgVdcIdentifier
                # If we havent gathered site details for this org VDC yet
                if (-not ($VPGRecoveryOrgVDCArray.Contains($VPGRecoveryOrgVDC)))
                {
                    Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoveryOrgVDCArray.Add($VPGRecoveryOrgVDC)
                    $VPGOrgVdcNetworksURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/networks"
                    Write-Host "networks, " -NoNewline -ForegroundColor Cyan
                    $VPGOrgVdcNetworks += Invoke-RestWrapper -Core $TurboCore -Uri $VPGOrgVdcNetworksURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type    
                    $VPGOrgVdcStoragePoliciesURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/storagepolicies"
                    Write-Host "storage profiles." -ForegroundColor Cyan
                    $VPGOrgVdcStoragePolicies += Invoke-RestWrapper -Core $TurboCore -Uri $VPGOrgVdcStoragePoliciesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type    
                }
                $VPGDefaultRecoveryOrgVdcNetworkFailoverID = $VPGSettings.Networks.Failover.VCD.DefaultRecoveryOrgVdcNetworkIdentifier
                $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID = $VPGSettings.Networks.FailoverTest.VCD.DefaultRecoveryOrgVdcNetworkIdentifier
                $VPGVCDNetworkDefaultFailover = $VPGOrgVdcNetworks | Where-Object {$_.NetworkIdentifier -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverID}  | select -ExpandProperty VirtualizationNetworkName
                $VPGVCDNetworkDefaultFailoverTest = $VPGOrgVdcNetworks | Where-Object {$_.NetworkIdentifier -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID}  | select -ExpandProperty VirtualizationNetworkName
            }
            else
            {
                # vCenter only
                Write-Host "Recovery site is vCenter"
                $VPGDefaultHostID = $VPGSettings.Recovery.DefaultHostIdentifier
                $VPGDefaultHostClusterID = $VPGSettings.Recovery.DefaultHostClusterIdentifier
                $VPGDefaultDatastoreID = $VPGSettings.Recovery.DefaultDatastoreIdentifier
                $VPGDefaultFolderID = $VPGSettings.Recovery.DefaultFolderIdentifier
                $VPGDefaultResourcePoolID = $VPGSettings.Recovery.ResourcePoolIdentifier
                $VPGNetworkDefaultFailoverID = $VPGSettings.Networks.Failover.Hypervisor.DefaultNetworkIdentifier
                $VPGNetworkDefaultFailoverTestID = $VPGSettings.Networks.FailoverTest.Hypervisor.DefaultNetworkIdentifier
                $VPGDefaultHost = $HostList | Where-Object {$_.HostIdentifier -eq $VPGDefaultHostID}  | select -ExpandProperty VirtualizationHostName
                $VPGDefaultHostCluster = $HostClusterList | Where-Object {$_.ClusterIdentifier -eq $VPGDefaultHostClusterID}  | select -ExpandProperty VirtualizationClusterName
                $VPGDefaultFolder = $FolderList | Where-Object {$_.FolderIdentifier -eq $VPGDefaultFolderID}  | select -ExpandProperty FolderName
                $VPGDefaultDatastore = $DatastoreList | Where-Object {$_.DatastoreIdentifier -eq $VPGDefaultDatastoreID}  | select -ExpandProperty DatastoreName
                $VPGDefaultResourcePool = $ResourcePoolsList | Where-Object {$_.ResourcepoolIdentifier -eq $VPGDefaultResourcePoolID}  | select -ExpandProperty ResourcepoolName
                $VPGNetworkDefaultFailover = $VPGPortGroups | Where-Object {$_.NetworkIdentifier -eq $VPGNetworkDefaultFailoverID}  | select -ExpandProperty VirtualizationNetworkName
                $VPGNetworkDefaultFailoverTest = $VPGPortGroups | Where-Object {$_.NetworkIdentifier -eq $VPGNetworkDefaultFailoverTestID}  | select -ExpandProperty VirtualizationNetworkName
            }
            # Null the values so they create the CSV properly when there is a mix of VCD and Vcenter 
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VcenterNetworkDefaultFailover" -Value $VPGNetworkDefaultFailover
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VcenterNetworkDefaultFailoverTest" -Value $VPGNetworkDefaultFailoverTest
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VCDNetworkDefaultFailover" -Value $VPGVCDNetworkDefaultFailover
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VCDNetworkDefaultFailoverTest" -Value $VPGVCDNetworkDefaultFailoverTest
            # Service Profile
            $VPGServiceProfileID = $VPGSettings.Basic.ServiceProfileIdentifier
            $VPGServiceProfileName = $ServiceProfileList | Where-Object {$_.ServiceProfileIdentifier -eq $VPGServiceProfileID}  | select -ExpandProperty ServiceProfileName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ServiceProfile" -Value $VPGServiceProfileName
            # Journal
            $JournalHardLimitInMB = $VPGSettings.Journal.Limitation.HardLimitInMB
            $JournalHardLimitInPercent = $VPGSettings.Journal.Limitation.HardLimitInPercent
            $JournalWarningThresholdInMB = $VPGSettings.Journal.Limitation.WarningThresholdInMB
            $JournalWarningThresholdInPercent = $VPGSettings.Journal.Limitation.WarningThresholdInPercent
            $JournalDatastoreID = $VPGSettings.Journal.DatastoreIdentifier
            $ScratchHardLimitInMB = $VPGSettings.Scratch.Limitation.HardLimitInMB
            $ScratchHardLimitInPercent = $VPGSettings.Scratch.Limitation.HardLimitInPercent
            $ScratchWarningThresholdInMB = $VPGSettings.Scratch.Limitation.WarningThresholdInMB
            $ScratchWarningThresholdInPercent = $VPGSettings.Scratch.Limitation.WarningThresholdInPercent
            $ScratchDatastoreID = $VPGSettings.Scratch.DatastoreIdentifier
            $JournalDatastoreName = $DatastoreList | Where-Object {$_.DatastoreIdentifier -eq $JournalDatastoreID}  | select -ExpandProperty DatastoreName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHardLimitInMB" -Value $JournalHardLimitInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHardLimitInPercent" -Value $JournalHardLimitInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalWarningThresholdInMB" -Value $JournalWarningThresholdInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalWarningThresholdInPercent" -Value $JournalWarningThresholdInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalDatastore" -Value $JournalDatastoreName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchHardLimitInMB" -Value $ScratchHardLimitInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchHardLimitInPercent" -Value $ScratchHardLimitInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchWarningThresholdInMB" -Value $ScratchWarningThresholdInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchWarningThresholdInPercent" -Value $ScratchWarningThresholdInPercent
            # Vcenter stuff
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultHost" -Value $VPGDefaultHost
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultHostCluster" -Value $VPGDefaultHostCluster
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultDatastore" -Value $VPGDefaultDatastore
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultFolder" -Value $VPGDefaultFolder
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultResourcePool" -Value $VPGDefaultResourcePool
            #Disk Sync Properties
            $volumesyncsettings = $VPGSettings.Vms.volumes.volumesyncsettings
            $InitialSyncOnly = $false
            foreach ($volume in $volumesyncsettings){if ($volume -ne "ContinuousSync"){$InitialSyncOnly = $true}}
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "InitialSyncOnly" -Value $InitialSyncOnly
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGID" -Value $VPGID
            # Create new line in CSV
            $null = $VPGArray.Add($VPGArrayLine)
            Write-Host "Finished $VPGName" -ForegroundColor Green
            # Blank values out so no chance they carry over
            $VPGName = $null
            $VPGID = $null
            $VPGRpoInSeconds = $null
            $VPGTestIntervalInMinutes = $null
            $VPGJournalHistoryInHours = $null
            $VPGPriority = $null
            $VPGNetworkDefaultFailover = $null
            $VPGNetworkDefaultFailoverTest = $null
            $VPGVCDNetworkDefaultFailover = $null
            $VPGVCDNetworkDefaultFailoverTest = $null
            $VPGServiceProfileName = $null
            $JournalHardLimitInMB = $null
            $JournalHardLimitInPercent = $null
            $JournalWarningThresholdInMB = $null
            $JournalWarningThresholdInPercent = $null
            $JournalDatastoreName = $null
            $VPGDefaultHost = $null
            $VPGDefaultHostCluster = $null
            $VPGDefaultDatastore = $null
            $VPGDefaultFolder = $null
            $VPGDefaultResourcePool = $null
            # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
            $null = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Delete -Headers $ZertoSessionHeader -ContentType $Type 
        }
    }
    # Exporting to CSV
    $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmm) + "-$ZVM-VPGS$(if ($Zorg){$Zorg}).csv"
    try
    {
        $VPGArray | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
        if (Test-Path -Path $CSVExportFile -PathType Leaf)
        {
            Write-Host "`nCopy/Paste next line to open CSV:" -ForegroundColor Green
            Write-Host ". $CSVExportFile `n" 
        }
        else
        {
            Write-Host "Unknown error, could not create CSV.  Check path $CSVExportFile" -ForegroundColor Red
        }
    }
    catch [System.IO.IOException]
    {
        #If we wait a minute, a new name will be generated.
        Write-Host "$CSVExportFile is already open.  Adding seconds to name" -ForegroundColor Yellow
        Start-Sleep -Seconds 60
        $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmmss) + "-$ZVM-VPGS$(if ($Zorg){$Zorg}).csv"
        $VPGArray | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
    }
    catch
    {
        $_.Exception.ToString()
        $error[0] | Format-List -Force
    }
}

Set-Alias -Name zset9 -Value Export-ZertoVPGSettings9
#>

<#
.SYNOPSIS
    Retrieves and exports settings for VPGs from a Zerto Virtual Manager (ZVM) v9.7 and below.

.DESCRIPTION
    This function connects to a Zerto Virtual Manager (ZVM) and retrieves settings for Virtual Protection Groups (VPGs) based on specified criteria. The retrieved settings are exported to a CSV file for further analysis.

.PARAMETER ZVM
    The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER Credentials
    The credentials to connect to the Zerto Virtual Manager. 

.PARAMETER Zorg
    The Zorg identifier of the customer to check settings for.

.PARAMETER VPGName
    The name of the VPG to filter the results.

.PARAMETER RecoverySite
    The name of the recovery site to filter the results.

.PARAMETER ProtectedSite
    The name of the protected site to filter the results.

.PARAMETER RecoveryVPGType
    The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ProtectedVPGType
    The type of protected VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ExportPath
    The directory path where the CSV file will be exported. Default is "~/ZertoScripts".

.PARAMETER Port
    The port to connect to the ZVM. Default is 443.

.EXAMPLE
    # Get network settings for all VPGs in a specific site and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter"

.EXAMPLE
    # Get network settings for a specific customer and export to a specified path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "VCD" -Zorg "CustomerZorg" -ExportPath "C:\Exports"

.EXAMPLE
    # Get network settings for a specific VPG and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter" -VPGName "VPG1"

#>

<#function Export-ZertoVPGSettings9 {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter()]
        [string]$Zorg,
        [Parameter()]
        [string]$VPGName,
        [Parameter()]
        [string]$RecoverySite,
        [Parameter()]
        [string]$ProtectedSite,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$RecoveryVPGType,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$ProtectedVPGType,
        [Parameter()]
        [ValidateScript({
                if (!($_ | Test-Path -PathType Container))
                {
                    throw "The path argument must be a directory not a file"
                }
                return $true
            })]
        [string]$ExportPath="~/ZertoScripts",
        [Parameter()]
        [string]$Port="9669"

    )

    if (-not (Test-Path $ExportPath))
    {
        $ExportPath = New-Item $ExportPath -ItemType Directory
    }

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref
    $typeHash = @{
        vCenter = "0"
        VCD     = "2"
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'recoveryvpgtype')))
    {

        $RecoverySiteType = $typeHash[$RecoveryVpgType]
    }

    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedvpgtype')))
    {
        $ProtectedSiteType = $typeHash[$ProtectedVpgType]
    }

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref

    Function Invoke-WebWrapper($Core,$Uri,$Method,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType
            }
        }
        catch
        {
            if ([string]$_.Exception.Response.StatusCode.value__ -eq "401")
            {
                throw("Unauthorized, Invalid credentials")
            }
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    Function Invoke-RestWrapper($Core,$Uri,$Method,$Body,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType
            }
        }
        catch
        {
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    if ($PSVersionTable.PSVersion.Major -gt 6) {$TurboCore = $true} else {$TurboCore = $false}
    if (-not $TurboCore)
    {
        try
        {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        catch
        {
            Write-Host "Already ignoring SSL cert errors"
        }
    }

    $ZertoUser = $Credentials.UserName
    $ZertoPassword = $Credentials.GetNetworkCredential().Password
    $BaseURL = "https://" + $ZVM + "/v1/"
    $GUIBaseURL = "https://" + $ZVM + ":" + "$Port" + "/GuiServices/v1/VisualQueryProvider/"
    $ZertoSessionURL = $BaseURL + "session/add"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoUser+":"+$ZertoPassword))}
    $Type = "application/json"

    # Auth
    $ZertoSessionResponse = Invoke-WebWrapper -Core $TurboCore -Uri $ZertoSessionURL -Method Post -Headers $Header -ContentType $Type 
    $ZertoSession = $ZertoSessionResponse.headers.get_item("x-zerto-session")
    $ZertoSessionHeader = @{"Accept" ="application/json"
        "x-zerto-session"            ="$ZertoSession"
    }
    $DSRemoteSession = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoSession))
    $GUISessionHeader = @{"Accept" ="application/json"
        DSRemoteCredentials        = $DSRemoteSession
    }
    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    # Gather Site ID's so we can relay information and filter based on that 
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')) -or ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
    {
        $VirtualizationSitesURL = $BaseURL+"virtualizationsites"
        $VirtualizationSiteList = Invoke-RestWrapper -Core $TurboCore -Uri $VirtualizationSitesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
        # Only set requested values
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite'))
        {
            $ProtectedSiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $ProtectedSite}  | select -ExpandProperty SiteIdentifier
        }
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite'))
        {
            $RecoverySiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $RecoverySite}  | select -ExpandProperty SiteIdentifier
        } 
        # If values are not found warn user
        if (($null -eq $RecoverySiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
        {
            Write-Host "Could not find site information for $RecoverySite" -ForegroundColor Red
        }
        if (($null -eq $ProtectedSiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')))
        {
            Write-Host "Could not find site information for $ProtectedSite" -ForegroundColor Red
        }
    }
    # Get Zorgs if requested
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'zorg')))
    {
        $ZorgURL = $BaseURL+"zorgs"
        $ZorgList = Invoke-RestWrapper -Core $TurboCore -Uri $ZorgURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
        $ZorgIdentifier = $ZorgList | Where-Object {$_.ZorgName -eq $Zorg} | select -ExpandProperty ZorgIdentifier
    }
    # Get Service Profiles
    $ServiceProfilesURL = $BaseURL+"serviceprofiles"
    $ServiceProfileList = Invoke-RestWrapper -Core $TurboCore -Uri $ServiceProfilesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 

    #Array lists fast
    $VPGArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoverySiteArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoveryOrgVDCArray = New-Object -TypeName "System.Collections.ArrayList"

    # Doing filter in the URL to lighten load on ZVM, but since it doesnt support wildcards, we ommit VPGName and sort that later
    # Then make sure its encoded properly since users might enter shenanigans

    $VPGListUrl = $BaseURL+"vpgs?zorgIdentifier=$ZorgIdentifier&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=" +
    "$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    Add-Type -AssemblyName System.Web
    $EncodedVPGListUrl = [System.Web.HttpUtility]::UrlPathEncode($VPGListUrl)
    Write-Host "Filtering VPGS: $EncodedVPGListUrl"
    $VPGList = Invoke-RestWrapper -Core $TurboCore -Uri $VPGListUrl -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
    if ([bool]($MyInvocation.BoundParameters.Keys -match 'vpgname'))
    {
        $VPGList = $VPGList | Where-Object {$_.vpgName -like "*${VPGName}*"}
    }
    Write-Host "Found $($VPGList.count) VPGs to process" -ForegroundColor Yellow
    Start-Sleep 2

    ForEach ($VPG in $VPGList)
    {   
        $VPGID = $VPG.VpgIdentifier
        $VPGName = $VPG.VpgName
        Write-Host "Starting $VPGName" -ForegroundColor Yellow
        $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
        # Posting the VPG JSON Request to the API to get a settings ID (like clicking edit on a VPG in the GUI)
        $EditVPGURL = $BaseURL+"vpgSettings"
        $VPGSettingsID = Invoke-RestWrapper -Core $TurboCore -Uri $EditVPGURL -Method Post -Body $VPGJSON -ContentType $Type -Headers $ZertoSessionHeader   
        if ($?) {$ValidVPGSettingsID = $true} else {$ValidVPGSettingsID = $false}
        # Getting VPG settings from API
        # Skipping if unable to obtain valid VPG setting identifier
        if ($ValidVPGSettingsID)
        {
            # Getting VPG settings
            $VPGSettingsURL = $BaseURL+"vpgSettings/"+$VPGSettingsID
            $VPGSettings = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader   
            $VPGName = $VPGSettings.Basic.Name
            $VPGRecoverySiteID = $VPGSettings.Basic.RecoverySiteIdentifier
            $VPGRpoInSeconds = $VPGSettings.Basic.RpoInSeconds
            $VPGTestIntervalInMinutes = $VPGSettings.Basic.TestIntervalInMinutes
            $VPGJournalHistoryInHours = $VPGSettings.Basic.JournalHistoryInHours
            $VPGPriority = $VPGSettings.Basic.Priority
            $VPGDescription = $VPG.VPGDescription
            # Get RecoverySite details only if havent before
            if (-not ($VPGRecoverySiteArray.Contains($VPGRecoverySiteID)))
            {
                Write-Host "Discovering new recovery site " -NoNewline -ForegroundColor Cyan
                $null = $VPGRecoverySiteArray.Add($VPGRecoverySiteID)
                $DatastoresURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/datastores"
                Write-Host "datastores, " -NoNewline -ForegroundColor Cyan
                $DatastoreList += Invoke-RestWrapper -Core $TurboCore -Uri $DatastoresURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $FoldersURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/folders"
                Write-Host "folders, " -NoNewline -ForegroundColor Cyan
                $FolderList += Invoke-RestWrapper -Core $TurboCore -Uri $FoldersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $HostclustersURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/hostclusters"
                Write-Host "clusters, " -NoNewline -ForegroundColor Cyan
                $HostclusterList += Invoke-RestWrapper -Core $TurboCore -Uri $HostclustersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $HostsURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/hosts"
                Write-Host "hosts, " -NoNewline -ForegroundColor Cyan
                $HostList += Invoke-RestWrapper -Core $TurboCore -Uri $HostsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $ResourcePoolsURL = $BaseURL+"virtualizationsites/$VPGRecoverySiteID/resourcepools"
                Write-Host "resource pools, " -NoNewline -ForegroundColor Cyan
                $ResourcePoolsList += Invoke-RestWrapper -Core $TurboCore -Uri $ResourcePoolsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                $VPGPortGroupsURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/networks"
                Write-Host "networks." -ForegroundColor Cyan
                $VPGPortGroups += Invoke-RestWrapper -Core $TurboCore -Uri $VPGPortGroupsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type   
            }
            $VPGArrayLine = New-Object PSObject
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDesc" -Value $VPGDescription
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "RpoInSeconds" -Value $VPGRpoInSeconds
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "TestIntervalInMinutes" -Value $VPGTestIntervalInMinutes
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHistoryInHours" -Value $VPGJournalHistoryInHours
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "Priority" -Value $VPGPriority
            if ($null -ne $VPGSettings.Recovery.VCD)
            {
                # VCD only
                Write-Host "Recovery site is VCD"
                $VPGRecoveryOrgVDC = $VPGSettings.Recovery.VCD.OrgVdcIdentifier
                # If we havent gathered site details for this org VDC yet
                if (-not ($VPGRecoveryOrgVDCArray.Contains($VPGRecoveryOrgVDC)))
                {
                    Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoveryOrgVDCArray.Add($VPGRecoveryOrgVDC)
                    $VPGOrgVdcNetworksURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/networks"
                    Write-Host "networks, " -NoNewline -ForegroundColor Cyan
                    $VPGOrgVdcNetworks += Invoke-RestWrapper -Core $TurboCore -Uri $VPGOrgVdcNetworksURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type    
                    $VPGOrgVdcStoragePoliciesURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/storagepolicies"
                    Write-Host "storage profiles." -ForegroundColor Cyan
                    $VPGOrgVdcStoragePolicies += Invoke-RestWrapper -Core $TurboCore -Uri $VPGOrgVdcStoragePoliciesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type    
                }
                $VPGDefaultRecoveryOrgVdcNetworkFailoverID = $VPGSettings.Networks.Failover.VCD.DefaultRecoveryOrgVdcNetworkIdentifier
                $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID = $VPGSettings.Networks.FailoverTest.VCD.DefaultRecoveryOrgVdcNetworkIdentifier
                $VPGVCDNetworkDefaultFailover = $VPGOrgVdcNetworks | Where-Object {$_.NetworkIdentifier -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverID}  | select -ExpandProperty VirtualizationNetworkName
                $VPGVCDNetworkDefaultFailoverTest = $VPGOrgVdcNetworks | Where-Object {$_.NetworkIdentifier -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID}  | select -ExpandProperty VirtualizationNetworkName
            }
            else
            {
                # vCenter only
                Write-Host "Recovery site is vCenter"
                $VPGDefaultHostID = $VPGSettings.Recovery.DefaultHostIdentifier
                $VPGDefaultHostClusterID = $VPGSettings.Recovery.DefaultHostClusterIdentifier
                $VPGDefaultDatastoreID = $VPGSettings.Recovery.DefaultDatastoreIdentifier
                $VPGDefaultFolderID = $VPGSettings.Recovery.DefaultFolderIdentifier
                $VPGDefaultResourcePoolID = $VPGSettings.Recovery.ResourcePoolIdentifier
                $VPGNetworkDefaultFailoverID = $VPGSettings.Networks.Failover.Hypervisor.DefaultNetworkIdentifier
                $VPGNetworkDefaultFailoverTestID = $VPGSettings.Networks.FailoverTest.Hypervisor.DefaultNetworkIdentifier
                $VPGDefaultHost = $HostList | Where-Object {$_.HostIdentifier -eq $VPGDefaultHostID}  | select -ExpandProperty VirtualizationHostName
                $VPGDefaultHostCluster = $HostClusterList | Where-Object {$_.ClusterIdentifier -eq $VPGDefaultHostClusterID}  | select -ExpandProperty VirtualizationClusterName
                $VPGDefaultFolder = $FolderList | Where-Object {$_.FolderIdentifier -eq $VPGDefaultFolderID}  | select -ExpandProperty FolderName
                $VPGDefaultDatastore = $DatastoreList | Where-Object {$_.DatastoreIdentifier -eq $VPGDefaultDatastoreID}  | select -ExpandProperty DatastoreName
                $VPGDefaultResourcePool = $ResourcePoolsList | Where-Object {$_.ResourcepoolIdentifier -eq $VPGDefaultResourcePoolID}  | select -ExpandProperty ResourcepoolName
                $VPGNetworkDefaultFailover = $VPGPortGroups | Where-Object {$_.NetworkIdentifier -eq $VPGNetworkDefaultFailoverID}  | select -ExpandProperty VirtualizationNetworkName
                $VPGNetworkDefaultFailoverTest = $VPGPortGroups | Where-Object {$_.NetworkIdentifier -eq $VPGNetworkDefaultFailoverTestID}  | select -ExpandProperty VirtualizationNetworkName
            }
            # Null the values so they create the CSV properly when there is a mix of VCD and Vcenter 
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VcenterNetworkDefaultFailover" -Value $VPGNetworkDefaultFailover
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VcenterNetworkDefaultFailoverTest" -Value $VPGNetworkDefaultFailoverTest
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VCDNetworkDefaultFailover" -Value $VPGVCDNetworkDefaultFailover
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VCDNetworkDefaultFailoverTest" -Value $VPGVCDNetworkDefaultFailoverTest
            # Service Profile
            $VPGServiceProfileID = $VPGSettings.Basic.ServiceProfileIdentifier
            $VPGServiceProfileName = $ServiceProfileList | Where-Object {$_.ServiceProfileIdentifier -eq $VPGServiceProfileID}  | select -ExpandProperty ServiceProfileName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ServiceProfile" -Value $VPGServiceProfileName
            # Journal
            $JournalHardLimitInMB = $VPGSettings.Journal.Limitation.HardLimitInMB
            $JournalHardLimitInPercent = $VPGSettings.Journal.Limitation.HardLimitInPercent
            $JournalWarningThresholdInMB = $VPGSettings.Journal.Limitation.WarningThresholdInMB
            $JournalWarningThresholdInPercent = $VPGSettings.Journal.Limitation.WarningThresholdInPercent
            $JournalDatastoreID = $VPGSettings.Journal.DatastoreIdentifier
            $ScratchHardLimitInMB = $VPGSettings.Scratch.Limitation.HardLimitInMB
            $ScratchHardLimitInPercent = $VPGSettings.Scratch.Limitation.HardLimitInPercent
            $ScratchWarningThresholdInMB = $VPGSettings.Scratch.Limitation.WarningThresholdInMB
            $ScratchWarningThresholdInPercent = $VPGSettings.Scratch.Limitation.WarningThresholdInPercent
            $ScratchDatastoreID = $VPGSettings.Scratch.DatastoreIdentifier
            $JournalDatastoreName = $DatastoreList | Where-Object {$_.DatastoreIdentifier -eq $JournalDatastoreID}  | select -ExpandProperty DatastoreName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHardLimitInMB" -Value $JournalHardLimitInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalHardLimitInPercent" -Value $JournalHardLimitInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalWarningThresholdInMB" -Value $JournalWarningThresholdInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalWarningThresholdInPercent" -Value $JournalWarningThresholdInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalDatastore" -Value $JournalDatastoreName
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchHardLimitInMB" -Value $ScratchHardLimitInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchHardLimitInPercent" -Value $ScratchHardLimitInPercent
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchWarningThresholdInMB" -Value $ScratchWarningThresholdInMB
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "ScratchWarningThresholdInPercent" -Value $ScratchWarningThresholdInPercent
            # Vcenter stuff
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultHost" -Value $VPGDefaultHost
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultHostCluster" -Value $VPGDefaultHostCluster
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultDatastore" -Value $VPGDefaultDatastore
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultFolder" -Value $VPGDefaultFolder
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "DefaultResourcePool" -Value $VPGDefaultResourcePool
            #Disk Sync Properties
            $volumesyncsettings = $VPGSettings.Vms.volumes.volumesyncsettings
            $InitialSyncOnly = $false
            foreach ($volume in $volumesyncsettings){if ($volume -ne "ContinuousSync"){$InitialSyncOnly = $true}}
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "InitialSyncOnly" -Value $InitialSyncOnly
            $VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGID" -Value $VPGID
            # Create new line in CSV
            $null = $VPGArray.Add($VPGArrayLine)
            Write-Host "Finished $VPGName" -ForegroundColor Green
            # Blank values out so no chance they carry over
            $VPGName = $null
            $VPGID = $null
            $VPGRpoInSeconds = $null
            $VPGTestIntervalInMinutes = $null
            $VPGJournalHistoryInHours = $null
            $VPGPriority = $null
            $VPGNetworkDefaultFailover = $null
            $VPGNetworkDefaultFailoverTest = $null
            $VPGVCDNetworkDefaultFailover = $null
            $VPGVCDNetworkDefaultFailoverTest = $null
            $VPGServiceProfileName = $null
            $JournalHardLimitInMB = $null
            $JournalHardLimitInPercent = $null
            $JournalWarningThresholdInMB = $null
            $JournalWarningThresholdInPercent = $null
            $JournalDatastoreName = $null
            $VPGDefaultHost = $null
            $VPGDefaultHostCluster = $null
            $VPGDefaultDatastore = $null
            $VPGDefaultFolder = $null
            $VPGDefaultResourcePool = $null
            # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
            $null = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Delete -Headers $ZertoSessionHeader -ContentType $Type 
        }
    }
    # Exporting to CSV
    $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmm) + "-$ZVM-VPGS$(if ($Zorg){$Zorg}).csv"
    try
    {
        $VPGArray | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
        if (Test-Path -Path $CSVExportFile -PathType Leaf)
        {
            Write-Host "`nCopy/Paste next line to open CSV:" -ForegroundColor Green
            Write-Host ". $CSVExportFile `n" 
        }
        else
        {
            Write-Host "Unknown error, could not create CSV.  Check path $CSVExportFile" -ForegroundColor Red
        }
    }
    catch [System.IO.IOException]
    {
        #If we wait a minute, a new name will be generated.
        Write-Host "$CSVExportFile is already open.  Adding seconds to name" -ForegroundColor Yellow
        Start-Sleep -Seconds 60
        $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmmss) + "-$ZVM-VPGS$(if ($Zorg){$Zorg}).csv"
        $VPGArray | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
    }
    catch
    {
        $_.Exception.ToString()
        $error[0] | Format-List -Force
    }
}

Set-Alias -Name zset9 -Value Export-ZertoVPGSettings9
#>
<#
.SYNOPSIS
  This Commandlet is the compliment of Export-ZertoVPGSettings9. After exporting settings to a csv and editing to the desired settings, this function imports the csv and uploads the network settings for VPGs to a Zerto Virtual Manager (ZVM).

.DESCRIPTION
  This function connects to a Zerto Virtual Manager (ZVM) and sends settings for Virtual Protection Groups (VPGs) based on and a csv file. 

.PARAMETER ZVM
  The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER CSVPath
  The path to the csv file. 

.PARAMETER RecoveryVPGType
  The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER Port
  The port to connect to the ZVM. Default is 9669.

.EXAMPLE
   # Send network settings for all VPGs listed in the csv to the Zerto Virtual Manager.
   Import-ZertoSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -CSVPath "C:\users\username\documents\VPGsettings.csv"

#>
<#function Import-ZertoVPGSettings9 {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter()]
        [ValidateScript({
                if (!($_ | Test-Path))
                {
                    throw "File does not exist"
                }
                if (!($_ | Test-Path -PathType Leaf))
                {
                    throw "The path argument must be a file not a directory"
                }
                return $true
            })]
        [string]$CSVPath,
        [Parameter()]
        [string]$Port="9669"
    )

    Function Invoke-WebWrapper($Core,$Uri,$Method,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            if ([string]$_.Exception.Response.StatusCode.value__ -eq "401")
            {
                throw("Unauthorized, Invalid credentials")
            }
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    Function Invoke-RestWrapper($Core,$Uri,$Method,$Body,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    if ($PSVersionTable.PSVersion.Major -gt 6) {$TurboCore = $true} else {$TurboCore = $false}
    if (-not $TurboCore)
    {
        try
        {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        catch
        {
            Write-Host "Already ignoring SSL cert errors"
        }
    }

    $ZertoUser = $Credentials.UserName
    $ZertoPassword = $Credentials.GetNetworkCredential().Password
    $BaseURL = "https://" + $ZVM + ":" + "$Port" + "/v1/"
    $GUIBaseURL = "https://" + $ZVM + ":" + "$Port" + "/GuiServices/v1/VisualQueryProvider/"
    $ZertoSessionURL = $BaseURL + "session/add"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoUser+":"+$ZertoPassword))}
    $Type = "application/json"

    # Auth
    $ZertoSessionResponse = Invoke-WebWrapper -Core $TurboCore -Uri $ZertoSessionURL -Method Post -Headers $Header -ContentType $Type 
    if ($ZertoSessionResponse.StatusCode -eq 401)
    {
        throw('401 Not Authorized.  Please check your credentials and try again')
    }
    $ZertoSession = $ZertoSessionResponse.headers.get_item("x-zerto-session")
    $ZertoSessionHeader = @{"Accept" ="application/json"
        "x-zerto-session"            ="$ZertoSession"
    }
    $DSRemoteSession = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoSession))
    $GUISessionHeader = @{"Accept" ="application/json"
        DSRemoteCredentials        = $DSRemoteSession
    }
    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    $CSVImport = Import-Csv $CSVPath
    $NumVPGs = (Get-Content $CSVPath).Count - 1
    Write-Host "Read $NumVPGs VPGs to configure" -ForegroundColor Yellow
    $VPGRecoverySiteArray = New-Object -TypeName "System.Collections.ArrayList"
    $RecoveryOrgVdcIDArray = New-Object -TypeName "System.Collections.ArrayList"
    $NetworksBySiteId = @{}
    $StorageBySiteId = @{}
    $FoldersBySiteId = @{}
    $ResourcePoolsBySiteId = @{}
    $HostClustersBySiteId = @{}
    $HostsBySiteId = @{}

    # Get Service Profiles
    $ServiceProfilesURL = $BaseURL+"serviceprofiles"
    $ServiceProfileList = Invoke-RestWrapper -Core $TurboCore -Uri $ServiceProfilesURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 

    pause

    if ($null -ne $CSVImport)
    {
        foreach ($VPG in $CSVImport)
        {
            $VPGID = $VPG.VPGID
            Write-Host "Starting $VPGID" -ForegroundColor Yellow
            $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
            $CreateVPGSettingsURL = $BaseURL+"vpgSettings"
            $VPGSettingsID = Invoke-RestWrapper -Core $TurboCore -Uri $CreateVPGSettingsURL -Method Post -Body $VPGJSON -ContentType $Type -Headers $ZertoSessionHeader  
            if ($?) {$ValidVPGSettingsID = $True} else {$ValidVPGSettingsID = $False}

            if ($ValidVPGSettingsID)
            {
                # Getting VPG settings
                $VPGSettingsURL = $BaseURL + "vpgSettings/$VPGSettingsID"
                $OriginalVPGSettings = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader 
                # Deep clone of object
                $VPGSettings = $OriginalVPGSettings | ConvertTo-Json -Depth 10 | ConvertFrom-JSON
                $RecoverySiteID = $VPGSettings.Basic.RecoverySiteIdentifier
                $ServiceProfileIdentifier = $ServiceProfileList | Where-Object {$_.ServiceProfileName -eq $VPG.ServiceProfile} | select -ExpandProperty ServiceProfileIdentifier
                # Update Basic 
                $VPGSettings.Basic.Name                     = $VPG.VPGName
                $VPGSettings.Basic.RpoInSeconds             = [int]$VPG.RpoInSeconds 
                $VPGSettings.Basic.TestIntervalInMinutes    = [int]$VPG.TestIntervalInMinutes
                $VPGSettings.Basic.JournalHistoryInHours    = [int]$VPG.JournalHistoryInHours
                $VPGSettings.Basic.Priority                 = $VPG.Priority
                $VPGSettings.Basic.ServiceProfileIdentifier = $ServiceProfileIdentifier
                # Update Journal
                # Casting to int makes null values = 0.
                if ($null -eq [int]$VPG.JournalHardLimitInMB) {$JournalHardLimitInMB = $null}
                else {$JournalHardLimitInMB = [int]$VPG.JournalHardLimitInMB}
                if ($null -eq [int]$VPG.JournalHardLimitInPercent) {$JournalHardLimitInPercent = $null}
                else {$JournalHardLimitInPercent = [int]$VPG.JournalHardLimitInPercent}
                if ($null -eq [int]$VPG.JournalWarningThresholdInMB) {$JournalWarningThresholdInMB = $null}
                else {$JournalWarningThresholdInMB = [int]$VPG.JournalWarningThresholdInMB}
                if ($null -eq [int]$VPG.JournalWarningThresholdInPercent) {$JournalWarningThresholdInPercent = $null}
                else {$JournalWarningThresholdInPercent = [int]$VPG.JournalWarningThresholdInPercent}
                $VPGSettings.Journal.Limitation.HardLimitInMB               = $JournalHardLimitInMB
                $VPGSettings.Journal.Limitation.HardLimitInPercent          = $JournalHardLimitInPercent
                $VPGSettings.Journal.Limitation.WarningThresholdInMB        = $JournalWarningThresholdInMB
                $VPGSettings.Journal.Limitation.WarningThresholdInPercent   = $JournalWarningThresholdInPercent
                # Update networks
                if ($null -ne $VPGSettings.Recovery.VCD)
                {
                    Write-Host "Recovery site is VCD"
                    $RecoveryOrgVdcID = $VPGSettings.Recovery.VCD.OrgVdcIdentifier
                    # If we havent gathered site details for this org VDC yet
                    if (-not ($RecoveryOrgVdcIDArray.Contains($RecoveryOrgVdcID)))
                    {
                        Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                        $null = $RecoveryOrgVdcIDArray.Add($RecoveryOrgVdcID)
                        $VPGOrgVdcNetworksURL = $baseURL+"virtualizationsites/$RecoverySiteID/orgvdcs/$RecoveryOrgVdcID/networks"
                        Write-Host "networks, " -NoNewline -ForegroundColor Cyan
                        $NetworksBySiteId.$RecoveryOrgVdcId = Invoke-RestWrapper -Core $TurboCore -Method Get -Uri $VPGOrgVdcNetworksURL -ContentType $Type -Headers $ZertoSessionHeader   
                        $VPGOrgVdcStoragePoliciesURL = $baseURL+"virtualizationsites/$RecoverySiteID/orgvdcs/$RecoveryOrgVdcID/storagepolicies"
                        Write-Host "storage profiles." -ForegroundColor Cyan
                        $StorageBySiteId.$RecoveryOrgVdcId = Invoke-RestWrapper -Core $TurboCore -Method Get -Uri $VPGOrgVdcStoragePoliciesURL -ContentType $Type -Headers $ZertoSessionHeader   
                    }
                    $VPGDefaultRecoveryOrgVdcNetworkFailoverID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $VPG.VCDNetworkDefaultFailover}  | select -ExpandProperty NetworkIdentifier
                    $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $VPG.VCDNetworkDefaultFailoverTest}  | select -ExpandProperty NetworkIdentifier
                    # Discover network identifiers
                    $VPGSettings.Networks.Failover.VCD.DefaultRecoveryOrgVdcNetworkIdentifier = $VPGDefaultRecoveryOrgVdcNetworkFailoverID
                    $VPGSettings.Networks.FailoverTest.VCD.DefaultRecoveryOrgVdcNetworkIdentifier = $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID
                    if (($null -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverID) -or ($null -eq $VPGDefaultRecoveryOrgVdcNetworkFailoverTestID))
                    {
                        Write-Host "Default network not found!  Skipping VPG: $($VPG.VPGName)" -ForegroundColor Red
                        Write-Host "NetworkDefaultFailoverName: $($VPG.VCDNetworkDefaultFailover)"
                        Write-Host "NetworkDefaultFailoverTestName: $($VPG.VCDNetworkDefaultFailoverTest)"
                        Write-Host "Valid OrgVDC Networks:"
                        $NetworksBySiteId.$RecoveryOrgVdcId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                        continue
                    }
                }
                else
                {
                    Write-Host "Recovery site is vCenter"
                    if (-not ($VPGRecoverySiteArray.Contains($RecoverySiteID)))
                    {
                        Write-Host "Discovering new recovery site " -NoNewline -ForegroundColor Cyan
                        $null = $VPGRecoverySiteArray.Add($RecoverySiteID)
                        $DatastoresURL = $BaseURL+"virtualizationsites/$RecoverySiteID/datastores"
                        Write-Host "datastores, " -NoNewline -ForegroundColor Cyan
                        $StorageBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $DatastoresURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                        $FoldersURL = $BaseURL+"virtualizationsites/$RecoverySiteID/folders"
                        Write-Host "folders, " -NoNewline -ForegroundColor Cyan
                        $FoldersBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $FoldersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                        $HostclustersURL = $BaseURL+"virtualizationsites/$RecoverySiteID/hostclusters"
                        Write-Host "clusters, " -NoNewline -ForegroundColor Cyan
                        $HostclustersBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $HostclustersURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                        $HostsURL = $BaseURL+"virtualizationsites/$RecoverySiteID/hosts"
                        Write-Host "hosts, " -NoNewline -ForegroundColor Cyan
                        $HostsBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $HostsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                        $ResourcePoolsURL = $BaseURL+"virtualizationsites/$RecoverySiteID/resourcepools"
                        Write-Host "resource pools, " -NoNewline -ForegroundColor Cyan
                        $ResourcePoolsBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $ResourcePoolsURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
                        $VPGPortGroupsURL = $baseURL+"virtualizationsites/$RecoverySiteID/networks"
                        Write-Host "networks." -ForegroundColor Cyan
                        $NetworksBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $TurboCore -Uri $VPGPortGroupsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader   
                    }
                    # Discover vcenter object identifiers
                    $VPGDefaultHostID = $HostsBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationHostName -eq $VPG.DefaultHost}  | select -ExpandProperty HostIdentifier
                    $VPGDefaultHostClusterID = $HostClustersBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationClusterName -eq $VPG.DefaultHostCluster}  | select -ExpandProperty ClusterIdentifier
                    $VPGDefaultFolderID = $FoldersBySiteId.$RecoverySiteId | Where-Object {$_.FolderName -eq $VPG.DefaultFolder}  | select -ExpandProperty FolderIdentifier
                    $VPGDefaultDatastoreID = $StorageBySiteId.$RecoverySiteId | Where-Object {$_.DatastoreName -eq $VPG.DefaultDatastore}  | select -ExpandProperty DatastoreIdentifier
                    $VPGDefaultResourcePoolID = $ResourcePoolsBySiteId.$RecoverySiteId | Where-Object {$_.ResourcepoolName -eq $VPG.DefaultResourcePool}  | select -ExpandProperty ResourcepoolIdentifier
                    $VPGNetworkDefaultFailoverID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $VPG.VcenterNetworkDefaultFailover}  | select -ExpandProperty NetworkIdentifier
                    $VPGNetworkDefaultFailoverTestID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $VPG.VcenterNetworkDefaultFailoverTest}  | select -ExpandProperty NetworkIdentifier
                    if (($null -eq $VPGNetworkDefaultFailoverID) -or ($null -eq $VPGNetworkDefaultFailoverTestID))
                    {
                        Write-Host "Default network not found!  Skipping VPG: $($VPG.VPGName)" -ForegroundColor Red
                        Write-Host "NetworkDefaultFailoverName: $($VPG.VcenterNetworkDefaultFailover)"
                        Write-Host "NetworkDefaultFailoverTestName: $($VPG.VcenterNetworkDefaultFailoverTest)"
                        Write-Host "Valid port groups:"
                        $NetworksBySiteId.$RecoverySiteId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                        continue
                    }
                    $VPGSettings.Recovery.DefaultHostIdentifier = $VPGDefaultHostID
                    $VPGSettings.Recovery.DefaultHostClusterIdentifier = $VPGDefaultHostClusterID
                    $VPGSettings.Recovery.DefaultDatastoreIdentifier = $VPGDefaultDatastoreID
                    $VPGSettings.Recovery.DefaultFolderIdentifier = $VPGDefaultFolderID
                    $VPGSettings.Recovery.ResourcePoolIdentifier = $VPGDefaultResourcePoolID
                    $VPGSettings.Networks.Failover.Hypervisor.DefaultNetworkIdentifier = $VPGNetworkDefaultFailoverID
                    $VPGSettings.Networks.FailoverTest.Hypervisor.DefaultNetworkIdentifier = $VPGNetworkDefaultFailoverTestID
                }
            }
            # Compare objects by breaking them back into JSON, split by lines, and trim whitespace for output formatting
            $Comparison = Compare-Object (($OriginalVPGSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$') `
                                         (($VPGSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$')
            if ($null -ne $Comparison)
            {
                Write-Host ($Comparison | Select-Object @{E={$_.InputObject};N='RequestedChanges'} | Format-Table | Out-String)
                $VPGSettingsJSON = $VPGSettings | ConvertTo-Json -Depth 10
                $null = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsURL -Method Put -Body $VPGSettingsJSON -ContentType $Type -Headers $ZertoSessionHeader 
                $CommitVPGSettingURL = $BaseURL + "vpgSettings/$VPGSettingsID/commit"
                $null = Invoke-RestWrapper -Core $TurboCore -Uri $CommitVPGSettingURL -Method Post -ContentType $Type -Headers $ZertoSessionHeader 
                if ($?) {Write-Host "Update for $VPGID completed" -ForegroundColor Green} else {Write-Host "Update failed" -ForegroundColor Red; continue}            
                Start-Sleep -Seconds 2
            }
            else
            {
                Write-Host "No changes requested." -ForegroundColor Green
            }
        }
        Write-Host "Finished all edits" -ForegroundColor Green
    }
}

Set-Alias -Name izset9 -Value Import-ZertoVPGSettings9
#>
<#
.SYNOPSIS
    Retrieves and exports network settings for VPGs from a Zerto Virtual Manager (ZVM) v9.7 and below.

.DESCRIPTION
    This function connects to a Zerto Virtual Manager (ZVM) and retrieves network settings for Virtual Protection Groups (VPGs) based on specified criteria. The retrieved network settings are exported to a CSV file for further analysis.

.PARAMETER ZVM
    The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER Credentials
    The credentials to connect to the Zerto Virtual Manager. 

.PARAMETER RecoveryVPGType
    The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER Zorg
    The Zorg identifier of the customer to check network settings for.

.PARAMETER VPGName
    The name of the VPG to filter the results.

.PARAMETER RecoverySite
    The name of the recovery site to filter the results.

.PARAMETER ProtectedSite
    The name of the protected site to filter the results.

.PARAMETER ProtectedVPGType
    The type of protected VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ExportPath
    The directory path where the CSV file will be exported. Default is "~/ZertoScripts".

.PARAMETER Port
    The port to connect to the ZVM. Default is 443.

.EXAMPLE
    # Get network settings for all VPGs in a specific site and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter"

.EXAMPLE
    # Get network settings for a specific customer and export to a specified path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "VCD" -Zorg "CustomerZorg" -ExportPath "C:\Exports"

.EXAMPLE
    # Get network settings for a specific VPG and export to the default path.
    Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter" -VPGName "VPG1"

#>
<#function Export-ZertoVPGNetworkSettings9 { 

    [CmdletBinding()]
    param(
        [Parameter(Mandatory,HelpMessage='Enter ZVM hostname without the port here eg. "zerto-lab.lab.tierpoint.com"')]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter(Mandatory,HelpMessage='Specify "vCenter" or "VCD" for VPG type')]
        [ValidateSet("vCenter","VCD")]
        [string]$RecoveryVPGType,
        [Parameter()]
        [string]$Zorg,
        [Parameter()]
        [string]$VPGName,
        [Parameter()]
        [string]$RecoverySite,
        [Parameter()]
        [string]$ProtectedSite,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$ProtectedVPGType,
        [Parameter()]
        [ValidateScript({
                if (!($_ | Test-Path -PathType Container))
                {
                    throw "The path argument must be a directory not a file"
                }
                return $true
            })]
        [string]$ExportPath="~/ZertoScripts",
        [Parameter()]
        [string]$Port="9669",
        [Parameter()]
        [switch]$ProtectedVMList
    )

    # Parameter work
    if (-not (Test-Path $ExportPath))
    {
        $ExportPath = New-Item $ExportPath -ItemType Directory
    }

    $typeHash = @{
        vCenter = "0"
        VCD     = "2"
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'recoveryvpgtype')))
    {
        $RecoverySiteType = $typeHash[$RecoveryVpgType]
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedvpgtype')))
    {
        $ProtectedSiteType = $typeHash[$ProtectedVpgType]
    }
    if ($RecoveryVPGType -eq "VCD") {$vCloud = $true} else {$vCloud = $false}

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref

    Function Invoke-WebWrapper($Core,$Uri,$Method,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            if ([string]$_.Exception.Response.StatusCode.value__ -eq "401")
            {
                throw("Unauthorized, Invalid credentials")
            }
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    Function Invoke-RestWrapper($Core,$Uri,$Method,$Body,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    if ($PSVersionTable.PSVersion.Major -gt 6) {$TurboCore = $true} else {$TurboCore = $false}
    if (-not $TurboCore)
    {
        try
        {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        catch
        {
            Write-Host "Already ignoring SSL cert errors"
        }
    }

    $ZertoUser = $Credentials.UserName
    $ZertoPassword = $Credentials.GetNetworkCredential().Password
    $BaseURL = "https://" + $ZVM + ":" + "$Port" + "/v1/"
    $GUIBaseURL = "https://" + $ZVM + ":" + "$Port" + "/GuiServices/v1/VisualQueryProvider/"
    $ZertoSessionURL = $BaseURL + "session/add"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoUser+":"+$ZertoPassword))}
    $Type = "application/json"

    # Auth
    $ZertoSessionResponse = Invoke-WebWrapper -Core $TurboCore -Uri $ZertoSessionURL -Method Post -Headers $Header -ContentType $Type 
    if ($ZertoSessionResponse.StatusCode -eq 401)
    {
        throw('401 Not Authorized.  Please check your credentials and try again')
    }
    $ZertoSession = $ZertoSessionResponse.headers.get_item("x-zerto-session")
    $ZertoSessionHeader = @{"Accept" ="application/json"
        "x-zerto-session"            ="$ZertoSession"
    }
    $DSRemoteSession = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoSession))
    $GUISessionHeader = @{"Accept" ="application/json"
        DSRemoteCredentials        = $DSRemoteSession
    }
    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')) -or ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
    {
        $VirtualizationSitesURL = $BaseURL+"virtualizationsites"
        $VirtualizationSiteList = Invoke-RestWrapper -Core $TurboCore -Uri $VirtualizationSitesURL -Method Get -TimeoutSec 100 -Headers $ZertoSessionHeader -ContentType $Type 
        # Only set requested values
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite'))
        {
            $ProtectedSiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $ProtectedSite}  | select -ExpandProperty SiteIdentifier
        }
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite'))
        {
            $RecoverySiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $RecoverySite}  | select -ExpandProperty SiteIdentifier
        } 
        # If values are not found warn user
        if (($null -eq $RecoverySiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
        {
            Write-Host "Could not find site information for $RecoverySite" -ForegroundColor Red
        }
        if (($null -eq $ProtectedSiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')))
        {
            Write-Host "Could not find site information for $ProtectedSite" -ForegroundColor Red
            $protectedsite 
        }
    }
    # Get Zorgs if requested
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'zorg')))
    {
        $ZorgURL = $BaseURL+"zorgs"
        $ZorgList = Invoke-RestWrapper -Core $TurboCore -Uri $ZorgURL -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
        $ZorgIdentifier = $ZorgList | Where-Object {$_.ZorgName -eq $Zorg} | select -ExpandProperty ZorgIdentifier
    }

    #Array lists fast
    $VPGRecoverySiteArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoveryOrgVDCArray = New-Object -TypeName "System.Collections.ArrayList"
    $VMNICArrayList = New-Object -TypeName "System.Collections.ArrayList"

    # Doing filter in the URL to lighten load on ZVM, but since it doesnt support wildcards, we omit VPGName and sort that later
    # Then make sure its encoded properly since users might enter shenanigans
    $VPGListUrl = $BaseURL+"vpgs?zorgIdentifier=$ZorgIdentifier&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=" +
        "$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    # Without this add-type PowerShell 5 will bomb
    Add-Type -AssemblyName System.Web
    $EncodedVPGListUrl = [System.Web.HttpUtility]::UrlPathEncode($VPGListUrl)
    Write-Host "Filtering VPGS: $EncodedVPGListUrl"
    $VPGList = Invoke-RestWrapper -Core $TurboCore -Uri $EncodedVPGListUrl -Method Get -Headers $ZertoSessionHeader -ContentType $Type 
    if ([bool]($MyInvocation.BoundParameters.Keys -match 'vpgname'))
    {
        $VPGList = $VPGList | Where-Object {$_.vpgName -like "*${VPGName}*"}
    }
    if ($null -ne $VPGList.count)
    {
        Write-Host "Found $($VPGList.count) VPGs to process" -ForegroundColor Yellow
    }    
    # Getting list of VMs filtered by Zorg (orgname is undocumented filter?)
    $VMListUrl = $BaseURL+"vms?orgname=$Zorg&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=" +
        "$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    $EncodedVMListUrl = [System.Web.HttpUtility]::UrlPathEncode($VMListUrl)
    Write-Host "Filtering VMS: $EncodedVMListUrl"
    $VMList = Invoke-RestWrapper -Core $TurboCore -Uri $EncodedVMListUrl -Method Get -Headers $ZertoSessionHeader -ContentType $Type  
    Write-Host "Found $($VMList.count) VMs to process" -ForegroundColor Yellow
    Write-Host "Counting VPGSettings Objects"
    $VPGSettingsObjectsURL = $BaseURL+"vpgSettings"
    $VPGSettingsObjects = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsObjectsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader
    $VPGSettingsObjectCount = $VPGSettingsObjects.count
    if ($VPGSettingsObjectCount -ge 99)
    {
        For($i = 0; $i -lt 5; $i++)
        {
            Write-Host "There are $VPGSettingsObjectCount VPG Settings ojects. Deleting VPGSettings objects." -ForegroundColor Red
            $VPGSettingsObjectID = $VPGSettingsObjects[$i].vpgsettingsidentifier
            $deleteVpgSettingsObjectURL = $VPGSettingsObjectsURL+"/"+$VPGSettingsObjectID
            $null = Invoke-RestWrapper -Core $TurboCore -Uri $deleteVpgSettingsObjectURL -Method delete -ContentType $Type -Headers $ZertoSessionHeader 
            $VPGSettingsObjects = Invoke-RestWrapper -Core $TurboCore -Uri $VPGSettingsObjectsURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader
            $VPGSettingsObjectCount = $VPGSettingsObjects.count
        } 
    }    


    ForEach ($VPG in $VPGList)
    {
        $VPGID = $VPG.VpgIdentifier
        $VPGName = $VPG.VpgName
        $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
        Write-Host "Starting $VPGName" -ForegroundColor Yellow
        # Posting the VPG JSON Request to the API to get a settings ID (like clicking edit on a VPG in the GUI)
        $EditVPGURL = $BaseURL+"vpgSettings"
        $VPGSettingsID = Invoke-RestWrapper -Core $TurboCore -Uri $EditVPGURL -Method Post -Body $VPGJSON -ContentType $Type -Headers $ZertoSessionHeader   
        if ($VPGSettingsID -ne $null) {$ValidVPGSettingsID = $true} 
        #else {
            #$ValidVPGSettingsID = $false
            #Zerto holds a max of 100 vpgSettings objects. Checking for that here and prompting user to delete vpgSettings objects.
            #$VPGSettingsObjects = Invoke-RestWrapper -Core $TurboCore -Uri $EditVPGURL -Method Get -ContentType $Type -Headers $ZertoSessionHeader
            #$VPGSettingsObjectCount = $VPGSettingsObjects.count
            #Write-Host "Zerto holds a maximum of 101 vpg settings objects. 
         
            #}


        # Getting VPG settings from API
        # Skipping if unable to obtain valid VPG setting identifier
        if ($ValidVPGSettingsID)
        {
            # Getting VPG settings
            $VPGSettingsURL = $BaseURL+"vpgSettings/"+$VPGSettingsID
            $VPGSettings = Invoke-RestWrapper -Core $TurboCore -Method Get -Uri $VPGSettingsURL -ContentType $Type -Headers $ZertoSessionHeader   
            $VPGVMs = $VPGSettings.VMs
            $VPGRecoverySiteID = $VPGSettings.Basic.RecoverySiteIdentifier
            # Discover if new site and do VCD/vcenter only actions here
            if ($vCloud)
            {
                $VPGRecoveryOrgVDC = $VPGSettings.Recovery.VCD.OrgVdcIdentifier
                if (-not ($VPGRecoveryOrgVDCArray.Contains($VPGRecoveryOrgVDC)))
                {
                    Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoveryOrgVDCArray.Add($VPGRecoveryOrgVDC)
                    $VPGOrgVdcNetworksURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/networks"
                    Write-Host "networks." -ForegroundColor Cyan
                    $OrgVdcNetworkList += Invoke-RestWrapper -Core $TurboCore -Method Get -Uri $VPGOrgVdcNetworksURL -ContentType $Type -Headers $ZertoSessionHeader   
                }
            }
            else
            {
                if (-not ($VPGRecoverySiteArray.Contains($VPGRecoverySiteID)))
                {
                    Write-Host "Discovering new vCenter " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoverySiteArray.Add($VPGRecoverySiteID)
                    $VPGPortGroupsURL = $baseURL+"virtualizationsites/$VPGRecoverySiteID/networks"
                    Write-Host "networks." -ForegroundColor Cyan
                    $PortGroupList += Invoke-RestWrapper -Core $TurboCore -Method Get -Uri $VPGPortGroupsURL -ContentType $Type -Headers $ZertoSessionHeader   
                }
            }
            ForEach ($VM in $VPGVMs)
            {
                $VMID = $VM.VmIdentifier
                $VMName = $VMList | Where-Object {$_.VMIdentifier -eq $VMID} | select -ExpandProperty VMName
                $VMNICs = $VM.Nics
                if ($VMNICs.Count -lt 1)
                {
                    Write-Host "No NICS on $VPGName!" -ForegroundColor Red
                    continue
                }
                ForEach ($NIC in $VMNICs)
                {
                    $VMNICID = $NIC.NicIdentifier
                    if ($vCloud)
                    {
                        $Failover = $NIC.Failover.VCD
                        $FailoverTest = $NIC.FailoverTest.VCD
                        $VCDGuestCustomization = $VPGSettings.Networks.Failover.VCD.IsEnableGuestCustomization
                        $FailoverNetworkName = $OrgVdcNetworkList | Where-Object {$_.NetworkIdentifier -eq $Failover.RecoveryOrgVdcNetworkIdentifier} | 
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $FailoverTestNetworkName = $OrgVdcNetworkList | Where-Object {$_.NetworkIdentifier -eq $FailoverTest.RecoveryOrgVdcNetworkIdentifier} | 
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        if ($ProtectedVMList) {
                            $CSVLine  = [ordered]@{
                            BootGroup                     = $null
                            VMName                        = $VMName
                            VPGName                       = $VPGName
                            ProductionIPs                 = $null
                            PublicDRNATs                  = $null
                            FailoverNetworkName           = $FailoverNetworkName
                            FailoverStaticIp              = $Failover.IpAddress
                            FailoverTestNetworkName       = $FailoverTestNetworkName
                            FailoverTestStaticIp          = $FailoverTest.IpAddress
                            RPO                           = $null
                            JournalHardLimit              = $null
                            AlwaysonAvailibilityGroup     = $null
                            SpecialStorageProvisioning    = $null
                            CaseNumberOrPINumber          = $null
                            DateAddedRemoved              = $null
                            NotesDontCopyThisColumn       = $null
                            FailoverIpMode                = $Failover.IpMode                        
                            FailoverIsResetMacAddress     = $Failover.IsResetMacAddress
                            FailoverIsPrimary             = $Failover.IsPrimary
                            FailoverIsConnected           = $Failover.IsConnected                        
                            FailoverTestIpMode            = $FailoverTest.IpMode                        
                            FailoverTestIsResetMacAddress = $FailoverTest.IsResetMacAddress
                            FailoverTestIsPrimary         = $FailoverTest.IsPrimary
                            FailoverTestIsConnected       = $FailoverTest.IsConnected
                            VPGID                         = $VPGID
                            VMID                          = $VMID
                            IsVcloud                      = $true
                            RecoverySiteID                = $VPGRecoverySiteID
                            RecoveryOrgVdcID              = $VPGRecoveryOrgVDC
                            }
                        } else {
                            $CSVLine  = [ordered]@{
                                VPGName                       = $VPGName
                                VMName                        = $VMName
                                NICID                         = $VMNICID
                                vCDGuestCustomization         = $VCDGuestCustomization
                                FailoverNetworkName           = $FailoverNetworkName
                                FailoverIpMode                = $Failover.IpMode
                                FailoverStaticIp              = $Failover.IpAddress
                                FailoverIsResetMacAddress     = $Failover.IsResetMacAddress
                                FailoverIsPrimary             = $Failover.IsPrimary
                                FailoverIsConnected           = $Failover.IsConnected
                                FailoverTestNetworkName       = $FailoverTestNetworkName
                                FailoverTestIpMode            = $FailoverTest.IpMode
                                FailoverTestStaticIp          = $FailoverTest.IpAddress
                                FailoverTestIsResetMacAddress = $FailoverTest.IsResetMacAddress
                                FailoverTestIsPrimary         = $FailoverTest.IsPrimary
                                FailoverTestIsConnected       = $FailoverTest.IsConnected
                                VPGID                         = $VPGID
                                VMID                          = $VMID
                                IsVcloud                      = $true
                                RecoverySiteID                = $VPGRecoverySiteID
                                RecoveryOrgVdcID              = $VPGRecoveryOrgVDC
                                }
                            }
                        $null = $VMNICArrayList.Add((New-Object PSObject -Property $CSVLine))
                    }
                    else
                    {
                        $Failover = $NIC.Failover.Hypervisor
                        $FailoverTest = $NIC.FailoverTest.Hypervisor
                        $FailoverNetworkName = $PortGroupList | Where-Object {$_.NetworkIdentifier -eq $Failover.NetworkIdentifier} |
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $FailoverTestNetworkName = $PortGroupList | Where-Object {$_.NetworkIdentifier -eq $FailoverTest.NetworkIdentifier} |
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $CSVLine  = [ordered]@{
                            VPGName                             = $VPGName
                            VMName                              = $VMName
                            NICID                               = $VMNICID
                            FailoverNetworkName                 = $FailoverNetworkName
                            FailoverIsDHCP                      = $Failover.IpConfig.IsDHCP
                            FailoverStaticIp                    = $Failover.IpConfig.StaticIp
                            FailoverSubnetMask                  = $Failover.IpConfig.SubnetMask
                            FailoverGateway                     = $Failover.IpConfig.Gateway
                            FailoverPrimaryDns                  = $Failover.IpConfig.PrimaryDns
                            FailoverSecondaryDns                = $Failover.IpConfig.SecondaryDns
                            FailoverDNSSuffix                   = $Failover.DnsSuffix
                            FailoverShouldReplaceMacAddress     = $Failover.ShouldReplaceMacAddress
                            FailoverTestNetworkName             = $FailoverTestNetworkName
                            FailoverTestIsDHCP                  = $FailoverTest.IpConfig.IsDHCP
                            FailoverTestStaticIp                = $FailoverTest.IpConfig.StaticIp
                            FailoverTestSubnetMask              = $FailoverTest.IpConfig.SubnetMask
                            FailoverTestGateway                 = $FailoverTest.IpConfig.Gateway
                            FailoverTestPrimaryDns              = $FailoverTest.IpConfig.PrimaryDns
                            FailoverTestSecondaryDns            = $FailoverTest.IpConfig.SecondaryDns
                            FailoverTestDNSSuffix               = $FailoverTest.DnsSuffix           
                            FailoverTestShouldReplaceMacAddress = $FailoverTest.ShouldReplaceMacAddress
                            VPGID                               = $VPGID
                            VMID                                = $VMID
                            isVcloud                            = $false
                            RecoverySiteID                      = $VPGRecoverySiteID
                        }
                        $null = $VMNICArrayList.Add((New-Object PSObject -Property $CSVLine))
                    }
                    #Eliminate any possibility of carry over on our lookups 
                    $FailoverNetworkName = $null
                    $FailoverTestNetworkName = $null
                }
            }
            # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
            $null = Invoke-RestWrapper -Core $TurboCore -Method Delete -Uri $VPGSettingsURL -TimeoutSec 100 -ContentType $Type -Headers $ZertoSessionHeader
            Write-Host "Finished $VPGName" -ForegroundColor Green
        }
    }
    Write-Host "All done!" -ForegroundColor Green
    # Exporting to CSV
    $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmm) + "-$ZVM-NICs$(if ($Zorg){$Zorg}).csv"
    try
    {
        $VMNICArrayList | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
        if (Test-Path -Path $CSVExportFile -PathType Leaf)
        {
            Write-Host "`nCopy/Paste next line to open CSV:" -ForegroundColor Green
            Write-Host ". $CSVExportFile `n" 
        }
        else
        {
            Write-Host "Unknown error, could not create CSV.  Check path $CSVExportFile" -ForegroundColor Red
        }
    }
    catch [System.IO.IOException]
    {
        #If we wait a minute, a new name will be generated.
        Write-Host "$CSVExportFile is already open.  Adding seconds to name" -ForegroundColor Yellow
        Start-Sleep -Seconds 60
        $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmmss) + "-$ZVM-NICs$(if ($Zorg){$Zorg}).csv"
        $VMNICArrayList | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
    }
    catch
    {
        Write-Host $_ | Out-String
    }
}
Set-Alias -Name znic9 -Value Export-ZertoVPGNetworkSettings9
#>
<#
.SYNOPSIS
  Retrieves and exports network settings for VPGs from a Zerto Virtual Manager (ZVM) v10.0 and up.

.DESCRIPTION
  This function connects to a Zerto Virtual Manager (ZVM) and retrieves network settings for Virtual Protection Groups (VPGs) based on specified criteria. The retrieved network settings are exported to a CSV file for further analysis.

.PARAMETER ZVM
  The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER Credentials
  The credentials to connect to the Zerto Virtual Manager. 

.PARAMETER RecoveryVPGType
  The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER Zorg
  The Zorg identifier of the customer to check network settings for.

.PARAMETER VPGName
  The name of the VPG to filter the results.

.PARAMETER RecoverySite
  The name of the recovery site to filter the results.

.PARAMETER ProtectedSite
  The name of the protected site to filter the results.

.PARAMETER ProtectedVPGType
  The type of protected VPG. Valid values are "vCenter" or "VCD".

.PARAMETER ExportPath
  The directory path where the CSV file will be exported. Default is "~/ZertoScripts".

.PARAMETER Port
  The port to connect to the ZVM. Default is 443.

.EXAMPLE
   # Get network settings for all VPGs in a specific site and export to the default path.
   Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter"

.EXAMPLE
   # Get network settings for a specific customer and export to a specified path.
   Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "VCD" -Zorg "CustomerZorg" -ExportPath "C:\Exports"

.EXAMPLE
   # Get network settings for a specific VPG and export to the default path.
   Export-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -RecoveryVPGType "vCenter" -VPGName "VPG1"

#>

<#function Export-ZertoVPGNetworkSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,HelpMessage='Enter ZVM hostname without the port here eg. "zerto-lab.lab.zerto.com"')]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter(Mandatory,HelpMessage='Specify "vCenter" or "VCD" for VPG type')]
        [ValidateSet("vCenter","VCD")]
        [string]$RecoveryVPGType,
        [Parameter()]
        [string]$Zorg,
        [Parameter()]
        [string]$VPGName,
        [Parameter()]
        [string]$RecoverySite,
        [Parameter()]
        [string]$ProtectedSite,
        [Parameter()]
        [ValidateSet("vCenter","VCD")]
        [string]$ProtectedVPGType,
        [Parameter()]
        [ValidateScript({
                if (!($_ | Test-Path -PathType Container))
                {
                    throw "The path argument must be a directory not a file"
                }
                return $true
            })]
        [string]$ExportPath="~/ZertoScripts",
        [Parameter()]
        [string]$Port="443",
        [Parameter()]
        [switch]$ProtectedVMList
    )

    # Parameter work
    if (-not (Test-Path $ExportPath))
    {
        $ExportPath = New-Item $ExportPath -ItemType Directory
    }

    $typeHash = @{
        vCenter = "0"
        VCD     = "2"
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'recoveryvpgtype')))
    {
        $RecoverySiteType = $typeHash[$RecoveryVpgType]
    }
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedvpgtype')))
    {
        $ProtectedSiteType = $typeHash[$ProtectedVpgType]
    }
    if ($RecoveryVPGType -eq "VCD") {$vCloud = $true} else {$vCloud = $false}

    if (-not ([bool]($MyInvocation.BoundParameters.Keys -match 'credentials')))
    {
        $Credentials = Get-Credential -Message "Enter your Password for $ZVM" -UserName "cloud\"
    }
    $defaultProgPref = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    if (-not ($null = Test-NetConnection $ZVM -Port $Port -InformationLevel Quiet))
    {
        throw("Could not connect to $ZVM on port $Port")
    }
    $Global:ProgressPreference = $defaultProgPref

    
    # Auth
    if((get-module -name zertoapiwrapper).version.Major -eq 1)
    {
        #This required some changes to due to dependency conflicts (Changed function name in psm1 file and in psd1 file for version 1.4.2)
        Connect-ZertoServerUnder10 -Server $ZVM -credential $Credentials
    } else {
        Connect-ZertoServer -Server $ZVM -credential $Credentials -AutoReconnect
    }

    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    if (([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')) -or ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
    {
        $VirtualizationSiteList = Get-ZertoVirtualizationSite
        # Only set requested values
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite'))
        {
            $ProtectedSiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $ProtectedSite}  | select -ExpandProperty SiteIdentifier
        }
        if ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite'))
        {
            $RecoverySiteIdentifier = $VirtualizationSiteList | Where-Object {$_.VirtualizationSiteName -eq $RecoverySite}  | select -ExpandProperty SiteIdentifier
        } 
        # If values are not found warn user
        if (($null -eq $RecoverySiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'recoverysite')))
        {
            Write-Host "Could not find site information for $RecoverySite" -ForegroundColor Red
        }
        if (($null -eq $ProtectedSiteIdentifier) -and ([bool]($MyInvocation.BoundParameters.Keys -match 'protectedsite')))
        {
            Write-Host "Could not find site information for $ProtectedSite" -ForegroundColor Red
            $protectedsite 
        }
    }
    # Get Zorgs if requested
    if (([bool]($MyInvocation.BoundParameters.Keys -match 'zorg')))
    {
        $ZorgList = Get-ZertoZorg
        $ZorgIdentifier = $ZorgList | Where-Object {$_.ZorgName -eq $Zorg} | select -ExpandProperty ZorgIdentifier
    }

    #Array lists fast
    $VPGRecoverySiteArray = New-Object -TypeName "System.Collections.ArrayList"
    $VPGRecoveryOrgVDCArray = New-Object -TypeName "System.Collections.ArrayList"
    $VMNICArrayList = New-Object -TypeName "System.Collections.ArrayList"

    # Doing filter in the URL to lighten load on ZVM, but since it doesnt support wildcards, we omit VPGName and sort that later
    # Then make sure its encoded properly since users might enter shenanigans
    $VPGListUrl = "vpgs?zorgIdentifier=$ZorgIdentifier&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    Write-Host "Filtering VPGS: $VPGListUrl"
    $VPGList = Invoke-ZertoRestRequest -Uri $VPGListUrl -Method Get
    if ([bool]($MyInvocation.BoundParameters.Keys -match 'vpgname'))
    {
        $VPGList = $VPGList | Where-Object {$_.vpgName -like "*${VPGName}*"}
    }
    if ($null -ne $VPGList.count)
    {
        Write-Host "Found $($VPGList.count) VPGs to process" -ForegroundColor Yellow
    }    
    # Getting list of VMs filtered by Zorg (orgname is undocumented filter?)
    $VMListUrl = "vms?orgname=$Zorg&protectedSiteIdentifier=$ProtectedSiteIdentifier&recoverySiteIdentifier=$RecoverySiteIdentifier&recoverySiteType=$RecoverySiteType&protectedSiteType=$ProtectedSiteType"
    Write-Host "Filtering VMS: $VMListUrl"
    $VMList = Invoke-ZertoRestRequest -Uri $VMListUrl -Method Get
    Write-Host "Found $($VMList.count) VMs to process" -ForegroundColor Yellow
    Write-Host "Counting VPGSettings Objects"
    $VPGSettingsObjects = Get-ZertoVpgSetting
    $VPGSettingsObjectCount = $VPGSettingsObjects.count
    if ($VPGSettingsObjectCount -ge 99)
    {
        For($i = 0; $i -lt 10; $i++)
        {
            Write-Host "There are $VPGSettingsObjectCount VPG Settings ojects. Deleting VPGSettings objects." -ForegroundColor Red
            $VPGSettingsObjectID = $VPGSettingsObjects[$i].vpgsettingsidentifier
            $null = Remove-ZertoVpgSettingsIdentifier -vpgSettingsIdentifier $VPGSettingsObjectID 
            $VPGSettingsObjects = Get-ZertoVpgSetting
            $VPGSettingsObjectCount = $VPGSettingsObjects.count
        } 
    }    


    ForEach ($VPG in $VPGList)
    {
        $VPGID = $VPG.VpgIdentifier
        $VPGName = $VPG.VpgName
        $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
        Write-Host "Starting $VPGName" -ForegroundColor Yellow
        # Posting the VPG JSON Request to the API to get a settings ID (like clicking edit on a VPG in the GUI)
        $EditVPGURL = "vpgSettings"
        $VPGSettingsID = Invoke-ZertoRestRequest -Uri $EditVPGURL -Method Post -Body $VPGJSON   
        if ($VPGSettingsID -ne $null) {$ValidVPGSettingsID = $true} 
        # Getting VPG settings from API
        # Skipping if unable to obtain valid VPG setting identifier
        if ($ValidVPGSettingsID)
        {
            # Getting VPG settings
            $VPGSettingsURL = "vpgSettings/"+$VPGSettingsID
            $VPGSettings = Invoke-ZertoRestRequest -Method Get -Uri $VPGSettingsURL   
            $VPGVMs = $VPGSettings.VMs
            $VPGRecoverySiteID = $VPGSettings.Basic.RecoverySiteIdentifier
            # Discover if new site and do VCD/vcenter only actions here
            if ($vCloud)
            {
                $VPGRecoveryOrgVDC = $VPGSettings.Recovery.VCD.OrgVdcIdentifier
                if (-not ($VPGRecoveryOrgVDCArray.Contains($VPGRecoveryOrgVDC)))
                {
                    Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoveryOrgVDCArray.Add($VPGRecoveryOrgVDC)
                    $VPGOrgVdcNetworksURL = "virtualizationsites/$VPGRecoverySiteID/orgvdcs/$VPGRecoveryOrgVDC/networks"
                    Write-Host "networks." -ForegroundColor Cyan
                    $OrgVdcNetworkList += Invoke-ZertoRestRequest -Method Get -Uri $VPGOrgVdcNetworksURL
                }
            }
            else
            {
                if (-not ($VPGRecoverySiteArray.Contains($VPGRecoverySiteID)))
                {
                    Write-Host "Discovering new vCenter " -NoNewline -ForegroundColor Cyan
                    $null = $VPGRecoverySiteArray.Add($VPGRecoverySiteID)
                    $VPGPortGroupsURL = "virtualizationsites/$VPGRecoverySiteID/networks"
                    Write-Host "networks." -ForegroundColor Cyan
                    $PortGroupList += Invoke-ZertoRestRequest -Method Get -Uri $VPGPortGroupsURL   
                }
            }
            ForEach ($VM in $VPGVMs)
            {
                $VMID = $VM.VmIdentifier
                $VMName = $VMList | Where-Object {$_.VMIdentifier -eq $VMID} | select -ExpandProperty VMName
                $VMNICs = $VM.Nics
                if ($VMNICs.Count -lt 1)
                {
                    Write-Host "No NICS on $VPGName!" -ForegroundColor Red
                    continue
                }
                ForEach ($NIC in $VMNICs)
                {
                    $VMNICID = $NIC.NicIdentifier
                    if ($vCloud)
                    {
                        $Failover = $NIC.Failover.VCD
                        $FailoverTest = $NIC.FailoverTest.VCD
                        $VCDGuestCustomization = $VPGSettings.Networks.Failover.VCD.IsEnableGuestCustomization
                        $FailoverNetworkName = $OrgVdcNetworkList | Where-Object {$_.NetworkIdentifier -eq $Failover.RecoveryOrgVdcNetworkIdentifier} | 
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $FailoverTestNetworkName = $OrgVdcNetworkList | Where-Object {$_.NetworkIdentifier -eq $FailoverTest.RecoveryOrgVdcNetworkIdentifier} | 
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        if ($ProtectedVMList) {
                            $CSVLine  = [ordered]@{
                            BootGroup                     = $null
                            VMName                        = $VMName
                            VPGName                       = $VPGName
                            ProductionIPs                 = $null
                            PublicDRNATs                  = $null
                            FailoverNetworkName           = $FailoverNetworkName
                            FailoverStaticIp              = $Failover.IpAddress
                            FailoverTestNetworkName       = $FailoverTestNetworkName
                            FailoverTestStaticIp          = $FailoverTest.IpAddress
                            RPO                           = $null
                            JournalHardLimit              = $null
                            AlwaysonAvailibilityGroup     = $null
                            SpecialStorageProvisioning    = $null
                            CaseNumberOrPINumber          = $null
                            DateAddedRemoved              = $null
                            NotesDontCopyThisColumn       = $null
                            FailoverIpMode                = $Failover.IpMode                        
                            FailoverIsResetMacAddress     = $Failover.IsResetMacAddress
                            FailoverIsPrimary             = $Failover.IsPrimary
                            FailoverIsConnected           = $Failover.IsConnected                        
                            FailoverTestIpMode            = $FailoverTest.IpMode                        
                            FailoverTestIsResetMacAddress = $FailoverTest.IsResetMacAddress
                            FailoverTestIsPrimary         = $FailoverTest.IsPrimary
                            FailoverTestIsConnected       = $FailoverTest.IsConnected
                            VPGID                         = $VPGID
                            VMID                          = $VMID
                            IsVcloud                      = $true
                            RecoverySiteID                = $VPGRecoverySiteID
                            RecoveryOrgVdcID              = $VPGRecoveryOrgVDC
                            }
                        } else {
                            $CSVLine  = [ordered]@{
                                VPGName                       = $VPGName
                                VMName                        = $VMName
                                NICID                         = $VMNICID
                                vCDGuestCustomization         = $VCDGuestCustomization
                                FailoverNetworkName           = $FailoverNetworkName
                                FailoverIpMode                = $Failover.IpMode
                                FailoverStaticIp              = $Failover.IpAddress
                                FailoverIsResetMacAddress     = $Failover.IsResetMacAddress
                                FailoverIsPrimary             = $Failover.IsPrimary
                                FailoverIsConnected           = $Failover.IsConnected
                                FailoverTestNetworkName       = $FailoverTestNetworkName
                                FailoverTestIpMode            = $FailoverTest.IpMode
                                FailoverTestStaticIp          = $FailoverTest.IpAddress
                                FailoverTestIsResetMacAddress = $FailoverTest.IsResetMacAddress
                                FailoverTestIsPrimary         = $FailoverTest.IsPrimary
                                FailoverTestIsConnected       = $FailoverTest.IsConnected
                                VPGID                         = $VPGID
                                VMID                          = $VMID
                                IsVcloud                      = $true
                                RecoverySiteID                = $VPGRecoverySiteID
                                RecoveryOrgVdcID              = $VPGRecoveryOrgVDC
                                }
                            }
                        $null = $VMNICArrayList.Add((New-Object PSObject -Property $CSVLine))
                    }
                    else
                    {
                        $Failover = $NIC.Failover.Hypervisor
                        $FailoverTest = $NIC.FailoverTest.Hypervisor
                        $FailoverNetworkName = $PortGroupList | Where-Object {$_.NetworkIdentifier -eq $Failover.NetworkIdentifier} |
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $FailoverTestNetworkName = $PortGroupList | Where-Object {$_.NetworkIdentifier -eq $FailoverTest.NetworkIdentifier} |
                        Select-Object -ExpandProperty VirtualizationNetworkName 
                        $CSVLine  = [ordered]@{
                            VPGName                             = $VPGName
                            VMName                              = $VMName
                            NICID                               = $VMNICID
                            FailoverNetworkName                 = $FailoverNetworkName
                            FailoverIsDHCP                      = $Failover.IpConfig.IsDHCP
                            FailoverStaticIp                    = $Failover.IpConfig.StaticIp
                            FailoverSubnetMask                  = $Failover.IpConfig.SubnetMask
                            FailoverGateway                     = $Failover.IpConfig.Gateway
                            FailoverPrimaryDns                  = $Failover.IpConfig.PrimaryDns
                            FailoverSecondaryDns                = $Failover.IpConfig.SecondaryDns
                            FailoverDNSSuffix                   = $Failover.DnsSuffix
                            FailoverShouldReplaceMacAddress     = $Failover.ShouldReplaceMacAddress
                            FailoverTestNetworkName             = $FailoverTestNetworkName
                            FailoverTestIsDHCP                  = $FailoverTest.IpConfig.IsDHCP
                            FailoverTestStaticIp                = $FailoverTest.IpConfig.StaticIp
                            FailoverTestSubnetMask              = $FailoverTest.IpConfig.SubnetMask
                            FailoverTestGateway                 = $FailoverTest.IpConfig.Gateway
                            FailoverTestPrimaryDns              = $FailoverTest.IpConfig.PrimaryDns
                            FailoverTestSecondaryDns            = $FailoverTest.IpConfig.SecondaryDns
                            FailoverTestDNSSuffix               = $FailoverTest.DnsSuffix           
                            FailoverTestShouldReplaceMacAddress = $FailoverTest.ShouldReplaceMacAddress
                            VPGID                               = $VPGID
                            VMID                                = $VMID
                            isVcloud                            = $false
                            RecoverySiteID                      = $VPGRecoverySiteID
                        }
                        $null = $VMNICArrayList.Add((New-Object PSObject -Property $CSVLine))
                    }
                    #Eliminate any possibility of carry over on our lookups 
                    $FailoverNetworkName = $null
                    $FailoverTestNetworkName = $null
                }
            }
            # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
            $null = Remove-ZertoVpgSettingsIdentifier -vpgSettingsIdentifier $VPGSettingsID
            Write-Host "Finished $VPGName" -ForegroundColor Green
        }
    }
    Write-Host "All done!" -ForegroundColor Green
    # Exporting to CSV
    $ZVM = ($ZVM.Trim("[]")) -replace ":", "."
    $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmm) + "-$ZVM-NICs$(if ($Zorg){$Zorg}).csv"
    try
    {
        $VMNICArrayList | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
        if (Test-Path -Path $CSVExportFile -PathType Leaf)
        {
            . $CSVExportFile 
        }
        else
        {
            Write-Host "Unknown error, could not create CSV.  Check path $CSVExportFile" -ForegroundColor Red
        }
    }
    catch [System.IO.IOException]
    {
        #If we wait a minute, a new name will be generated.
        Write-Host "$CSVExportFile is already open.  Adding seconds to name" -ForegroundColor Yellow
        Start-Sleep -Seconds 60
        $CSVExportFile = $ExportPath + "/" + (Get-Date -Format MM-dd-hhmmss) + "-$ZVM-NICs$(if ($Zorg){$Zorg}).csv"
        $VMNICArrayList | Sort-Object VPGName | Export-Csv $CSVExportFile -NoTypeInformation -Force
    }
    catch
    {
        Write-Host $_ | Out-String
    }
}

Set-Alias -Name znic -Value Export-ZertoVPGNetworkSettings
#>

<#
.SYNOPSIS
  This Commandlet is the compliment of Export-ZertoVPGNetworkSettings. After exporting network settings to a csv and editting to the desired settings, this function imports the csv and uploads the network settings for VPGs to a Zerto Virtual Manager (ZVM).

.DESCRIPTION
  This function connects to a Zerto Virtual Manager (ZVM) and sends network settings for Virtual Protection Groups (VPGs) based on and a csv file. 

.PARAMETER ZVM
  The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER CSVPath
  The path to the csv file. 

.PARAMETER RecoveryVPGType
  The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER Port
  The port to connect to the ZVM. Default is 443.

.EXAMPLE
   # Send network settings for all VPGs listed in the csv to the Zerto Virtual Manager.
   Import-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -CSVPath "C:\users\username\documents\VPGsettings.csv"

#>
<#function Import-ZertoVPGNetworkSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter(Mandatory)]
        [ValidateScript({
                if (!($_ | Test-Path))
                {
                    throw "File does not exist"
                }
                if (!($_ | Test-Path -PathType Leaf))
                {
                    throw "The path argument must be a file not a directory"
                }
                return $true
            })]
        [string]$CSVPath,
        [Parameter()]
        [string]$Port="443"
    )

    # Connect to ZVM

    if((get-module -name zertoapiwrapper).version.Major -eq 1)
    {
        #This required some changes to due to dependency conflicts (Changed function name in psm1 file and in psd1 file for version 1.4.2)
        Connect-ZertoServerUnder10 -Server $ZVM -credential $Credentials
    } else {
        Connect-ZertoServer -Server $ZVM -credential $Credentials -AutoReconnect
    }

    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    $CSVImport = Import-Csv $CSVPath
    $NumNICs = (Get-Content $CSVPath).Count - 1
    $RecoverySiteList = New-Object -TypeName "System.Collections.ArrayList"
    $RecoveryOrgVdcList = New-Object -TypeName "System.Collections.ArrayList"
    $NetworksBySiteId = @{}

    if ($null -ne $CSVImport)
    {
        # Each line in CSV represents a NIC.  One VPG might have multiple VMS and multiple NICs per VM.  
        # We get one VPGSetting per VPG, then commit once if and only if any changes were requested
        $VPGList = $CSVImport | Select-Object -Unique -ExpandProperty VPGID
        Write-Host "Read $NumNICs NIC's across $($VPGlist.Count) VPG's to configure." -ForegroundColor Yellow
        foreach ($VPGID in $VPGList)
        {
            $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
            $VPGSettingsID = Invoke-ZertoRestRequest -uri "vpgSettings" -method POST -body $VPGJSON
            if ($?) {$ValidVPGSettingsID = $True} else {$ValidVPGSettingsID = $False}
            $SkipVPGCommit = $true
            # Now we get all the VMs that belong to the VPG without duplicates
            $VMList = $CSVImport | Where-Object {$_.VPGID -eq $VPGID} | Select-Object -ExpandProperty VMID -Unique
            foreach ($VMID in $VMList)
            {
                # Then we gather all the lines(NICs) that match that VMID
                $NICList = $CSVImport | Where-Object {$_.VMID -eq $VMID} 
                foreach ($NIC in $NICList)
                {
                    $VPGName = $NIC.VPGName
                    $NICID = $NIC.NICID
                    $vCloud = [System.Convert]::ToBoolean($NIC.IsVcloud)
                    Write-Host "Starting NIC:$NICID on VM:$VMID VPG:$VPGName" -ForegroundColor Yellow
                    if ($ValidVPGSettingsID)
                    {
                        # Getting NIC settings
                        $EditVMNICURL = "vpgSettings/$VPGSettingsID/vms/$VMID/nics/$NICID"
                        # VMNICID might contain spaces so encode the URL
                        $EncodedVMNICURL = [System.Web.HttpUtility]::UrlPathEncode($EditVMNICURL)
                        $OriginalNICSettings = Invoke-ZertoRestRequest -Method GET -Uri $EncodedVMNICURL 
                        $NICSettings = $OriginalNICSettings | ConvertTo-Json -Depth 10 | ConvertFrom-Json
                        $RecoverySiteId = $NIC.RecoverySiteId
                        if ($vCloud)
                        {
                            $RecoveryOrgVDCId = $NIC.RecoveryOrgVdcId
                            # If we havent gathered site details for this org VDC yet
                            if (-not ($RecoveryOrgVdcList.Contains($RecoveryOrgVDCId)))
                            {
                                Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                                $null = $RecoveryOrgVdcList.Add($RecoveryOrgVDCId)
                                $VPGOrgVdcNetworksURL = "virtualizationsites/$RecoverySiteId/orgvdcs/$RecoveryOrgVDCId/networks"
                                Write-Host "networks." -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoveryOrgVdcId = Invoke-ZertoRestRequest -Method GET -Uri $VPGOrgVdcNetworksURL
                            }
                            # Discover network identifiers
                            $FailoverNetworkID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverNetworkName} | select -ExpandProperty NetworkIdentifier
                            $FailoverTestNetworkID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverTestNetworkName} | select -ExpandProperty NetworkIdentifier
                            if (($null -eq $FailoverNetworkID) -or ($null -eq $FailoverTestNetworkID))
                            {
                                Write-Host "VDC network not found!  Skipping NIC:$NICID VM:$VMID VPG:$VPGName)" -ForegroundColor Red
                                Write-Host "Requested FailoverNetworkName: $($NIC.FailoverNetworkName)" -ForegroundColor Yellow
                                Write-Host "Requested FailoverNetworkTestName: $($NIC.FailoverNetworkTestName)" -ForegroundColor Yellow
                                Write-Host "Valid OrgVDC Networks:" -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoveryOrgVdcId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                                continue
                            }
                            if ($NIC.FailoverIpMode -ne "StaticIp") {$NIC.FailoverStaticIp = $null}
                            if ($NIC.FailoverTestIpMode -ne "StaticIp") {$NIC.FailoverTestStaticIp = $null}
                            $NICSettings.Failover.VCD.IsResetMacAddress                     = [System.Convert]::ToBoolean($NIC.FailoverShouldResetMacAddress)
                            $NICSettings.Failover.VCD.IpMode                                = $NIC.FailoverIpMode
                            $NICSettings.Failover.VCD.RecoveryOrgVdcNetworkIdentifier       = $FailoverNetworkID
                            $NICSettings.Failover.VCD.IpAddress                             = $NIC.FailoverStaticIp
                            $NICSettings.Failover.VCD.IsConnected                           = [System.Convert]::ToBoolean($NIC.FailoverIsConnected)
                            $NICSettings.Failover.VCD.IsPrimary                             = [System.Convert]::ToBoolean($NIC.FailoverIsPrimary)
                            $NICSettings.FailoverTest.VCD.IsResetMacAddress                 = [System.Convert]::ToBoolean($NIC.FailoverTestShouldResetMacAddress)
                            $NICSettings.FailoverTest.VCD.IpMode                            = $NIC.FailoverTestIpMode
                            $NICSettings.FailoverTest.VCD.RecoveryOrgVdcNetworkIdentifier   = $FailoverTestNetworkID
                            $NICSettings.FailoverTest.VCD.IpAddress                         = $NIC.FailoverTestStaticIp
                            $NICSettings.FailoverTest.VCD.IsConnected                       = [System.Convert]::ToBoolean($NIC.FailoverTestIsConnected)
                            $NICSettings.FailoverTest.VCD.IsPrimary                         = [System.Convert]::ToBoolean($NIC.FailoverTestIsPrimary)
                        }
                        else
                        {
                            if (-not ($RecoverySiteList.Contains($RecoverySiteId)))
                            {
                                Write-Host "Discovering new recovery site " -NoNewline -ForegroundColor Cyan
                                $null = $RecoverySiteList.Add($RecoverySiteId)
                                $VPGPortGroupsURL = "virtualizationsites/$RecoverySiteId/networks"
                                Write-Host "networks." -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoverySiteId = Invoke-ZertoRestRequest -Method GET -Uri $VPGPortGroupsURL
                            }
                            $FailoverNetworkID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverNetworkName} | select -ExpandProperty NetworkIdentifier
                            $FailoverTestNetworkID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverTestNetworkName} | select -ExpandProperty NetworkIdentifier
                            if (($null -eq $FailoverNetworkID) -or ($null -eq $FailoverTestNetworkID))
                            {
                                Write-Host "Vcenter network not found!  Skipping NIC:$NICID VM:$VMID VPG:$VPGName)" -ForegroundColor Red
                                Write-Host "Requested FailoverNetworkName: $($NIC.FailoverNetworkName)" -ForegroundColor Yellow
                                Write-Host "Requested FailoverNetworkTestName: $($NIC.FailoverNetworkTestName)" -ForegroundColor Yellow
                                Write-Host "Valid vCenter Networks:" -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoverySiteId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                                continue
                            }
                            $Failover = $NICSettings.Failover.Hypervisor
                            $FailoverTest = $NICSettings.FailoverTest.Hypervisor
                            if (([System.Convert]::ToBoolean($NIC.FailoverIsDHCP))) {$NIC.FailoverStaticIp = $null}
                            if (([System.Convert]::ToBoolean($NIC.FailoverTestIsDHCP))) {$NIC.FailoverTestStaticIp = $null}
                            $Failover.NetworkIdentifier             = $FailoverNetworkID
                            $Failover.ShouldReplaceMacAddress       = [System.Convert]::ToBoolean($NIC.FailoverShouldReplaceMacAddress)
                            $Failover.DnsSuffix                     = $NIC.FailoverDNSSuffix
                            $Failover.Ipconfig.IsDhcp               = [System.Convert]::ToBoolean($NIC.FailoverIsDHCP)
                            $Failover.Ipconfig.StaticIp             = $NIC.FailoverStaticIp
                            $Failover.Ipconfig.SubnetMask           = $NIC.FailoverSubnetMask
                            $Failover.Ipconfig.Gateway              = $NIC.FailoverGateway
                            $Failover.Ipconfig.PrimaryDns           = $NIC.FailoverPrimaryDns
                            $Failover.Ipconfig.SecondaryDns         = $NIC.FailoverSecondaryDns
                            $FailoverTest.NetworkIdentifier         = $FailoverTestNetworkID
                            $FailoverTest.ShouldReplaceMacAddress   = [System.Convert]::ToBoolean($NIC.FailoverTestShouldReplaceMacAddress)
                            $FailoverTest.DnsSuffix                 = $NIC.FailoverTestDNSSuffix
                            $FailoverTest.Ipconfig.IsDhcp           = [System.Convert]::ToBoolean($NIC.FailoverTestIsDHCP)
                            $FailoverTest.Ipconfig.StaticIp         = $NIC.FailoverTestStaticIp
                            $FailoverTest.Ipconfig.SubnetMask       = $NIC.FailoverTestSubnetMask
                            $FailoverTest.Ipconfig.Gateway          = $NIC.FailoverTestGateway
                            $FailoverTest.Ipconfig.PrimaryDns       = $NIC.FailoverTestPrimaryDns
                            $FailoverTest.Ipconfig.SecondaryDns     = $NIC.FailoverTestSecondaryDns
                        }
                        $VMNICJSON = $NICSettings | ConvertTo-Json -Depth 5
                        # Compare objects by breaking them back into JSON, split by lines, and trim whitespace for output formatting
                        $Comparison = Compare-Object (($OriginalNICSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$') `
                        (($NICSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$')
                        if ($null -ne $Comparison)
                        {
                            # If *any* nics in the VPG are requested to be changed, then we must commit
                            $SkipVPGCommit = $false
                            Write-Host ($Comparison | Select-Object @{E={$_.InputObject};N='RequestedChanges'} | Format-Table | Out-String)
                            $EditVMNICURL = "vpgSettings/$VPGSettingsID/vms/$VMID/nics/$NICID"
                            # VMNICID might contain spaces so encode the URL
                            $EncodedVMNICURL = [System.Web.HttpUtility]::UrlPathEncode($EditVMNICURL)
                            $null = Invoke-ZertoRestRequest -Method PUT -Uri $EncodedVMNICURL -Body $VMNICJSON
                        }
                        $FailoverNetworkID = $null
                        $FailoverTestNetworkID = $null
                    }
                }
            }
            if (-not ($SkipVPGCommit))
            {
                $CommitVPGSettingURL = "vpgSettings/$VPGSettingsID/commit"
                $null = Invoke-ZertoRestRequest -Method POST -Uri $CommitVPGSettingURL
                if ($?) {Write-Host "Update for VPG:$VPGName completed" -ForegroundColor Green} else {Write-Host "Update failed" -ForegroundColor Red;continue}            
            }
            else
            {
                Write-Host "No changes for VPG:$VPGName" -ForegroundColor Green 
                # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
                $VPGSettingsURL = "vpgSettings/$VPGSettingsID"
                $null = Invoke-ZertoRestRequest -Method Delete -Uri $VPGSettingsURL
            }
        }
        Write-Host "All done!" 
    }
}
Set-Alias -Name iznic -Value Import-ZertoVPGNetworkSettings
#>
<#
.SYNOPSIS
  This Commandlet is the compliment of Export-ZertoVPGNetworkSettings. After exporting network settings to a csv and editting to the desired settings, this function imports the csv and uploads the network settings for VPGs to a Zerto Virtual Manager (ZVM).

.DESCRIPTION
  This function connects to a Zerto Virtual Manager (ZVM) and sends network settings for Virtual Protection Groups (VPGs) based on and a csv file. 

.PARAMETER ZVM
  The IP address or FQDN of the Zerto Virtual Manager.

.PARAMETER CSVPath
  The path to the csv file. 

.PARAMETER RecoveryVPGType
  The type of recovery VPG. Valid values are "vCenter" or "VCD".

.PARAMETER Port
  The port to connect to the ZVM. Default is 443.

.EXAMPLE
   # Send network settings for all VPGs listed in the csv to the Zerto Virtual Manager.
   Import-ZertoNetworkSettings -ZVM "zerto-lab.lab.zerto.com" -Credentials $MyCreds -CSVPath "C:\users\username\documents\VPGsettings.csv"

#>
<#function Import-ZertoVPGNetworkSettings9 {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]$ZVM,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,
        [Parameter(Mandatory)]
        [ValidateScript({
                if (!($_ | Test-Path))
                {
                    throw "File does not exist"
                }
                if (!($_ | Test-Path -PathType Leaf))
                {
                    throw "The path argument must be a file not a directory"
                }
                return $true
            })]
        [string]$CSVPath,
        [Parameter()]
        [string]$Port="9669"
    )

    Function Invoke-WebWrapper($Core,$Uri,$Method,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            if ([string]$_.Exception.Response.StatusCode.value__ -eq "401")
            {
                throw("Unauthorized, Invalid credentials")
            }
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    Function Invoke-RestWrapper($Core,$Uri,$Method,$Body,$Headers,$ContentType)
    {
        # Compatibility function for PowerShell 5/7 
        # Mostly we use self-signed certs, so we must ignore SSL cert errors
        try
        {
            if ($Core)
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -SkipCertificateCheck
            }
            else
            {
                Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ContentType $ContentType -UseBasicParsing
            }
        }
        catch
        {
            Write-Host "Failed URL $URI" -ForegroundColor Yellow
            Write-Host "Response code: $($_.Exception.Response.StatusCode.value__) Message: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
    if ($PSVersionTable.PSVersion.Major -gt 6) {$TurboCore = $true} else {$TurboCore = $false}
    if (-not $TurboCore)
    {
        try
        {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        catch
        {
            Write-Host "Already ignoring SSL cert errors"
        }
    }

    $ZertoUser = $Credentials.UserName
    $ZertoPassword = $Credentials.GetNetworkCredential().Password
    $BaseURL = "https://" + $ZVM + ":" + "$Port" + "/v1/"
    $GUIBaseURL = "https://" + $ZVM + ":" + "$Port" + "/GuiServices/v1/VisualQueryProvider/"
    $ZertoSessionURL = $BaseURL + "session/add"
    $Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoUser+":"+$ZertoPassword))}
    $Type = "application/json"

    # Auth
    $ZertoSessionResponse = Invoke-WebWrapper -Core $TurboCore -Uri $ZertoSessionURL -Method Post -Headers $Header -ContentType $Type 
    if ($ZertoSessionResponse.StatusCode -eq 401)
    {
        throw('401 Not Authorized.  Please check your credentials and try again')
    }
    $ZertoSession = $ZertoSessionResponse.headers.get_item("x-zerto-session")
    $ZertoSessionHeader = @{"Accept" ="application/json"
        "x-zerto-session"            ="$ZertoSession"
    }
    $DSRemoteSession = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ZertoSession))
    $GUISessionHeader = @{"Accept" ="application/json"
        DSRemoteCredentials        = $DSRemoteSession
    }
    Write-Host "Authenticated to $ZVM" -ForegroundColor Green

    $CSVImport = Import-Csv $CSVPath
    $NumNICs = (Get-Content $CSVPath).Count - 1
    $RecoverySiteList = New-Object -TypeName "System.Collections.ArrayList"
    $RecoveryOrgVdcList = New-Object -TypeName "System.Collections.ArrayList"
    $NetworksBySiteId = @{}

    if ($null -ne $CSVImport)
    {
        # Each line in CSV represents a NIC.  One VPG might have multiple VMS and multiple NICs per VM.  
        # We get one VPGSetting per VPG, then commit once if and only if any changes were requested
        $VPGList = $CSVImport | Select-Object -Unique -ExpandProperty VPGID
        Write-Host "Read $NumNICs NIC's across $($VPGlist.Count) VPG's to configure." -ForegroundColor Yellow
        foreach ($VPGID in $VPGList)
        {
            $VPGJSON = "{""VpgIdentifier"":""$VPGID""}"
            $CreateVPGSettingsURL = $BaseURL+"vpgSettings"
            $VPGSettingsID = Invoke-RestWrapper -Core $Turbocore -Method POST -Uri $CreateVPGSettingsURL -Body $VPGJSON -ContentType $Type -Headers $ZertoSessionHeader  
            if ($?) {$ValidVPGSettingsID = $True} else {$ValidVPGSettingsID = $False}
            $SkipVPGCommit = $true
            # Now we get all the VMs that belong to the VPG without duplicates
            $VMList = $CSVImport | Where-Object {$_.VPGID -eq $VPGID} | Select-Object -ExpandProperty VMID -Unique
            foreach ($VMID in $VMList)
            {
                # Then we gather all the lines(NICs) that match that VMID
                $NICList = $CSVImport | Where-Object {$_.VMID -eq $VMID} 
                foreach ($NIC in $NICList)
                {
                    $VPGName = $NIC.VPGName
                    $NICID = $NIC.NICID
                    $vCloud = [System.Convert]::ToBoolean($NIC.IsVcloud)
                    Write-Host "Starting NIC:$NICID on VM:$VMID VPG:$VPGName" -ForegroundColor Yellow
                    if ($ValidVPGSettingsID)
                    {
                        # Getting NIC settings
                        $EditVMNICURL = $BaseURL + "vpgSettings/$VPGSettingsID/vms/$VMID/nics/$NICID"
                        # VMNICID might contain spaces so encode the URL
                        $EncodedVMNICURL = [System.Web.HttpUtility]::UrlPathEncode($EditVMNICURL)
                        $OriginalNICSettings = Invoke-RestWrapper -Core $Turbocore -Method GET -Uri $EncodedVMNICURL -ContentType $Type -Headers $ZertoSessionHeader
                        $NICSettings = $OriginalNICSettings | ConvertTo-Json -Depth 10 | ConvertFrom-Json
                        $RecoverySiteId = $NIC.RecoverySiteId
                        if ($vCloud)
                        {
                            $RecoveryOrgVDCId = $NIC.RecoveryOrgVdcId
                            # If we havent gathered site details for this org VDC yet
                            if (-not ($RecoveryOrgVdcList.Contains($RecoveryOrgVDCId)))
                            {
                                Write-Host "Discovering new OrgVDC " -NoNewline -ForegroundColor Cyan
                                $null = $RecoveryOrgVdcList.Add($RecoveryOrgVDCId)
                                $VPGOrgVdcNetworksURL = $baseURL+"virtualizationsites/$RecoverySiteId/orgvdcs/$RecoveryOrgVDCId/networks"
                                Write-Host "networks." -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoveryOrgVdcId = Invoke-RestWrapper -Core $Turbocore -Method GET -Uri $VPGOrgVdcNetworksURL -ContentType $Type -Headers $ZertoSessionHeader
                            }
                            # Discover network identifiers
                            $FailoverNetworkID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverNetworkName} | select -ExpandProperty NetworkIdentifier
                            $FailoverTestNetworkID = $NetworksBySiteId.$RecoveryOrgVdcId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverTestNetworkName} | select -ExpandProperty NetworkIdentifier
                            if (($null -eq $FailoverNetworkID) -or ($null -eq $FailoverTestNetworkID))
                            {
                                Write-Host "VDC network not found!  Skipping NIC:$NICID VM:$VMID VPG:$VPGName)" -ForegroundColor Red
                                Write-Host "Requested FailoverNetworkName: $($NIC.FailoverNetworkName)" -ForegroundColor Yellow
                                Write-Host "Requested FailoverNetworkTestName: $($NIC.FailoverNetworkTestName)" -ForegroundColor Yellow
                                Write-Host "Valid OrgVDC Networks:" -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoveryOrgVdcId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                                continue
                            }
                            if ($NIC.FailoverIpMode -ne "StaticIp") {$NIC.FailoverStaticIp = $null}
                            if ($NIC.FailoverTestIpMode -ne "StaticIp") {$NIC.FailoverTestStaticIp = $null}
                            $NICSettings.Failover.VCD.IsResetMacAddress                     = [System.Convert]::ToBoolean($NIC.FailoverShouldResetMacAddress)
                            $NICSettings.Failover.VCD.IpMode                                = $NIC.FailoverIpMode
                            $NICSettings.Failover.VCD.RecoveryOrgVdcNetworkIdentifier       = $FailoverNetworkID
                            $NICSettings.Failover.VCD.IpAddress                             = $NIC.FailoverStaticIp
                            $NICSettings.Failover.VCD.IsConnected                           = [System.Convert]::ToBoolean($NIC.FailoverIsConnected)
                            $NICSettings.Failover.VCD.IsPrimary                             = [System.Convert]::ToBoolean($NIC.FailoverIsPrimary)
                            $NICSettings.FailoverTest.VCD.IsResetMacAddress                 = [System.Convert]::ToBoolean($NIC.FailoverTestShouldResetMacAddress)
                            $NICSettings.FailoverTest.VCD.IpMode                            = $NIC.FailoverTestIpMode
                            $NICSettings.FailoverTest.VCD.RecoveryOrgVdcNetworkIdentifier   = $FailoverTestNetworkID
                            $NICSettings.FailoverTest.VCD.IpAddress                         = $NIC.FailoverTestStaticIp
                            $NICSettings.FailoverTest.VCD.IsConnected                       = [System.Convert]::ToBoolean($NIC.FailoverTestIsConnected)
                            $NICSettings.FailoverTest.VCD.IsPrimary                         = [System.Convert]::ToBoolean($NIC.FailoverTestIsPrimary)
                        }
                        else
                        {
                            if (-not ($RecoverySiteList.Contains($RecoverySiteId)))
                            {
                                Write-Host "Discovering new recovery site " -NoNewline -ForegroundColor Cyan
                                $null = $RecoverySiteList.Add($RecoverySiteId)
                                $VPGPortGroupsURL = $baseURL+"virtualizationsites/$RecoverySiteId/networks"
                                Write-Host "networks." -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoverySiteId = Invoke-RestWrapper -Core $Turbocore -Method GET -Uri $VPGPortGroupsURL -ContentType $Type -Headers $ZertoSessionHeader
                            }
                            $FailoverNetworkID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverNetworkName} | select -ExpandProperty NetworkIdentifier
                            $FailoverTestNetworkID = $NetworksBySiteId.$RecoverySiteId | Where-Object {$_.VirtualizationNetworkName -eq $NIC.FailoverTestNetworkName} | select -ExpandProperty NetworkIdentifier
                            if (($null -eq $FailoverNetworkID) -or ($null -eq $FailoverTestNetworkID))
                            {
                                Write-Host "Vcenter network not found!  Skipping NIC:$NICID VM:$VMID VPG:$VPGName)" -ForegroundColor Red
                                Write-Host "Requested FailoverNetworkName: $($NIC.FailoverNetworkName)" -ForegroundColor Yellow
                                Write-Host "Requested FailoverNetworkTestName: $($NIC.FailoverNetworkTestName)" -ForegroundColor Yellow
                                Write-Host "Valid vCenter Networks:" -ForegroundColor Cyan
                                $NetworksBySiteId.$RecoverySiteId | Select-Object -ExpandProperty VirtualizationNetworkName | Sort-Object
                                continue
                            }
                            $Failover = $NICSettings.Failover.Hypervisor
                            $FailoverTest = $NICSettings.FailoverTest.Hypervisor
                            if (([System.Convert]::ToBoolean($NIC.FailoverIsDHCP))) {$NIC.FailoverStaticIp = $null}
                            if (([System.Convert]::ToBoolean($NIC.FailoverTestIsDHCP))) {$NIC.FailoverTestStaticIp = $null}
                            $Failover.NetworkIdentifier             = $FailoverNetworkID
                            $Failover.ShouldReplaceMacAddress       = [System.Convert]::ToBoolean($NIC.FailoverShouldReplaceMacAddress)
                            $Failover.DnsSuffix                     = $NIC.FailoverDNSSuffix
                            $Failover.Ipconfig.IsDhcp               = [System.Convert]::ToBoolean($NIC.FailoverIsDHCP)
                            $Failover.Ipconfig.StaticIp             = $NIC.FailoverStaticIp
                            $Failover.Ipconfig.SubnetMask           = $NIC.FailoverSubnetMask
                            $Failover.Ipconfig.Gateway              = $NIC.FailoverGateway
                            $Failover.Ipconfig.PrimaryDns           = $NIC.FailoverPrimaryDns
                            $Failover.Ipconfig.SecondaryDns         = $NIC.FailoverSecondaryDns
                            $FailoverTest.NetworkIdentifier         = $FailoverTestNetworkID
                            $FailoverTest.ShouldReplaceMacAddress   = [System.Convert]::ToBoolean($NIC.FailoverTestShouldReplaceMacAddress)
                            $FailoverTest.DnsSuffix                 = $NIC.FailoverTestDNSSuffix
                            $FailoverTest.Ipconfig.IsDhcp           = [System.Convert]::ToBoolean($NIC.FailoverTestIsDHCP)
                            $FailoverTest.Ipconfig.StaticIp         = $NIC.FailoverTestStaticIp
                            $FailoverTest.Ipconfig.SubnetMask       = $NIC.FailoverTestSubnetMask
                            $FailoverTest.Ipconfig.Gateway          = $NIC.FailoverTestGateway
                            $FailoverTest.Ipconfig.PrimaryDns       = $NIC.FailoverTestPrimaryDns
                            $FailoverTest.Ipconfig.SecondaryDns     = $NIC.FailoverTestSecondaryDns
                        }
                        $VMNICJSON = $NICSettings | ConvertTo-Json -Depth 5
                        # Compare objects by breaking them back into JSON, split by lines, and trim whitespace for output formatting
                        $Comparison = Compare-Object (($OriginalNICSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$') `
                        (($NICSettings | ConvertTo-Json -Depth 10) -split '\r?\n' -replace '^\s+|\s+$')
                        if ($null -ne $Comparison)
                        {
                            # If *any* nics in the VPG are requested to be changed, then we must commit
                            $SkipVPGCommit = $false
                            Write-Host ($Comparison | Select-Object @{E={$_.InputObject};N='RequestedChanges'} | Format-Table | Out-String)
                            $EditVMNICURL = $BaseURL + "vpgSettings/$VPGSettingsID/vms/$VMID/nics/$NICID"
                            # VMNICID might contain spaces so encode the URL
                            $EncodedVMNICURL = [System.Web.HttpUtility]::UrlPathEncode($EditVMNICURL)
                            $null = Invoke-RestWrapper -Core $Turbocore -Method PUT -Uri $EncodedVMNICURL -Body $VMNICJSON -ContentType $Type -Headers $ZertoSessionHeader  
                        }
                        $FailoverNetworkID = $null
                        $FailoverTestNetworkID = $null
                    }
                }
            }
            if (-not ($SkipVPGCommit))
            {
                $CommitVPGSettingURL = $BaseURL + "vpgSettings/$VPGSettingsID/commit"
                $null = Invoke-RestWrapper -Core $Turbocore -Method POST -Uri $CommitVPGSettingURL -Headers $ZertoSessionHeader -ContentType $Type
                if ($?) {Write-Host "Update for VPG:$VPGName completed" -ForegroundColor Green} else {Write-Host "Update failed" -ForegroundColor Red;continue}            
            }
            else
            {
                Write-Host "No changes for VPG:$VPGName" -ForegroundColor Green 
                # Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
                $VPGSettingsURL = $BaseURL + "vpgSettings/$VPGSettingsID"
                $null = Invoke-RestWrapper -Core $Turbocore -Method Delete -Uri $VPGSettingsURL -ContentType $Type -Headers $ZertoSessionHeader
            }
        }
        Write-Host "All done!" 
    }
}
Set-Alias -Name iznic9 -Value Import-ZertoVPGNetworkSettings9
#>
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

Set-Alias -Name gdu -Value Get-ZertoDatastoreUsage

<#function Remove-vpgSettingsIDs {
    $vpgSettingsIds = Get-ZertoVpgSetting
    foreach ($vpgSettingsID in $vpgSettingsIds){Remove-ZertoVpgSettingsIdentifier -vpgSettingsIdentifier $vpgSettingsID.VpgSettingsIdentifier}
}
Set-Alias -Name vpgids -Value Remove-vpgSettingsIDs
#>

Export-ModuleMember -Function Get-CustomerDRStorageReport, Export-ZertoVPGNetworkSettings, Import-ZertoVPGNetworkSettings, Export-ZertoVPGNetworkSettings9, Import-ZertoVPGNetworkSettings9, Get-ZertoDatastoreUsage, Remove-vpgSettingsIDs, Export-ZertoVPGSettings, Export-ZertoVPGSettings9, Import-ZertoVPGSettings -Alias znic, gdu, vpgids, drs, iznic, znic9, iznic9, zset, zset9, izset
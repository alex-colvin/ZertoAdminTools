Connect-ZertoServer $DA2Z $DA2ZPW -AutoReconnect

$vpginfo = import-csv C:\Users\alex.colvin\Downloads\BBAVMDRInfo2.csv
$StoragePolicyID = "urn:vcloud:vdcstorageProfile:6b829040-d80b-4cf8-a409-625f3fdba7a7"


foreach ($vpg in $vpginfo)
{
    Copy-ZertoVpg -SourceVpgName "BBA-cid7c69-RTP-DA2-BBA-PHL-VPCM1" -NewVpgName "BBA-cid7c69-RTP-DA2-BBA-$($vpg.vm_or_vapp_name)" -VMs $vpg.vm_or_vapp_name -StoragePolicyIdentifier $StoragePolicyID
}

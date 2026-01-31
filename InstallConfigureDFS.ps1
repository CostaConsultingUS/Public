# This script installs DFS services, creates DFS folder, builds replication and publishes.
# There needs to be another script that makes subfolders. This one doesn't do that.
# Written by:   Patrick Costa 7.25.2019
#               Eric Talamantes

# Define Variables
$SiteID="x"
$Domain = "x.x"
$sourceServer="x"
$SourceUNC="\\$sourceServer\x"
$SourceLocal="E:\x"
$destinationServer="x"
$destinationUNC="\\$destinationServer\site\x"
$destinationLocal="E:\site\x"

# DFS Replication Group name (must NOT contain slashes)
$DFSReplGroup = "Location-$SiteID"

# DFS Namespace folder path (must be a valid DFS root)
$DFSFolderPath="\\$Domain\site\$SiteID"

# Create Folder, add targets to folder
New-DfsnFolder -Path $DFSFolderPath -TargetPath $SourceUNC -EnableTargetFailback $True -State online
New-DfsnFolderTarget -Path $DFSFolderPath -TargetPath $destinationUNC -State online

# Install DFS Replication on Servers
Invoke-Command -Computername $sourceServer -ScriptBlock {Install-WindowsFeature FS-DFS-Replication, RSAT-DFS-Mgmt-Con}
Invoke-Command -Computername $destinationServer -ScriptBlock {Install-WindowsFeature FS-DFS-Replication, RSAT-DFS-Mgmt-Con}

# Create Replication Group
New-DfsReplicationGroup -GroupName $DFSReplGroup |
    New-DfsReplicatedFolder -FolderName $SiteID |
    Add-DfsrMember -ComputerName $SourceServer, $destinationServer -GroupName $DFSReplGroup

Set-DfsrMembership -GroupName $DFSReplGroup -FolderName $SiteID -ComputerName $sourceServer -ContentPath $SourceLocal -PrimaryMember $True -Force
Set-DfsrMembership -GroupName $DFSReplGroup -FolderName $SiteID -ComputerName $destinationServer -ContentPath $DestinationLocal -Force

Add-DfsrConnection -DestinationComputerName $destinationServer -GroupName $DFSReplGroup -SourceComputerName $SourceServer

# Link Replication Group to DFS Folder (DFSn)
Set-DfsReplicatedFolder -GroupName $DFSReplGroup -DfsnPath $DFSFolderPath -FolderName $SiteID
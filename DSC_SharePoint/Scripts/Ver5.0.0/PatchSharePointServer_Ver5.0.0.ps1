param(
    [Parameter(Mandatory = $true)]
    [string]$FarmName,
	[Parameter(Mandatory = $true)]
    [string]$username
	
)

# Load the configuration file
$ConfigFile = ".\Config.psd1"
if (-Not (Test-Path $ConfigFile)) {
    throw "Configuration file not found at path '$ConfigFile'"
}

$ConfigurationData = Import-PowerShellDataFile -Path $ConfigFile

# Filter nodes for the selected farm
$FarmNodes = $ConfigurationData.AllNodes | Where-Object { $_.FarmName -eq $FarmName -or $_.NodeName -eq "*"}
if (-Not $FarmNodes) {
    throw "No nodes found for farm '$FarmName' in the configuration."
}

$FarmNodesForConfig = $FarmNodes | Where-Object { $_.NodeName -ne "*" }

# Determine the farm type and patch details
$FarmType = $FarmNodes[1].FarmType
$FarmPatchInfo = $ConfigurationData.NonNodeData.PathInfo | Where-Object { $_.FarmType -eq $FarmType }
if (-Not $FarmPatchInfo) {
    throw "No patch information found for farm type '$FarmType'."
}

$localRootFolder = "G:\Software\SharePoint_CUs"
$PatchVersion = $FarmPatchInfo.FarmVersion
$PatchLocalFolder = Join-Path $localRootFolder $PatchVersion

$password = Read-Host "Enter password for $($username)" -AsSecureString
[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)


Configuration PatchSharePointServers
{
	param (
        [PSObject]$FarmNodes,
        [PSObject]$PatchInfo
    )
	
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc

    node $AllNodes.NodeName
    {
        
        # Determine the CA server and let it create the farm, all other servers will run wizard that afterwards
        $CAServer = ($AllNodes | Where-Object { $_.IsCA -eq $true } | Select-Object -First 1).NodeName
        $AllNodeNames = ($AllNodes | Where-Object { $_.NodeName -ne "*" }).NodeName

        xRemoteFile DownloadCoreFile
        {
            DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PatchInfo.CorePath.Url)))
            Uri = $PatchInfo.CorePath.Url
            ChecksumType    = $PatchInfo.CorePath.ChecksumType
            Checksum        = $PatchInfo.CorePath.Checksum
            PsDscRunAsCredential = $credential
        }

        $DownloadWaitTask = "[xRemoteFile]DownloadCoreFile"

        if($PatchInfo.LangPath.IsExist)
        {
            xRemoteFile DownloadLanguageFile
            {
                DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PatchInfo.LangPath.Url)))
                Uri = $PatchInfo.LangPath.Url
                ChecksumType    = $PatchInfo.LangPath.ChecksumType
                Checksum        = $PatchInfo.LangPath.Checksum
                PsDscRunAsCredential = $credential
            }

            $DownloadWaitTask = "[xRemoteFile]DownloadCoreFile","[xRemoteFile]DownloadLanguageFile"
        }

        SPProductUpdate InstallCorePatch
        {
            SetupFile            = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PatchInfo.CorePath.Url)))
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $credential
			DependsOn             = $DownloadWaitTask
        }
        $WaitingWizard = "[SPProductUpdate]InstallCorePatch"

        if($PatchInfo.LangPath.IsExist)
        {
            SPProductUpdate InstallLangPatch
            {
                SetupFile            =  (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PatchInfo.LangPath.Url)))
                ShutdownServices     = $false            
                Ensure               = "Present"
                PsDscRunAsCredential = $credential
			    DependsOn             = "[SPProductUpdate]InstallCorePatch"
            }

            $WaitingWizard = '[SPProductUpdate]InstallCorePatch','[SPProductUpdate]InstallLangPatch'
        }

        if($Node.IsCA)
        {
            

            if(!$PatchInfo.LangPath.IsExist)
            {
                WaitForAll WaitForPatchesInstallComplete
                {
                    ResourceName         = "[SPProductUpdate]InstallCorePatch"
                    NodeName             = $AllNodeNames
                    RetryIntervalSec     = 300
                    RetryCount           = 1000
                    PsDscRunAsCredential = $credential
                    DependsOn             = $WaitingWizard
                }

            
            }
            else
            {

                WaitForAll WaitForPatchesInstallComplete
                {
                    ResourceName         = '[SPProductUpdate]InstallLangPatch'
                    NodeName             = $AllNodeNames
                    RetryIntervalSec     = 300
                    RetryCount           = 1000
                    PsDscRunAsCredential = $credential
                    DependsOn             = $WaitingWizard
                }
            

            }


             SPConfigWizard RunConfigWizard
            {
                IsSingleInstance     = "Yes"
                PsDscRunAsCredential = $credential
				DependsOn             = "[WaitForAll]WaitForPatchesInstallComplete"
            }

           <# PendingReboot RebootAfterSPConfigWizard
            {
                Name      = 'AfterCASPConfigWizard'
                DependsOn = '[SPConfigWizard]RunConfigWizard'
            } #>
        }
        else
        {
            WaitForAll WaitForCAFarmToComplete
            {
                ResourceName         = "[SPConfigWizard]RunConfigWizard"
                NodeName             = $CAServer
                RetryIntervalSec     = 300
                RetryCount           = 1000
                PsDscRunAsCredential = $credential
                DependsOn             = $WaitingWizard
            }

            SPConfigWizard OtherRunConfigWizard
            {
                IsSingleInstance     = "Yes"
                PsDscRunAsCredential = $credential
				DependsOn             = "[WaitForAll]WaitForCAFarmToComplete"
            }

            <#PendingReboot AfterApr2023SPConfigWizard
            {
                Name      = 'AfterOtherSPConfigWizard'
                DependsOn = '[SPConfigWizard]OtherRunConfigWizard'
            }#>

        }
    }
}

#region LCM Config


[DSCLocalConfigurationManager()]
Configuration LCMConfig
{
    node $FarmNodesForConfig.NodeName
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration';
            RebootNodeIfNeeded = $true;
			
        }
		
    }
}
#LCMConfig -ConfigurationData .\Config.psd1
LCMConfig -ConfigurationData @{ AllNodes = $FarmNodes }
Set-DscLocalConfigurationManager LCMConfig -Force -Verbose
#endregion



#PatchSharePointServers -ConfigurationData .\Config.psd1 -OutputPath .\PatchServers
#PatchSharePointServers -FarmNodes $FarmNodes -PatchInfo $FarmPatchInfo -OutputPath .\PatchServers
PatchSharePointServers -ConfigurationData @{ AllNodes = $FarmNodes } -FarmNodes $FarmNodes -PatchInfo $FarmPatchInfo -OutputPath .\PatchServers
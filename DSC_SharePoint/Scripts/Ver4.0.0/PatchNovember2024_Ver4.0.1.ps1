$localRootFolder = "G:\Software\SharePoint_CUs"
$PatchVersion = "16.0.5474.1001-November2024"
$PatchLocalFolder = Join-Path $localRootFolder $PatchVersion

$username = "EXTWTO\svcSP_AdminPP_WTO"
$password = Read-Host "Enter password for $($username)" -AsSecureString

[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)


Configuration PatchSharePointServersNovember2024
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc

    node $AllNodes.NodeName
    {
        
        # Determine the CA server and let it create the farm, all other servers will run wizard that afterwards
        $CAServer = ($AllNodes | Where-Object { $_.IsCA -eq $true } | Select-Object -First 1).NodeName
        $AllNodeNames = ($AllNodes | Where-Object { $_.NodeName -ne "*" }).NodeName -join ","
        $AllNodeNames1 = ($AllNodes | Where-Object { $_.NodeName -ne "*" }).NodeName 

        xRemoteFile DownloadCoreFile
        {
            DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($ConfigurationData.NonNodeData.CorePath.Url)))
            Uri = $ConfigurationData.NonNodeData.CorePath.Url
            ChecksumType    = $ConfigurationData.NonNodeData.CorePath.ChecksumType
            Checksum        = $ConfigurationData.NonNodeData.CorePath.Checksum
            PsDscRunAsCredential = $credential
        }

        $DownloadWaitTask = "[xRemoteFile]DownloadCoreFile"

        if($ConfigurationData.NonNodeData.LangPath.IsExist)
        {
            xRemoteFile DownloadLanguageFile
            {
                DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($ConfigurationData.NonNodeData.LangPath.Url)))
                Uri = $ConfigurationData.NonNodeData.LangPath.Url
                ChecksumType    = $ConfigurationData.NonNodeData.LangPath.ChecksumType
                Checksum        = $ConfigurationData.NonNodeData.LangPath.Checksum
                PsDscRunAsCredential = $credential
            }

            $DownloadWaitTask = "[xRemoteFile]DownloadCoreFile","[xRemoteFile]DownloadLanguageFile"
        }

        SPProductUpdate InstallCorePatch
        {
            SetupFile            = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($ConfigurationData.NonNodeData.CorePath.Url)))
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $credential
			DependsOn             = $DownloadWaitTask
        }
        $WaitingWizard = "[SPProductUpdate]InstallCorePatch"

        if($ConfigurationData.NonNodeData.LangPath.IsExist)
        {
            SPProductUpdate InstallLangPatch
            {
                SetupFile            =  (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($ConfigurationData.NonNodeData.LangPath.Url)))
                ShutdownServices     = $false            
                Ensure               = "Present"
                PsDscRunAsCredential = $credential
			    DependsOn             = "[SPProductUpdate]InstallCorePatch"
            }

            $WaitingWizard = '[SPProductUpdate]InstallCorePatch','[SPProductUpdate]InstallLangPatch'
        }

        if($Node.IsCA)
        {
            

            if(!$ConfigurationData.NonNodeData.LangPath.IsExist)
            {
                WaitForAll WaitForPatchesInstallComplete
                {
                    ResourceName         = "[SPProductUpdate]InstallCorePatch"
                    NodeName             = $AllNodeNames1
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
                    NodeName             = $AllNodeNames1
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
    node $AllNodes.NodeName
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration';
            RebootNodeIfNeeded = $true;
        }
    }
}
LCMConfig -ConfigurationData .\Config.psd1
Set-DscLocalConfigurationManager LCMConfig -Force -Verbose
#endregion



PatchSharePointServersNovember2024 -ConfigurationData .\Config.psd1 -OutputPath .\PatchNovember2024
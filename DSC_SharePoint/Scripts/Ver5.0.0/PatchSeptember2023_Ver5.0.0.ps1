$localRootFolder = "C:\Software\SharePoint_CUs"

$PatchLocalFolder = Join-Path $localRootFolder $PatchVersion

#$password = "abcde12345-" | ConvertTo-SecureString -asPlainText -Force
#$username = "icclabvn\spfarm"
#[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)


Configuration PatchSharePointServersSeptember2023
{
    param
    (
        [Parameter(Mandatory)] [String]$FarmName,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$DomainAdminCreds
        
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion 5.4.0
    $RelatedServer = $AllNodes | Where-Object {$_.FarmName -eq $FarmName }

    node $RelatedServer.NodeName
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ContinueConfiguration'
            RebootNodeIfNeeded = $true
			
        }
        
        # Determine the CA server and let it create the farm, all other servers will run wizard that afterwards
        $CAServer = ($RelatedServer | Where-Object { $_.IsCA -eq $true } | Select-Object -First 1).NodeName
        
        #$AllNodeNames = ($RelatedServer | Where-Object { $_.NodeName -ne "*" }).NodeName -join ","
        $AllNodeNames = ($RelatedServer | Where-Object { $_.NodeName -ne "*" }).NodeName 

        #detect farm type: SPSE, SP19, SP16
        $farmType = ($RelatedServer | Select-Object -First 1).FarmType 

        $PathInfo = $ConfigurationData.NonNodeData.PathInfo | Where-Object {$_.FarmType -eq $farmType }
        $PatchVersion = $PathInfo.FarmVersion

        xRemoteFile DownloadCoreFile
        {
            DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PathInfo.CorePath.Url)))
            Uri = $PathInfo.CorePath.Url
            ChecksumType    = $PathInfo.CorePath.ChecksumType
            Checksum        = $PathInfo.CorePath.Checksum
            PsDscRunAsCredential = $DomainAdminCreds
        }

        $DownloadWaitTask = "[xRemoteFile]DownloadCoreFile"

        if($PathInfo.LangPath.IsExist)
        {
            xRemoteFile DownloadLanguageFile
            {
                DestinationPath = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PathInfo.LangPath.Url)))
                Uri = $PathInfo.LangPath.Url
                #ChecksumType    = $ConfigurationData.NonNodeData.LangPath.ChecksumType
                #Checksum        = $ConfigurationData.NonNodeData.LangPath.Checksum
                PsDscRunAsCredential = $DomainAdminCreds
            }

            $DownloadWaitTask = "[xRemoteFile]DownloadLanguageFile"
        }

        SPProductUpdate InstallCorePatch
        {
            SetupFile            = (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PathInfo.CorePath.Url)))
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $DomainAdminCreds
			DependsOn             = $DownloadWaitTask
        }
        $WaitingWizard = "[SPProductUpdate]InstallCorePatch"

        if($ConfigurationData.NonNodeData.LangPath.IsExist)
        {
            SPProductUpdate InstallLangPatch
            {
                SetupFile            =  (Join-Path $PatchLocalFolder ([System.IO.Path]::GetFileName($PathInfo.LangPath.Url)))
                ShutdownServices     = $false            
                Ensure               = "Present"
                PsDscRunAsCredential = $DomainAdminCreds
			    DependsOn             = "[SPProductUpdate]InstallCorePatch"
            }

            $WaitingWizard = '[SPProductUpdate]InstallCorePatch','[SPProductUpdate]InstallLangPatch'
        }

        if($Node.IsCA)
        {
            WaitForAll WaitForCorePathInstallComplete
            {
                ResourceName         = "[SPProductUpdate]InstallCorePatch"
                NodeName             = $AllNodeNames
                RetryIntervalSec     = 300
                RetryCount           = 1000
                PsDscRunAsCredential = $DomainAdminCreds
                DependsOn             = $WaitingWizard
            }

            $DependWaitingWizardForCA = "[WaitForAll]WaitForCorePathInstallComplete"

            if($ConfigurationData.NonNodeData.LangPath.IsExist)
            {

                WaitForAll WaitForLanguePathInstallComplete
                {
                    ResourceName         = $DependWaitingWizardForCA
                    NodeName             = $AllNodeNames
                    RetryIntervalSec     = 300
                    RetryCount           = 1000
                    PsDscRunAsCredential = $DomainAdminCreds
                    DependsOn             = '[WaitForAll]WaitForCorePathInstallComplete'
                }
                $DependWaitingWizardForCA = "[WaitForAll]WaitForLanguePathInstallComplete"

            }


             SPConfigWizard RunConfigWizard
            {
                IsSingleInstance     = "Yes"
                PsDscRunAsCredential = $DomainAdminCreds
				DependsOn             = $DependWaitingWizardForCA
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
                PsDscRunAsCredential = $DomainAdminCreds
                DependsOn             = $WaitingWizard
            }

            SPConfigWizard OtherRunConfigWizard
            {
                IsSingleInstance     = "Yes"
                PsDscRunAsCredential = $DomainAdminCreds
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


PatchSharePointServersSeptember2023 -FarmName "SIF_STG" -ConfigurationData .\Config.psd1 -OutputPath .\SIF_STG\PatchSeptember2023
PatchSharePointServersSeptember2023 -FarmName "SIF_PRD" -ConfigurationData .\Config.psd1 -OutputPath .\SIF_PRD\PatchSeptember2023
PatchSharePointServersSeptember2023 -FarmName "ICJ_PRD" -ConfigurationData .\Config.psd1 -OutputPath .\ICJ_PRD\PatchSeptember2023
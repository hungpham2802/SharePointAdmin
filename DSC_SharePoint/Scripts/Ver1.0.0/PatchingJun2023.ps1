$password = "abcde12345-" | ConvertTo-SecureString -asPlainText -Force
$username = "icclabvn\spfarm"
[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)

configuration PatchJun2023
{
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc 
	
    Node localhost
    {
        
        xRemoteFile DownloadCoreFile
        {
            DestinationPath = "C:\Software\SharePoint_CUs\16.0.5400.1001-Jun2023\sts2016-kb5002404-fullfile-x64-glb.exe"
            Uri = "https://download.microsoft.com/download/5/a/7/5a75e07d-26b0-4b6a-9154-27e9a0224e1f/sts2016-kb5002404-fullfile-x64-glb.exe"
            PsDscRunAsCredential = $credential
        }

    
		
		SPProductUpdate InstallCU2023JunCore
        {
            SetupFile            = "C:\Software\SharePoint_CUs\16.0.5400.1001-Jun2023\sts2016-kb5002404-fullfile-x64-glb.exe"
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $credential
			DependsOn             = '[xRemoteFile]DownloadCoreFile'
        }
		
		SPConfigWizard RunConfigWizard
        {
                IsSingleInstance     = "Yes"
                PsDscRunAsCredential = $credential
				DependsOn             = '[SPProductUpdate]InstallCU2023JunCore'
        }
		
		

    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
PatchJun2023 -ConfigurationData $cd
$password = "abcde12345-" | ConvertTo-SecureString -asPlainText -Force
$username = "icclabvn\spfarm"
[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)

configuration PatchingJanuary2022
{
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
	
    Node localhost
    {
        
        xRemoteFile DownloadCoreFile
        {
            DestinationPath = "C:\Software\SharePoint_CUs\16.0.5266.1000-Jan2021\sts2016-kb5002113-fullfile-x64-glb.exe"
            Uri = "https://download.microsoft.com/download/8/6/e/86e2b0b7-18be-44fa-9f86-7ba7a2f71721/sts2016-kb5002113-fullfile-x64-glb.exe"
            PsDscRunAsCredential = $credential
		ChecksumType    = "SHA256"
            Checksum        = "3F528A56C1022187EA906E0CF8E058C528168897FB171C2ED94707149550C345"
        }

        xRemoteFile DownloadLanguageFile
        {
            DestinationPath = "C:\Software\SharePoint_CUs\16.0.5266.1000-Jan2021\wssloc2016-kb5002118-fullfile-x64-glb.exe"
            Uri = "https://download.microsoft.com/download/c/d/c/cdc66551-193f-4786-843f-c37e522c5025/wssloc2016-kb5002118-fullfile-x64-glb.exe"
            PsDscRunAsCredential = $credential
		ChecksumType    = "SHA256"
            Checksum        = "788296A1FEBCE2C2ACCD9E1095EE888F65E56C09364F0977AE9047073F5D6ECA"
        }
		
	SPProductUpdate InstallCU2022JanCore
        {
            SetupFile            = "C:\Software\SharePoint_CUs\16.0.5266.1000-Jan2021\sts2016-kb5002113-fullfile-x64-glb.exe"
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $credential
			DependsOn             = '[xRemoteFile]DownloadCoreFile','[xRemoteFile]DownloadLanguageFile'
        }

	SPProductUpdate InstallCU2022JanLangue
        {
            SetupFile            = "C:\Software\SharePoint_CUs\16.0.5266.1000-Jan2021\wssloc2016-kb5002118-fullfile-x64-glb.exe"
            ShutdownServices     = $false            
            Ensure               = "Present"
            PsDscRunAsCredential = $credential
			DependsOn             = '[SPProductUpdate]InstallCU2022JanCore'
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
PatchingJanuary2022 -ConfigurationData $cd
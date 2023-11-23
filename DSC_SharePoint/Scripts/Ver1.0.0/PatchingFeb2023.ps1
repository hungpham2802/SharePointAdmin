$password = "abcde12345-" | ConvertTo-SecureString -asPlainText -Force
$username = "icclabvn\spfarm"
[PSCredential] $credential = New-Object System.Management.Automation.PSCredential($username,$password)

configuration PatchFeb2023
{
    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
	
    Node localhost
    {
        
        xRemoteFile DownloadCoreFile
        {
            DestinationPath = "C:\Software\SharePoint_CUs\16.0.5383.1000-Feb2023\sts2016-kb5002350-fullfile-x64-glb.exe"
            Uri = "https://download.microsoft.com/download/d/8/d/d8d25884-acca-44fd-b2f9-fa57f38a37d3/sts2016-kb5002350-fullfile-x64-glb.exe"
            PsDscRunAsCredential = $credential
        }

        xRemoteFile DownloadLanguageFile
        {
            DestinationPath = "C:\Software\SharePoint_CUs\16.0.5383.1000-Feb2023\wssloc2016-kb5002325-fullfile-x64-glb.exe"
            Uri = "https://download.microsoft.com/download/a/9/4/a946e0c6-ddd2-4e74-960c-c1c9076a1029/wssloc2016-kb5002325-fullfile-x64-glb.exe"
            PsDscRunAsCredential = $credential
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
PatchFeb2023 -ConfigurationData $cd
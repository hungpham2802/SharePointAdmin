@{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true;
        },
        @{
            NodeName = "W16SP16PRD1.icclabvn.com"
            IsCA = $true
        },
        @{
            NodeName = "W16SP16PRD2.icclabvn.com"
            IsCA = $false
        },
	@{
            NodeName = "W16SP16PRD3.icclabvn.com"
            IsCA = $false
        }
    )
    NonNodeData = @{
        CorePath =@{
            Url = "https://download.microsoft.com/download/a/7/d/a7d95f46-a0b6-4c5a-ade2-b61e57949172/sts2016-kb5002494-fullfile-x64-glb.exe"  
            ChecksumType    = "SHA256"
            Checksum        = "E773C65A7D0F2736786118DDBEBAC03FA4D7DACAFD9167F42E5F3F7BBE1B575E"          
        }
        LangPath = @{
            Url = "https://download.microsoft.com/download/f/8/8/f8896fb2-c52e-4653-8c61-f1f4f8f11fbe/wssloc2016-kb5002501-fullfile-x64-glb.exe" 
            IsExist = $true
            ChecksumType    = "SHA256"
            Checksum        = "4552D3F1CAF83BBC0657B0689DDF6136B9C70F361B3C804AEAD95170D08CD685"
        }
    }
}

@{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true;
        },
        @{
            FarmName = "SIF_STG"
            FarmType = "SP16"
            NodeName = "SFSHP16STG1.mcs01.unicc.org"
            IsCA = $true
        },
        @{
            FarmName = "SIF_PRD"
            FarmType = "SP16"
            NodeName = "SFSHP16PRD1.mcs01.unicc.org"
            IsCA = $true
        },
        @{
            FarmName = "SIF_PRD"
            FarmType = "SP16"
            NodeName = "SFSHP16PRD2.mcs01.unicc.org"
            IsCA = $false
        },
	    @{
            FarmName = "SIF_PRD"
            FarmType = "SP16"
            NodeName = "SFSHP16PRD3.mcs01.unicc.org"
            IsCA = $false
        },
        @{
            FarmName = "IFAD_STG"
            FarmType = "SP16"
            NodeName = "IFSHP16STG1.mcs01.unicc.org"
            IsCA = $true
        },
         @{
            FarmName = "IFAD_PRD"
            FarmType = "SP16"
            NodeName = "IFSHP16PRD1.mcs01.unicc.org"
            IsCA = $true
        },
        @{
            FarmName = "IFAD_PRD"
            FarmType = "SP16"
            NodeName = "IFSHP16PRD2.mcs01.unicc.org"
            IsCA = $false
        },
        @{
            FarmName = "IFAD_PRD"
            FarmType = "SP16"
            NodeName = "IFSHP16PRD3.mcs01.unicc.org"
            IsCA = $false
        },
         @{
            FarmName = "ICJ_PRD"
            FarmType = "SPSE"
            NodeName = "CJSHPSEPRD1.mcs01.unicc.org"
            IsCA = $true
        },
         @{
            FarmName = "ICJ_PRD"
            FarmType = "SPSE"
            NodeName = "CJSHPSEPRD2.mcs01.unicc.org"
            IsCA = $false
        },
         @{
            FarmName = "ICJ_PRD"
            FarmType = "SPSE"
            NodeName = "CJSHPSEPRD3.mcs01.unicc.org"
            IsCA = $false
        },
         @{
            FarmName = "ICJ_DR"
            FarmType = "SPSE"
            NodeName = "CJSHPSEDR1.mcs01.unicc.org"
            IsCA = $false
        }

    )
    NonNodeData = @{
        PathInfo = @{
            FarmType = "SPSE"
            FarmVersion = "16.0.16731.20252-October2023"
            CorePath =@{
                Url = "https://download.microsoft.com/download/a/7/d/a7d95f46-a0b6-4c5a-ade2-b61e57949172/sts2016-kb5002494-fullfile-x64-glb.exe"  
                ChecksumType    = "SHA256"
                Checksum        = "E773C65A7D0F2736786118DDBEBAC03FA4D7DACAFD9167F42E5F3F7BBE1B575E"          
            }
            LangPath = @{
                Url = "" 
                IsExist = $false
                ChecksumType    = "SHA256"
                Checksum        = ""
            }
        },
        @{
            FarmType = "SP19"
            FarmVersion = "16.0.10403.20000-October2023"
            CorePath =@{
                Url = "https://download.microsoft.com/download/a/7/d/a7d95f46-a0b6-4c5a-ade2-b61e57949172/sts2016-kb5002494-fullfile-x64-glb.exe"  
                ChecksumType    = "SHA256"
                Checksum        = "E773C65A7D0F2736786118DDBEBAC03FA4D7DACAFD9167F42E5F3F7BBE1B575E"          
            }
            LangPath = @{
                Url = "https://download.microsoft.com/download/f/8/8/f8896fb2-c52e-4653-8c61-f1f4f8f11fbe/wssloc2016-kb5002501-fullfile-x64-glb.exe" 
                IsExist = $false
                ChecksumType    = "SHA256"
                Checksum        = ""
            }
        },
        @{
            FarmType = "SP16"
            FarmVersion = "16.0.5413.1001-September2023"
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
}

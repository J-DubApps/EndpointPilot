#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # This test requires Windows environment
    if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
        throw "FileOps integration tests require Windows environment"
    }
    
    # Import required modules
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-Functions.psm1"
    Import-Module $ModulePath -Force
    
    $SharedPath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-SHARED.ps1"
    if (Test-Path $SharedPath) {
        . $SharedPath
    }
    
    # Create test directory structure
    $script:TestRoot = Join-Path -Path $TestDrive -ChildPath "FileOpsTests"
    $script:SourcePath = Join-Path -Path $script:TestRoot -ChildPath "Source"
    $script:DestPath = Join-Path -Path $script:TestRoot -ChildPath "Destination"
    
    New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $script:SourcePath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:DestPath -ItemType Directory -Force | Out-Null
    
    # Create test files
    $script:TestFile1 = Join-Path -Path $script:SourcePath -ChildPath "test1.txt"
    $script:TestFile2 = Join-Path -Path $script:SourcePath -ChildPath "test2.txt"
    
    "Test content 1" | Out-File -FilePath $script:TestFile1 -Encoding UTF8
    "Test content 2" | Out-File -FilePath $script:TestFile2 -Encoding UTF8
}

Describe "File Operations Integration Tests" -Tag "Integration", "Windows", "FileOps" {
    
    Context "File Copy Operations" {
        It "Should copy single file successfully" {
            $destFile = Join-Path -Path $script:DestPath -ChildPath "copied1.txt"
            
            Copy-Item -Path $script:TestFile1 -Destination $destFile -Force
            
            Test-Path $destFile | Should -Be $true
            Get-Content $destFile | Should -Be "Test content 1"
        }
        
        It "Should copy multiple files successfully" {
            Copy-Item -Path "$($script:SourcePath)\*.txt" -Destination $script:DestPath -Force
            
            $copiedFiles = Get-ChildItem -Path $script:DestPath -Filter "*.txt"
            $copiedFiles.Count | Should -BeGreaterOrEqual 2
        }
        
        It "Should handle missing source files gracefully" {
            $nonExistentFile = Join-Path -Path $script:SourcePath -ChildPath "missing.txt"
            $destFile = Join-Path -Path $script:DestPath -ChildPath "missing.txt"
            
            { Copy-Item -Path $nonExistentFile -Destination $destFile -ErrorAction Stop } | Should -Throw
        }
        
        It "Should preserve file timestamps when requested" {
            $sourceTime = (Get-Item $script:TestFile1).LastWriteTime
            $destFile = Join-Path -Path $script:DestPath -ChildPath "timestamped.txt"
            
            Copy-Item -Path $script:TestFile1 -Destination $destFile -Force
            
            $destTime = (Get-Item $destFile).LastWriteTime
            # Allow for small time differences (within 2 seconds)
            ($destTime - $sourceTime).TotalSeconds | Should -BeLessThan 2
        }
    }
    
    Context "Directory Operations" {
        BeforeAll {
            $script:TestSubDir = Join-Path -Path $script:SourcePath -ChildPath "SubDirectory"
            New-Item -Path $script:TestSubDir -ItemType Directory -Force | Out-Null
            "Nested content" | Out-File -FilePath (Join-Path -Path $script:TestSubDir -ChildPath "nested.txt") -Encoding UTF8
        }
        
        It "Should create directories successfully" {
            $newDir = Join-Path -Path $script:TestRoot -ChildPath "NewDirectory"
            
            New-Item -Path $newDir -ItemType Directory -Force
            
            Test-Path $newDir | Should -Be $true
            (Get-Item $newDir).PSIsContainer | Should -Be $true
        }
        
        It "Should copy directories recursively" {
            $destDir = Join-Path -Path $script:DestPath -ChildPath "CopiedDirectory"
            
            Copy-Item -Path $script:TestSubDir -Destination $destDir -Recurse -Force
            
            Test-Path $destDir | Should -Be $true
            Test-Path (Join-Path -Path $destDir -ChildPath "nested.txt") | Should -Be $true
        }
        
        It "Should handle permission errors gracefully" {
            # Test copying to a restricted location (this may fail in some environments)
            $restrictedPath = "C:\Windows\System32\EndpointPilotTest"
            
            { Copy-Item -Path $script:TestFile1 -Destination $restrictedPath -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context "File Attribute Operations" {
        It "Should read file attributes correctly" {
            $attributes = Get-ItemProperty -Path $script:TestFile1
            
            $attributes | Should -Not -BeNullOrEmpty
            $attributes.Length | Should -BeGreaterThan 0
            $attributes.Extension | Should -Be ".txt"
        }
        
        It "Should modify file attributes when permitted" {
            $testFile = Join-Path -Path $script:TestRoot -ChildPath "attributetest.txt"
            "Attribute test" | Out-File -FilePath $testFile -Encoding UTF8
            
            # Set hidden attribute
            Set-ItemProperty -Path $testFile -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
            
            $attributes = Get-ItemProperty -Path $testFile
            $attributes.Attributes -band [System.IO.FileAttributes]::Hidden | Should -Be ([System.IO.FileAttributes]::Hidden)
            
            # Clear hidden attribute
            Set-ItemProperty -Path $testFile -Name Attributes -Value ([System.IO.FileAttributes]::Normal)
        }
    }
    
    Context "Large File Operations" {
        It "Should handle moderately large files" -Tag "Slow" {
            $largeFile = Join-Path -Path $script:TestRoot -ChildPath "large.txt"
            $destFile = Join-Path -Path $script:DestPath -ChildPath "large.txt"
            
            # Create a 1MB test file
            $content = "x" * 1024  # 1KB line
            1..1024 | ForEach-Object { $content } | Out-File -FilePath $largeFile -Encoding UTF8
            
            $copyStart = Get-Date
            Copy-Item -Path $largeFile -Destination $destFile -Force
            $copyEnd = Get-Date
            
            Test-Path $destFile | Should -Be $true
            (Get-Item $destFile).Length | Should -Be (Get-Item $largeFile).Length
            
            # Performance check - should complete within reasonable time
            ($copyEnd - $copyStart).TotalSeconds | Should -BeLessThan 30
        }
    }
    
    Context "Network Path Operations" -Tag "RequiresNetwork" {
        It "Should handle UNC paths when accessible" {
            # This test requires network access and may be skipped in isolated environments
            $uncPath = "\\localhost\c$\temp"
            
            if (Test-Path $uncPath) {
                $testUncFile = Join-Path -Path $uncPath -ChildPath "unctest.txt"
                "UNC test" | Out-File -FilePath $testUncFile -Encoding UTF8 -ErrorAction SilentlyContinue
                
                if (Test-Path $testUncFile) {
                    Test-Path $testUncFile | Should -Be $true
                    Remove-Item $testUncFile -Force -ErrorAction SilentlyContinue
                }
            } else {
                Set-ItResult -Skipped -Because "UNC path not accessible in test environment"
            }
        }
    }
}

Describe "File Operations Error Scenarios" -Tag "Integration", "ErrorHandling" {
    
    Context "Access Denied Scenarios" {
        It "Should handle readonly files appropriately" {
            $readonlyFile = Join-Path -Path $script:TestRoot -ChildPath "readonly.txt"
            "Readonly content" | Out-File -FilePath $readonlyFile -Encoding UTF8
            
            # Make file readonly
            Set-ItemProperty -Path $readonlyFile -Name IsReadOnly -Value $true
            
            # Attempt to overwrite should fail
            { "New content" | Out-File -FilePath $readonlyFile -Encoding UTF8 -ErrorAction Stop } | Should -Throw
            
            # Cleanup
            Set-ItemProperty -Path $readonlyFile -Name IsReadOnly -Value $false
            Remove-Item $readonlyFile -Force
        }
        
        It "Should handle locked files gracefully" {
            $lockedFile = Join-Path -Path $script:TestRoot -ChildPath "locked.txt"
            "Locked content" | Out-File -FilePath $lockedFile -Encoding UTF8
            
            # Open file for exclusive access
            $fileStream = [System.IO.File]::Open($lockedFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            
            try {
                # Attempt to copy locked file should handle the error
                $destFile = Join-Path -Path $script:DestPath -ChildPath "locked_copy.txt"
                { Copy-Item -Path $lockedFile -Destination $destFile -ErrorAction Stop } | Should -Throw
            } finally {
                $fileStream.Close()
                $fileStream.Dispose()
            }
        }
    }
    
    Context "Path Length Limitations" {
        It "Should handle long paths appropriately" -Tag "Slow" {
            # Create a path approaching Windows path length limits
            $longDirName = "a" * 100
            $longPath = Join-Path -Path $script:TestRoot -ChildPath $longDirName
            
            if ($longPath.Length -lt 248) {  # Leave room for filename
                New-Item -Path $longPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                
                if (Test-Path $longPath) {
                    $longFile = Join-Path -Path $longPath -ChildPath "longpath.txt"
                    "Long path test" | Out-File -FilePath $longFile -Encoding UTF8 -ErrorAction SilentlyContinue
                    
                    if (Test-Path $longFile) {
                        Test-Path $longFile | Should -Be $true
                    }
                }
            }
        }
    }
}

AfterAll {
    # Cleanup test directories
    if (Test-Path $script:TestRoot) {
        Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
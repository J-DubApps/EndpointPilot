###############################################################################################
#
#	    EndpointPilot Schema Validation Test Script
#			Test-Validation.PS1
#
#  Description
#    This script tests the JSON schema validation by validating the example JSON files
#    against their corresponding schemas.
#
#				Written by Julian West April 2025
#
###############################################################################################

# Create a copy of the example file for testing
Copy-Item -Path "EXAMPLE-FILE-OPS.json" -Destination "TEST-FILE-OPS.json" -Force
Write-Host "Created test file: TEST-FILE-OPS.json" -ForegroundColor Cyan

# Test the validation script with the test file
Write-Host "Testing validation script with TEST-FILE-OPS.json..." -ForegroundColor Yellow
& .\Validate-JsonSchema.ps1 -JsonFilePath "TEST-FILE-OPS.json" -SchemaFilePath "FILE-OPS.schema.json"

Write-Host "`nTest completed. You can examine the results above." -ForegroundColor Cyan
Write-Host "To test validation with all example files, run:" -ForegroundColor Yellow
Write-Host "  Copy-Item -Path 'EXAMPLE-*.json' -Destination { `$_.Name -replace 'EXAMPLE-', '' } -Force" -ForegroundColor Gray
Write-Host "  .\Validate-JsonSchema.ps1 -ValidateAll" -ForegroundColor Gray

# Clean up
Write-Host "`nCleaning up test file..." -ForegroundColor Cyan
Remove-Item -Path "TEST-FILE-OPS.json" -Force
Write-Host "Test file removed." -ForegroundColor Green
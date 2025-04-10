@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'MGMT-Functions.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = '12345678-1234-1234-1234-123456789abc'
    
    # Author of this module
    Author = 'Julian West'
    
    # Company or vendor of this module
    CompanyName = 'J-DubApps'
    
    # Copyright statement for this module
    Copyright = 'Copyright (c) 2025, Julian West'
    
    # Description of the functionality provided by this module
    Description = 'Core utility functions for the EndpointPilot Windows Endpoint Configuration Tool'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Core Utility Functions
        'InGroup', 
        'InGroupGP',
        'Get-Permission', 
        'IsCurrentProcessArm64', 
        'Get-RegistryValue',
        'Get-TextWithin', 
        'Get-DsRegStatusInfo', 
        'Get-WorkstationUsageStatus', 
        
        # Network/Performance Functions
        'Measure-DownloadSpeed', 
        'Measure-UploadSpeed', 
        'Send-SmtpMail',
        
        # User Information Functions
        'Get-LoggedInUser',

        # File Operation Functions
        
        'Copy-File', 
        'Copy-Directory', 
        'Move-Files', 
        'Move-Directory',
        'Import-RegKey'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
    'Get-Permissions'
    # Add any other aliases here
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('EndpointPilot', 'Windows', 'Endpoint', 'Configuration')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/J-DubApps/EndpointPilot'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/J-DubApps/EndpointPilot'
        }
    }
}
# EndpointPilot Product Requirements Document

Version 1.0 | August 2025

## Product overview

EndpointPilot is a PowerShell-based Windows endpoint configuration management solution designed to replace traditional domain logon scripts with a modern, hybrid-work-optimized approach. The system operates autonomously via an agent and uses JSON-driven configuration files to manage Windows endpoint settings across enterprise environments.

### Product summary

EndpointPilot addresses the limitations of traditional Group Policy Objects (GPO) and Intune policies for hybrid work environments by providing a locally-executing configuration management system that operates independently of network connectivity. The solution supports both x86-64 and ARM64 Windows architectures and integrates with Microsoft Intune and NinjaOne endpoint management platforms.

## Goals

### Business goals

- Replace unreliable domain logon scripts with a robust, locally-executing solution
- Enable consistent endpoint configuration for hybrid and remote work scenarios
- Reduce dependency on network connectivity for endpoint configuration management
- Provide enterprise-scale deployment capabilities through Intune and NinjaOne platforms
- Minimize IT support overhead through automated, self-maintaining endpoint configurations
- Support modern Windows architectures including ARM64 devices

### User goals

- IT administrators can deploy and manage endpoint configurations at scale without relying on domain connectivity
- End users experience consistent, reliable endpoint settings regardless of network location
- System administrators can modify configurations through intuitive JSON editing tools
- DevOps teams can version control and deploy endpoint configurations as code
- Security teams can enforce consistent security configurations across all managed endpoints

### Non-goals

- Inventory or asset tracking capabilities (delegated to Intune/NinjaOne)
- Remote control or IT service management features
- Database or stateful data storage requirements
- Support for Windows Server operating systems
- Support for x86 (32-bit) Windows architectures
- Support for Windows 10/11 Pro editions (Enterprise only)

## User personas

### Key user types

**IT System Administrator**: Primary configuration manager responsible for deploying and maintaining endpoint configurations across the organization

**DevOps Engineer**: Technical implementer who manages deployment packages, version control, and integration with enterprise management platforms

**Security Administrator**: Compliance and security specialist who defines security-related endpoint configurations and monitors compliance

**End User**: Windows endpoint user who benefits from consistent, reliable endpoint configurations without manual intervention

### Basic persona details

**IT System Administrator (Primary)**
- Role: Enterprise Windows endpoint management
- Technical skill: Intermediate PowerShell and JSON knowledge
- Goals: Reliable endpoint configuration with minimal maintenance overhead
- Pain points: Network-dependent GPO limitations, inconsistent remote worker configurations
- Tools: Intune admin center, JSON Editor Tool, PowerShell ISE/VS Code

**DevOps Engineer (Secondary)**
- Role: Deployment automation and CI/CD integration
- Technical skill: Advanced scripting and automation experience
- Goals: Automated deployment pipelines and version-controlled configurations
- Pain points: Manual deployment processes, inconsistent environment configurations
- Tools: GitHub Actions, Azure DevOps, PowerShell, .NET development tools

**Security Administrator (Secondary)**
- Role: Security policy enforcement and compliance monitoring
- Technical skill: Security frameworks and compliance requirements
- Goals: Consistent security configuration enforcement across all endpoints
- Pain points: Inconsistent security settings on remote endpoints, compliance gaps
- Tools: Security compliance dashboards, audit tools, JSON configuration files

### Role-based access

- **System Administrators**: Full access to all configuration files and deployment tools
- **Security Administrators**: Read/write access to security-related configurations, read access to other settings
- **DevOps Engineers**: Full access to deployment scripts and automation tools, read access to configurations
- **End Users**: No direct access to configuration files or administrative functions

## Functional requirements

### Core configuration management (Priority: High)

- Support for file operations (copy, move, delete, permissions)
- Registry modification capabilities for system and user-level settings
- Network drive mapping and management
- Roaming profile and folder redirection configuration
- System-level operations through dedicated System Agent service
- JSON schema validation for all configuration files
- Modular helper script architecture for extensibility

### Platform integration (Priority: High)

- Microsoft Intune deployment package creation and management
- NinjaOne application packaging and deployment support
- PowerShell 5.1 and PowerShell Core compatibility
- Windows 10/11 Enterprise edition support
- x86-64 and ARM64 architecture support
- Agent app script launch automation for autonomous operation

### Management and administration (Priority: Medium)

- WPF-based JSON Editor Tool for configuration management
- Configuration validation and error reporting
- Comprehensive logging and audit trail capabilities
- Update mechanism for deployed instances
- GitHub-based distribution and version control
- Group membership-based conditional execution

### Security and compliance (Priority: High)

- User-mode and system-mode execution contexts
- Secure configuration file storage and access control
- Comprehensive error handling and validation
- Script signing and integrity verification capabilities
- Audit logging for compliance reporting
- Security-focused system operations isolation

### Testing and quality assurance (Priority: Medium)

- Pester test framework integration
- JSON schema validation testing
- Installation and update process testing
- Cross-architecture compatibility testing
- Performance and reliability testing

## User experience

### Entry points

**Primary Entry Point**: Agent-based script execution every 30 minutes (configurable)
- Automatic execution via custom-built script launcher app
- No user interaction required for normal operation
- Silent execution with comprehensive logging

**Administrative Entry Points**:
- JSON Editor Tool for configuration management
- PowerShell script execution for manual operations
- GitHub repository for version control and updates
- Intune/NinjaOne deployment consoles for enterprise management

### Core experience

**Automatic Configuration Application**:
1. System detects scheduled execution trigger
2. ENDPOINT-PILOT.PS1 initiates architecture detection and validation
3. MAIN.PS1 orchestrates configuration loading and module execution
4. Helper scripts process JSON directive files for specific operation types
5. Operations execute with comprehensive error handling and logging
6. System returns to idle state until next scheduled execution

**Administrative Configuration Management**:
1. Administrator opens JSON Editor Tool or text editor
2. Loads existing configuration files or creates new ones
3. Modifies settings using schema-validated interface
4. Validates configuration against JSON schemas
5. Deploys updated configurations to target endpoints
6. Monitors execution through logs and reporting

### Advanced features

- **System Agent Integration**: Elevated system-level operations through dedicated Windows service
- **Group-Based Conditional Logic**: Configuration application based on Active Directory group membership
- **Hybrid Domain Detection**: Automatic adaptation for domain-joined and Azure AD-joined devices
- **Multi-Architecture Support**: Automatic detection and optimization for x86-64 and ARM64 platforms
- **Update Management**: Automated update mechanism preserving custom configurations

### UI/UX highlights

**JSON Editor Tool**:
- Modern WPF interface with Material Design styling
- Schema-driven validation with real-time error highlighting
- Tabbed interface for different operation types
- Save/load functionality with backup creation
- Export capabilities for deployment packages

**PowerShell Interface**:
- Comprehensive parameter validation and help text
- Consistent error messaging and logging format
- Progress indicators for long-running operations
- Verbose output modes for troubleshooting

## Narrative

As an IT administrator managing a hybrid workforce, I need a reliable way to configure Windows endpoints that works regardless of whether users are in the office, working from home, or traveling. Traditional Group Policy Objects fail when users are off the corporate network, and Intune policies don't cover all our configuration requirements. 

EndpointPilot solves this by running locally on each endpoint, executing configuration changes based on JSON files that I can easily manage and deploy. The system runs every 30 minutes automatically, ensuring that endpoints stay properly configured even when network connectivity is intermittent. When I need to make changes, I can use the JSON Editor Tool to modify configurations with confidence, knowing that the schema validation will catch errors before deployment. The solution integrates seamlessly with our existing Intune infrastructure for deployment, while providing the flexibility and reliability that our hybrid work model demands.

## Success metrics

### User-centric metrics

- **Configuration Reliability**: >99% successful configuration application rate across all managed endpoints
- **User Satisfaction**: <2 configuration-related help desk tickets per 1000 endpoints per month
- **Time to Configuration**: <5 minutes from deployment to first configuration application
- **Administrative Efficiency**: 75% reduction in manual endpoint configuration tasks

### Business metrics

- **Deployment Scale**: Support for 10,000+ managed endpoints across enterprise environments
- **Cost Reduction**: 60% reduction in endpoint configuration management overhead
- **Compliance Rate**: >95% compliance with security and configuration policies
- **Mean Time to Recovery**: <15 minutes for configuration issue resolution

### Technical metrics

- **System Performance**: <100MB memory usage during execution, <2% CPU utilization
- **Execution Speed**: <2 minutes average execution time for standard configuration sets
- **Reliability**: <0.1% system error rate, >99.9% scheduled execution success rate
- **Update Success**: >98% successful update deployment rate without configuration loss

## Technical considerations

### Integration points

**Microsoft Intune Integration**:
- .intunewin package creation for enterprise deployment
- Detection rules for installation and update management
- Win32 app deployment with custom installation parameters
- Assignment targeting and deployment scheduling

**NinjaOne Platform Integration**:
- Application packaging for NinjaOne deployment system
- Script deployment and execution monitoring
- Device categorization and targeting capabilities
- Automated deployment through NinjaOne policies

**Active Directory Integration**:
- Group membership detection for conditional configuration
- Domain join status detection for hybrid scenarios
- Group Policy preference integration where applicable
- Azure AD join status detection and handling

### Data storage and privacy

**Configuration Data Storage**:
- User-mode installations: %LOCALAPPDATA%\EndpointPilot
- System-mode installations: %PROGRAMDATA%\EndpointPilot
- JSON configuration files with schema validation
- Local logging with configurable retention periods

**Privacy and Security Considerations**:
- No personal data collection or transmission
- Local-only operation with no cloud dependencies
- Encrypted storage for sensitive configuration parameters
- Audit logging for compliance and security monitoring
- Access control lists for configuration file protection

### Scalability and performance

**Performance Optimization**:
- Modular architecture supporting selective operation execution
- Caching mechanisms for configuration validation and group membership
- Optimized PowerShell execution with minimal resource overhead
- Concurrent operation processing where applicable

**Scalability Design**:
- Stateless operation model supporting unlimited endpoint count
- Distributed configuration management through version control
- Horizontal scaling through platform integration (Intune/NinjaOne)
- Performance testing validated for 10,000+ endpoint deployments

### Potential challenges

**Technical Challenges**:
- PowerShell execution policy variations across enterprise environments
- Windows architecture differences between x86-64 and ARM64 platforms
- Agent operation reliability across different Windows versions
- JSON schema evolution and backward compatibility

**Operational Challenges**:
- Enterprise deployment coordination and change management
- Configuration conflict resolution between multiple management systems
- Update deployment without disrupting custom configurations
- Cross-platform development and testing requirements (Mac-based development)

**Security Challenges**:
- Secure configuration distribution and validation
- Privilege escalation prevention and monitoring
- Script signing and integrity verification implementation
- Audit trail maintenance for compliance requirements

## Milestones and sequencing

### Project estimate

**Total Project Duration**: 16 weeks
**Team Size**: 3-4 developers (1 primary, 2-3 supporting)
**Development Phases**: 4 major phases with incremental delivery

### Team size

**Core Development Team**:
- Primary Developer/Architect: PowerShell and .NET development expertise
- DevOps Engineer: CI/CD pipeline and deployment automation
- Security Specialist: Security review and compliance validation
- Quality Assurance: Testing framework and validation processes

### Suggested phases

**Phase 1: System Agent Implementation (Weeks 1-4)**
- Complete System Agent Windows service development
- SYSTEM-OPS.json processing implementation
- PowerShell hosting integration and testing
- Basic installer integration for System Agent deployment

**Phase 2: Enterprise Deployment (Weeks 5-8)**
- Intune package creation and deployment automation
- NinjaOne integration and packaging
- GitHub-based download and update mechanisms
- Installer refinement and error handling improvements

**Phase 3: Quality and Testing (Weeks 9-12)**
- Pester test framework implementation and comprehensive test coverage
- Cross-architecture compatibility testing and validation
- Performance testing and optimization for enterprise scale
- Security review and vulnerability assessment

**Phase 4: Production Readiness (Weeks 13-16)**
- Documentation completion and deployment guides
- Final deployment package creation and validation
- Production deployment pilot with select endpoint groups
- Support documentation and troubleshooting guides

## User stories

### US-001: Core Configuration Execution
**Title**: Automatic Configuration Application
**Description**: As a Windows endpoint, I need to automatically apply configuration changes based on JSON directive files so that system settings remain consistent regardless of network connectivity.
**Acceptance Criteria**:
- System Agent executes ENDPOINT-PILOT.PS1 every 30 minutes
- System detects and validates architecture (x86-64 or ARM64)
- MAIN.PS1 orchestrates loading of all helper modules
- JSON directive files are validated against schemas before processing
- File, registry, drive, and roaming operations execute successfully
- Comprehensive logging captures all execution details and errors
- System returns to idle state after completion

### US-002: JSON Configuration Management
**Title**: Configuration File Management
**Description**: As an IT administrator, I need to create and modify JSON configuration files using a schema-validated interface so that I can leverage standardized PowerShell Scripts to manage endpoint configurations -- without syntax errors.
**Acceptance Criteria**:

- JSON Editor Tool loads with tabbed interface for different operation types
- Real-time schema validation prevents invalid configuration entries
- Save functionality preserves configurations with backup creation
- Load functionality restores previous configurations
- Export capability creates deployment-ready configuration packages
- Material Design interface provides intuitive user experience

### US-003: System-Level Operations
**Title**: Elevated System Operations
**Description**: As a system administrator, I need to perform system-level operations like MSI installations and service management so that I can fully configure enterprise endpoints.
**Acceptance Criteria**:
- System Agent Windows service installs and starts automatically
- SYSTEM-OPS.json files are processed with elevated privileges
- MSI package installations execute successfully with proper error handling
- Windows service configuration and management operations work correctly
- System registry modifications apply at HKEY_LOCAL_MACHINE level
- Operations execute securely with proper access control validation

### US-004: Intune Deployment Package
**Title**: Enterprise Deployment via Intune
**Description**: As a DevOps engineer, I need to create Intune deployment packages so that I can deploy EndpointPilot to thousands of managed Windows endpoints.
**Acceptance Criteria**:
- Automated .intunewin package creation from GitHub repository
- Detection rules properly identify installation and update status
- Win32 app deployment supports custom installation parameters
- Assignment targeting allows deployment to specific device groups
- Installation progress monitoring and error reporting work correctly
- Update deployments preserve existing custom configurations

### US-005: Group-Based Conditional Logic
**Title**: Active Directory Group-Based Configuration
**Description**: As a security administrator, I need to apply different configurations based on Active Directory group membership so that I can enforce role-specific security policies.
**Acceptance Criteria**:
- InGroup and InGroupGP functions accurately detect AD group membership
- JSON configurations support conditional logic based on group membership
- Configuration application skips irrelevant settings for non-group members
- Group membership caching improves performance for repeated checks
- Hybrid Azure AD and on-premises AD group detection works correctly
- Audit logging captures group-based configuration decisions

### US-006: File Operations Management
**Title**: Automated File Management
**Description**: As an endpoint configuration system, I need to perform file operations like copying, moving, and setting permissions so that I can maintain consistent file structures across endpoints.
**Acceptance Criteria**:
- FILE-OPS.json directives process all file operation types
- Source file validation occurs before copy/move operations
- Destination path creation includes intermediate directory creation
- File permissions are set correctly with proper error handling
- Existing file handling (overwrite/skip) works as configured
- Operation logging includes file paths and success/failure status

### US-007: Registry Configuration Management
**Title**: Windows Registry Management
**Description**: As a system configuration tool, I need to create, modify, and delete registry entries so that I can configure Windows system and application settings.
**Acceptance Criteria**:
- REG-OPS.json directives support all registry operation types
- Registry key creation includes proper access permission handling
- Value setting supports all Windows registry data types
- Registry deletion operations include safety validation
- User and system registry hives are accessed appropriately
- Registry operations include rollback capability for error recovery

### US-008: Network Drive Mapping
**Title**: Automated Drive Mapping
**Description**: As an endpoint user, I need network drives mapped automatically so that I can access shared resources regardless of my location.
**Acceptance Criteria**:
- DRIVE-OPS.json directives create persistent network drive mappings
- Drive mapping includes credential handling for authenticated shares
- Existing drive mappings are updated or recreated as needed
- Drive mapping failures are logged with detailed error information
- Group-based drive mapping applies drives based on user group membership
- Drive mapping works correctly for both domain and Azure AD joined devices

### US-009: Roaming Profile Configuration
**Title**: Profile and Folder Redirection Management
**Description**: As an IT administrator, I need to configure roaming profiles and folder redirection so that users have consistent data access across devices.
**Acceptance Criteria**:
- ROAM-OPS.json directives configure folder redirection settings
- Profile path configuration supports both local and network locations
- Special folder redirection (Documents, Desktop, etc.) works correctly
- Folder redirection includes offline file synchronization settings
- User-specific folder redirection applies based on group membership
- Profile configuration changes take effect without requiring user logoff

### US-010: Comprehensive Logging and Auditing
**Title**: Audit Trail and Error Logging
**Description**: As a compliance officer, I need comprehensive logging of all configuration changes so that I can maintain audit trails and troubleshoot issues.
**Acceptance Criteria**:
- WriteLog function captures all operation attempts and results
- Log files include timestamps, operation types, and detailed outcomes
- Error logging includes stack traces and environmental context
- Log rotation prevents excessive disk space usage
- Audit logging meets enterprise compliance requirements
- Log analysis tools can parse and report on configuration activities

### US-011: Automated Installation and Updates
**Title**: Self-Installing and Updating System
**Description**: As an IT administrator, I need EndpointPilot to install and update itself automatically so that I can maintain current versions across all managed endpoints.
**Acceptance Criteria**:
- Install-EndpointPilot.ps1 downloads latest release from GitHub
- Installation creates proper directory structure and copies all required files
- Scheduled task creation works with appropriate user permissions
- Update process preserves custom configurations and settings
- Installation validation confirms all components are properly deployed
- Uninstallation removes all components cleanly without orphaned files

### US-012: Architecture Detection and Compatibility
**Title**: Multi-Architecture Support
**Description**: As a modern Windows endpoint, I need EndpointPilot to work correctly on both x86-64 and ARM64 architectures so that all device types are supported.
**Acceptance Criteria**:
- ENDPOINT-PILOT.PS1 accurately detects processor architecture
- Architecture-specific operations execute with platform-appropriate methods
- PowerShell compatibility is validated for both Windows PowerShell and PowerShell Core
- ARM64-specific optimizations are applied where beneficial
- Architecture validation blocks execution on unsupported platforms (x86)
- Cross-architecture testing validates functionality on all supported platforms

### US-013: JSON Schema Validation
**Title**: Configuration Validation Framework
**Description**: As a configuration management system, I need to validate all JSON files against schemas so that invalid configurations are detected before execution.
**Acceptance Criteria**:
- All JSON directive files have corresponding schema definitions
- Schema validation occurs before any configuration processing
- Validation errors include specific line numbers and error descriptions
- Schema evolution supports backward compatibility for existing configurations
- Custom validation rules enforce business logic constraints
- Validation reporting integrates with administrative tools

### US-014: Secure Authentication and Authorization
**Title**: Secure Access Control
**Description**: As a security administrator, I need secure authentication and authorization controls so that only authorized personnel can modify endpoint configurations.
**Acceptance Criteria**:
- Administrative functions require appropriate Windows permissions
- Configuration file access is restricted to authorized accounts
- System Agent operations validate caller permissions before execution
- Audit logging captures all authentication and authorization events
- Role-based access controls prevent unauthorized configuration changes
- Security review validates all access control implementations

### US-015: Performance Optimization
**Title**: Efficient Resource Utilization
**Description**: As an endpoint system, I need EndpointPilot to operate efficiently so that normal system performance is not impacted.
**Acceptance Criteria**:
- Memory usage remains below 100MB during operation
- CPU utilization stays below 2% average during execution
- Execution time for standard configurations completes within 2 minutes
- Disk I/O is optimized to minimize impact on system performance
- PowerShell module loading is cached to improve subsequent execution speed
- Performance monitoring validates resource usage targets

### US-016: Cross-Platform Development Support
**Title**: Mac-Based Development Environment
**Description**: As a developer working on Mac, I need to develop and test EndpointPilot components so that cross-platform development is supported.
**Acceptance Criteria**:
- Development container supports PowerShell development on Mac
- Testing framework can validate PowerShell scripts in containerized environment
- CI/CD pipeline supports development from Mac-based workstations
- Remote testing capabilities validate functionality on Windows VMs
- Documentation includes Mac-specific development setup instructions
- Version control workflow supports cross-platform collaboration

### US-017: Error Recovery and Resilience
**Title**: Robust Error Handling
**Description**: As an autonomous configuration system, I need comprehensive error recovery so that temporary failures don't prevent subsequent successful operations.
**Acceptance Criteria**:
- Try-catch blocks handle all potential error conditions
- Error recovery mechanisms retry failed operations with exponential backoff
- Configuration conflicts are detected and resolved automatically where possible
- System state validation ensures consistency after error recovery
- Critical errors trigger administrative notifications
- Error recovery preserves system stability and continues operation

### US-018: Enterprise Integration Testing
**Title**: Large-Scale Deployment Validation
**Description**: As an enterprise deployment, I need validation that EndpointPilot works correctly at scale so that production deployments are reliable.
**Acceptance Criteria**:
- Load testing validates performance with 10,000+ endpoint simulation
- Network connectivity variations are tested and handled gracefully
- Concurrent execution across multiple endpoints doesn't cause conflicts
- Enterprise directory integration works with large Active Directory environments
- Deployment package validation confirms successful installation across diverse hardware
- Scalability testing identifies and resolves potential bottlenecks

### US-019: Compliance and Regulatory Support
**Title**: Regulatory Compliance Framework
**Description**: As a compliance officer, I need EndpointPilot to support regulatory requirements so that audit and compliance obligations are met.
**Acceptance Criteria**:
- Audit logging meets regulatory requirements for data retention and security
- Configuration changes include approval workflow integration points
- Compliance reporting generates required documentation automatically
- Data privacy controls ensure no sensitive information is inappropriately logged
- Security controls meet enterprise security standards and frameworks
- Compliance validation testing confirms regulatory requirement adherence

### US-020: Documentation and Knowledge Transfer
**Title**: Comprehensive Documentation
**Description**: As a new administrator, I need complete documentation so that I can effectively deploy and manage EndpointPilot.
**Acceptance Criteria**:
- Installation guides provide step-by-step deployment instructions
- Configuration examples demonstrate common use cases
- Troubleshooting guides address known issues and resolution steps
- API documentation covers all PowerShell functions and parameters
- Security documentation explains all security controls and considerations
- Video tutorials demonstrate key administrative workflows
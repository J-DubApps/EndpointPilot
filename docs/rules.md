# EndpointPilot Project Rules

This document establishes comprehensive standards and guidelines for all humans and AI agents working on the EndpointPilot project. These rules ensure consistency, quality, security, and maintainability across all development work.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Security Standards](#security-standards)
3. [Code Quality Standards](#code-quality-standards)
4. [PowerShell Coding Conventions](#powershell-coding-conventions)
5. [JSON Schema Compliance](#json-schema-compliance)
6. [Architecture and Design Guidelines](#architecture-and-design-guidelines)
7. [Development Workflow](#development-workflow)
8. [Testing Requirements](#testing-requirements)
9. [Documentation Standards](#documentation-standards)
10. [Cross-Platform Development](#cross-platform-development)
11. [Enterprise Deployment Requirements](#enterprise-deployment-requirements)
12. [Error Handling and Logging](#error-handling-and-logging)
13. [Performance and Reliability](#performance-and-reliability)
14. [Version Control Standards](#version-control-standards)
15. [AI Agent Guidelines](#ai-agent-guidelines)

---

## Core Principles

### Project Mission
EndpointPilot is a PowerShell-based Windows endpoint configuration solution designed to replace traditional logon scripts with autonomous scheduled task execution, optimized for hybrid/remote work scenarios.

### Design Philosophy
- **"Better than a Logon Script"** - Autonomous operation via scheduled tasks, network-independent
- **JSON-Driven Configuration** - All operations defined through structured directive files
- **Modular Architecture** - Separate helper scripts for different operation types
- **User-Mode First** - Current user context operations with planned system-mode extensions
- **Enterprise Scale** - Design for 10,000+ endpoint deployments

### Quality Standards
- **Security First** - All security implications must be considered and documented
- **Performance Matters** - Solutions must perform efficiently at enterprise scale
- **Reliability Required** - System must be fault-tolerant and recoverable
- **Maintainability Focus** - Code must be self-documenting and easily modifiable

---

## Security Standards

### Code Security
1. **Input Validation**
   - All user inputs must be validated before processing
   - Use PowerShell parameter validation attributes (`[ValidateScript()]`, `[ValidateSet()]`)
   - Sanitize file paths to prevent path traversal attacks
   - Validate JSON structure against schemas before processing

2. **Execution Context**
   - Current operations run in user context only
   - System Agent operations must use principle of least privilege
   - Never store credentials in plain text
   - Use Windows Credential Manager or similar secure storage

3. **File System Security**
   - Use absolute paths only, never relative paths
   - Implement proper ACL validation before file operations
   - Verify file signatures where applicable
   - Use temporary directories with appropriate permissions

4. **Registry Security**
   - Validate registry paths before operations
   - Check for dangerous registry modifications
   - Document all registry changes with business justification
   - Implement rollback capabilities for registry operations

### Deployment Security
1. **Package Integrity**
   - All deployment packages must include integrity verification
   - Use code signing for PowerShell scripts where possible
   - Validate downloaded components against known good hashes

2. **Configuration Security**
   - JSON files must not contain sensitive information
   - Use environment variables or secure storage for secrets
   - Implement configuration validation at runtime

---

## Code Quality Standards

### General Code Quality
1. **Readability**
   - Code must be self-documenting with clear variable names
   - Complex logic must include explanatory comments
   - Functions should have a single, well-defined purpose
   - Maximum function length: 50 lines (excluding comments)

2. **Error Handling**
   - All functions must implement comprehensive error handling
   - Use try/catch blocks for all risky operations
   - Provide meaningful error messages with context
   - Log all errors with appropriate severity levels

3. **Performance**
   - Optimize for memory usage and execution speed
   - Avoid unnecessary loops and recursive operations
   - Use efficient data structures and algorithms
   - Implement caching where appropriate

### Code Review Requirements
1. **Mandatory Reviews**
   - All code changes require peer review before merge
   - Security-sensitive changes require security team review
   - Architecture changes require architect approval

2. **Review Checklist**
   - [ ] Code follows established patterns
   - [ ] Error handling is comprehensive
   - [ ] Tests are included and passing
   - [ ] Documentation is updated
   - [ ] Security implications are documented
   - [ ] Performance impact is assessed

---

## PowerShell Coding Conventions

### Script Structure
1. **Headers**
   ```powershell
   # BSD-3-Clause License header required
   # Author information
   # Purpose and usage description
   # Parameter documentation
   ```

2. **Module Self-Check Pattern**
   ```powershell
   if ($MyInvocation.InvocationName -ne '.') {
       # Running standalone - load dependencies
       Import-Module MGMT-Functions.psm1
       . .\MGMT-SHARED.ps1
   }
   ```

3. **Function Structure**
   ```powershell
   function Verb-Noun {
       [CmdletBinding()]
       param(
           [Parameter(Mandatory)]
           [ValidateNotNullOrEmpty()]
           [string]$RequiredParam,
           
           [Parameter()]
           [switch]$OptionalSwitch
       )
       
       try {
           # Function implementation
       }
       catch {
           WriteLog "Error in Verb-Noun: $($_.Exception.Message)" -Level "ERROR"
           throw
       }
   }
   ```

### Naming Conventions
1. **Functions**: Use approved PowerShell verbs (Get-, Set-, New-, Remove-, etc.)
2. **Variables**: Use PascalCase for function parameters, camelCase for local variables
3. **Constants**: Use UPPER_CASE with underscores
4. **Files**: Use hyphenated naming (MGMT-FileOps.ps1)

### PowerShell Best Practices
1. **Parameter Validation**
   - Use parameter attributes for validation
   - Provide meaningful parameter help
   - Use proper parameter sets for different usage patterns

2. **Output Handling**
   - Use Write-Output for function returns
   - Use WriteLog function for all logging
   - Avoid Write-Host except for interactive scripts

3. **Error Handling**
   - Use $ErrorActionPreference appropriately
   - Implement proper exception handling
   - Provide context in error messages

---

## JSON Schema Compliance

### Schema Requirements
1. **All JSON files must have corresponding schemas**
   - CONFIG.json ’ CONFIG.schema.json
   - FILE-OPS.json ’ FILE-OPS.schema.json
   - REG-OPS.json ’ REG-OPS.schema.json
   - DRIVE-OPS.json ’ DRIVE-OPS.schema.json
   - SYSTEM-OPS.json ’ SYSTEM-OPS.schema.json

2. **Schema Validation**
   - All JSON files must validate against their schemas
   - Use Validate-JsonSchema.ps1 for validation
   - Include schema validation in CI/CD pipeline

### JSON Structure Standards
1. **Consistent Property Naming**
   - Use camelCase for property names
   - Use descriptive, unambiguous property names
   - Maintain consistency across all JSON files

2. **Required Properties**
   - All operational objects must include required fields
   - Provide sensible defaults where appropriate
   - Document all properties in corresponding schemas

3. **Schema Evolution**
   - Maintain backward compatibility when updating schemas
   - Version schemas when breaking changes are necessary
   - Provide migration tools for schema updates

---

## Architecture and Design Guidelines

### Modular Design
1. **Helper Script Pattern**
   - Each operation type has dedicated helper script (MGMT-*.ps1)
   - Helper scripts are called by MAIN.PS1 orchestrator
   - Clear separation of concerns between helpers

2. **Configuration Management**
   - Global configuration in CONFIG.json
   - Operation-specific directives in *-OPS.json files
   - Environment-specific overrides supported

3. **Module Structure**
   - Core functions in MGMT-Functions.psm1
   - Shared variables and logging in MGMT-SHARED.ps1
   - Clear dependency management

### System Integration
1. **Windows Version Support**
   - Windows 10/11 Enterprise required
   - PowerShell 5.1 minimum, PowerShell 7+ preferred
   - x64/ARM64 architecture support only

2. **Deployment Targets**
   - Microsoft Intune integration
   - NinjaOne RMM support
   - Scheduled task execution model

### Future Architecture Considerations
1. **System Agent Development**
   - .NET 8+ Worker Service implementation
   - SYSTEM-level operations capability
   - PowerShell hosting for script execution

2. **Update Mechanism**
   - GitHub-based update distribution
   - Configuration preservation during updates
   - Rollback capability for failed updates

---

## Development Workflow

### Environment Setup
1. **Development Environment**
   - Primary development on macOS using VS Code
   - Windows VMs required for PowerShell testing
   - Git repository management from macOS

2. **Testing Requirements**
   - Windows VM testing mandatory before commit
   - Both PowerShell 5.1 and 7+ testing required
   - Integration testing with real JSON configurations

### Branching Strategy
1. **Branch Naming**
   - `feature/description` for new features
   - `bugfix/description` for bug fixes
   - `hotfix/description` for urgent fixes
   - `release/version` for release preparation

2. **Merge Requirements**
   - All tests must pass
   - Code review approval required
   - Documentation updates included
   - Security review for sensitive changes

### Release Process
1. **Version Management**
   - Semantic versioning (MAJOR.MINOR.PATCH)
   - Update CHANGELOG.TXT for all releases
   - Tag releases in Git repository

2. **Release Artifacts**
   - PowerShell scripts and modules
   - JSON schemas and examples
   - JsonEditorTool binaries (x64/ARM64)
   - Deployment packages (.intunewin, NinjaOne)

---

## Testing Requirements

### Test Categories
1. **Unit Tests**
   - All functions in MGMT-Functions.psm1
   - Individual helper script functions
   - JSON schema validation logic
   - Mock external dependencies

2. **Integration Tests**
   - End-to-end operation testing
   - JSON file processing workflows
   - Cross-module interaction validation
   - Real Windows environment testing

3. **Scenario Tests**
   - Fresh installation scenarios
   - Upgrade and migration testing
   - Error recovery and rollback
   - Performance and load testing

### Test Implementation
1. **Pester Framework**
   - Use Pester 5.x for all PowerShell tests
   - Maintain test configurations in /tests directory
   - Separate unit, integration, and scenario tests

2. **Test Data**
   - Provide representative test JSON files
   - Mock external dependencies appropriately
   - Test both success and failure scenarios

3. **Continuous Integration**
   - Automated test execution on commit
   - Multiple PowerShell version testing
   - Test result reporting and archival

### Test Coverage Requirements
- Minimum 80% code coverage for core functions
- 100% coverage for security-sensitive operations
- All JSON schema validations must be tested
- Error handling paths must be validated

---

## Documentation Standards

### Code Documentation
1. **Inline Documentation**
   - All functions must include PowerShell help comments
   - Complex algorithms require explanatory comments
   - Business logic must be documented with reasoning

2. **PowerShell Help Format**
   ```powershell
   <#
   .SYNOPSIS
       Brief description of function purpose
   
   .DESCRIPTION
       Detailed description of function behavior
   
   .PARAMETER ParameterName
       Description of parameter purpose and constraints
   
   .EXAMPLE
       Example usage with expected output
   
   .NOTES
       Additional notes, dependencies, or limitations
   #>
   ```

### Project Documentation
1. **Architectural Documentation**
   - System architecture diagrams
   - Data flow documentation
   - Integration point documentation
   - Deployment architecture guides

2. **User Documentation**
   - Installation and setup guides
   - Configuration reference documentation
   - Troubleshooting guides
   - FAQ and common issues

3. **Developer Documentation**
   - Development environment setup
   - Contributing guidelines
   - API reference documentation
   - Testing procedures

### Documentation Maintenance
1. **Version Control**
   - All documentation in Git repository
   - Version documentation with code changes
   - Maintain historical documentation versions

2. **Review Process**
   - Documentation reviews with code reviews
   - User acceptance testing for user docs
   - Regular documentation audits

---

## Cross-Platform Development

### Development Environment Considerations
1. **macOS Development**
   - Primary development environment is macOS
   - Use VS Code with PowerShell extension
   - Git operations performed from macOS

2. **Windows Testing Requirements**
   - Windows VMs required for all PowerShell testing
   - Test on both Windows 10 and Windows 11
   - Validate on both x64 and ARM64 architectures

3. **PowerShell Compatibility**
   - Code must work on PowerShell 5.1 (Windows PowerShell)
   - Prefer PowerShell 7+ features when available
   - Use `$PSVersionTable` for version detection

### File Path Handling
1. **Path Separators**
   - Use `Join-Path` for all path construction
   - Never hardcode backslashes or forward slashes
   - Test path handling on different platforms

2. **Case Sensitivity**
   - Assume case-sensitive file systems during development
   - Use exact case matching for file names
   - Test on Windows (case-insensitive) systems

### Line Endings
1. **Git Configuration**
   - Configure Git for appropriate line ending handling
   - Use `.gitattributes` for file-specific settings
   - Ensure PowerShell scripts use Windows line endings

---

## Enterprise Deployment Requirements

### Scalability Considerations
1. **Performance at Scale**
   - Design for 10,000+ endpoint deployments
   - Minimize resource consumption per endpoint
   - Optimize for network bandwidth efficiency

2. **Configuration Management**
   - Support centralized configuration distribution
   - Enable configuration templates and inheritance
   - Provide configuration validation tools

### Deployment Packaging
1. **Intune Deployment**
   - Create .intunewin packages using IntuneWinAppUtil
   - Include detection rules and requirements
   - Provide uninstall and update capabilities

2. **NinjaOne Integration**
   - Package for NinjaOne application deployment
   - Include monitoring and health checks
   - Support remote configuration management

3. **Manual Installation**
   - Provide standalone installation scripts
   - Support both user and administrator installation
   - Include verification and health check tools

### Monitoring and Maintenance
1. **Health Monitoring**
   - Implement health check mechanisms
   - Provide status reporting capabilities
   - Enable remote monitoring integration

2. **Update Management**
   - Support automatic update checking
   - Provide manual update procedures
   - Ensure configuration preservation during updates

---

## Error Handling and Logging

### Logging Standards
1. **WriteLog Function Usage**
   - All logging must use the standard WriteLog function
   - Include appropriate log levels (INFO, WARN, ERROR, DEBUG)
   - Provide meaningful, actionable log messages

2. **Log Level Guidelines**
   - `INFO`: Normal operational messages
   - `WARN`: Potential issues that don't prevent operation
   - `ERROR`: Failures that prevent normal operation
   - `DEBUG`: Detailed diagnostic information

3. **Log Message Format**
   ```powershell
   WriteLog "Operation completed successfully: $operationName" -Level "INFO"
   WriteLog "Configuration file not found: $configPath" -Level "WARN"
   WriteLog "Failed to process operation: $($_.Exception.Message)" -Level "ERROR"
   ```

### Error Handling Patterns
1. **Exception Handling**
   ```powershell
   try {
       # Risky operation
       $result = Invoke-SomeOperation -Parameter $value
   }
   catch [System.UnauthorizedAccessException] {
       WriteLog "Access denied: $($_.Exception.Message)" -Level "ERROR"
       # Handle specific exception type
   }
   catch {
       WriteLog "Unexpected error: $($_.Exception.Message)" -Level "ERROR"
       throw  # Re-throw if can't handle gracefully
   }
   ```

2. **Input Validation**
   - Validate all inputs before processing
   - Provide clear error messages for invalid inputs
   - Use PowerShell parameter validation where possible

3. **Resource Cleanup**
   - Use try/finally blocks for resource cleanup
   - Ensure temporary files are always removed
   - Close file handles and network connections properly

### Error Recovery
1. **Graceful Degradation**
   - Continue operation when non-critical components fail
   - Provide fallback mechanisms for optional features
   - Document known limitations and workarounds

2. **Rollback Capabilities**
   - Implement rollback for destructive operations
   - Maintain backup copies of modified files
   - Provide manual recovery procedures

---

## Performance and Reliability

### Performance Requirements
1. **Execution Time**
   - Individual operations should complete within 30 seconds
   - Full configuration run should complete within 5 minutes
   - Optimize for minimal system impact during execution

2. **Resource Usage**
   - Memory usage should not exceed 100MB per process
   - Minimize CPU usage during non-critical operations
   - Clean up temporary files and registry entries

3. **Network Efficiency**
   - Minimize network calls during operation
   - Implement caching for remote resources
   - Support offline operation modes

### Reliability Standards
1. **Fault Tolerance**
   - Handle network interruptions gracefully
   - Recover from partial failures automatically
   - Provide detailed status information for failures

2. **Data Integrity**
   - Validate configuration data before application
   - Maintain checksums for critical files
   - Implement atomic operations where possible

3. **Monitoring and Alerting**
   - Provide health check endpoints
   - Support integration with monitoring systems
   - Alert on critical failures or anomalies

### Performance Testing
1. **Load Testing**
   - Test with realistic configuration sizes
   - Validate performance under concurrent operations
   - Measure resource consumption over time

2. **Stress Testing**
   - Test failure scenarios and recovery
   - Validate behavior under resource constraints
   - Test with malformed or corrupted configurations

---

## Version Control Standards

### Commit Standards
1. **Commit Message Format**
   ```
   type(scope): subject

   body

   footer
   ```
   
   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   
   Examples:
   - `feat(mgmt-fileops): add support for symbolic links`
   - `fix(config): resolve JSON schema validation error`
   - `docs(readme): update installation instructions`

2. **Commit Content**
   - Each commit should represent a logical unit of work
   - Include tests with feature implementations
   - Update documentation with functional changes
   - Ensure commits don't break existing functionality

### Branch Management
1. **Protected Branches**
   - `main` branch requires pull request reviews
   - No direct commits to `main` branch
   - Require passing tests before merge

2. **Feature Development**
   - Create feature branches from `main`
   - Use descriptive branch names
   - Rebase before creating pull requests
   - Delete feature branches after merge

### Code Review Process
1. **Review Requirements**
   - At least one approval required for merge
   - Security-sensitive changes require security team review
   - Breaking changes require architect approval

2. **Review Guidelines**
   - Review for code quality and standards compliance
   - Verify test coverage and documentation
   - Validate security implications
   - Check for performance impact

---

## AI Agent Guidelines

### AI Assistant Interaction
1. **Context Awareness**
   - AI agents must understand the project's security-first approach
   - Consider enterprise scale implications in all recommendations
   - Respect cross-platform development constraints

2. **Code Generation Guidelines**
   - Always include comprehensive error handling
   - Follow established PowerShell coding conventions
   - Include appropriate logging and documentation
   - Validate generated code against project standards

3. **Testing Considerations**
   - Include unit tests with code generation
   - Consider integration testing requirements
   - Validate against JSON schemas where applicable

### Development Workflow Integration
1. **Cross-Platform Awareness**
   - Remember that testing requires Windows VMs
   - Plan for handoff to human developers for Windows testing
   - Provide clear testing instructions

2. **Security Focus**
   - Always consider security implications of suggestions
   - Highlight potential security risks in recommendations
   - Suggest secure alternatives for risky operations

3. **Documentation Expectations**
   - Update relevant documentation with code changes
   - Provide clear explanations of architectural decisions
   - Include troubleshooting guidance where appropriate

---

## Enforcement and Compliance

### Automated Validation
1. **Pre-commit Hooks**
   - PowerShell script syntax validation
   - JSON schema compliance checking
   - Code style and formatting validation

2. **Continuous Integration**
   - Automated test execution
   - Security vulnerability scanning
   - Performance regression testing

### Manual Review Process
1. **Code Review Checklist**
   - Compliance with coding standards
   - Security implications assessment
   - Performance impact evaluation
   - Documentation completeness

2. **Architecture Review**
   - Alignment with project principles
   - Scalability and maintainability assessment
   - Integration impact analysis

### Non-Compliance Handling
1. **Issue Resolution**
   - Document compliance violations
   - Provide remediation guidance
   - Track resolution progress

2. **Process Improvement**
   - Regular review of rules effectiveness
   - Update standards based on lessons learned
   - Continuous improvement of automation

---

## Conclusion

These rules establish the foundation for consistent, secure, and maintainable development of the EndpointPilot project. All contributors must understand and follow these guidelines to ensure the project's success at enterprise scale.

For questions or clarifications regarding these rules, consult the project documentation or reach out to the development team leads.

**Document Version**: 1.0  
**Last Updated**: 2025-08-21  
**Next Review**: 2025-11-21
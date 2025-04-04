using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Schema;
using EndpointPilotJsonEditor.Core.Models;

namespace EndpointPilotJsonEditor.Core.Services
{
    /// <summary>
    /// Service for validating JSON against schemas
    /// </summary>
    public class SchemaValidationService
    {
        private string _baseDirectory;

        /// <summary>
        /// Gets or sets the base directory for schema files
        /// </summary>
        public string BaseDirectory
        {
            get => _baseDirectory;
            set
            {
                _baseDirectory = value;
                _schemaCache.Clear(); // Clear cache when directory changes
            }
        }
        private readonly Dictionary<string, JSchema> _schemaCache = new Dictionary<string, JSchema>();

        /// <summary>
        /// Initializes a new instance of the SchemaValidationService class
        /// </summary>
        /// <param name="baseDirectory">The base directory for schema files</param>
        public SchemaValidationService(string baseDirectory)
        {
            _baseDirectory = baseDirectory;
        }

        /// <summary>
        /// Gets a schema from the cache or loads it from disk
        /// </summary>
        /// <param name="schemaFileName">The name of the schema file</param>
        /// <returns>The JSON schema</returns>
        private async Task<JSchema> GetSchemaAsync(string schemaFileName)
        {
            if (_schemaCache.TryGetValue(schemaFileName, out var cachedSchema))
            {
                return cachedSchema;
            }

            var schemaPath = Path.Combine(_baseDirectory, schemaFileName);
            if (!File.Exists(schemaPath))
            {
                throw new FileNotFoundException($"Schema file not found: {schemaPath}");
            }

            var schemaJson = await File.ReadAllTextAsync(schemaPath);
            var schema = JSchema.Parse(schemaJson);
            _schemaCache[schemaFileName] = schema;
            return schema;
        }

        /// <summary>
        /// Validates a configuration against its schema
        /// </summary>
        /// <param name="config">The configuration to validate</param>
        /// <param name="schemaFileName">The name of the schema file</param>
        /// <returns>A validation result</returns>
        public async Task<ValidationResult> ValidateConfigAsync(ConfigModel config, string schemaFileName = "CONFIG.schema.json")
        {
            try
            {
                var schema = await GetSchemaAsync(schemaFileName);
                var json = JObject.FromObject(config);
                
                var isValid = json.IsValid(schema, out IList<string> errorMessages);
                return new ValidationResult(isValid, errorMessages);
            }
            catch (Exception ex)
            {
                return new ValidationResult(false, new[] { $"Validation error: {ex.Message}" });
            }
        }

        /// <summary>
        /// Validates file operations against their schema
        /// </summary>
        /// <param name="operations">The operations to validate</param>
        /// <param name="schemaFileName">The name of the schema file</param>
        /// <returns>A validation result</returns>
        public async Task<ValidationResult> ValidateFileOperationsAsync(List<FileOperation> operations, string schemaFileName = "FILE-OPS.schema.json")
        {
            try
            {
                var schema = await GetSchemaAsync(schemaFileName);
                var json = JArray.FromObject(operations);
                
                var isValid = json.IsValid(schema, out IList<string> errorMessages);
                return new ValidationResult(isValid, errorMessages);
            }
            catch (Exception ex)
            {
                return new ValidationResult(false, new[] { $"Validation error: {ex.Message}" });
            }
        }

        /// <summary>
        /// Validates registry operations against their schema
        /// </summary>
        /// <param name="operations">The operations to validate</param>
        /// <param name="schemaFileName">The name of the schema file</param>
        /// <returns>A validation result</returns>
        public async Task<ValidationResult> ValidateRegOperationsAsync(List<RegOperation> operations, string schemaFileName = "REG-OPS.schema.json")
        {
            try
            {
                var schema = await GetSchemaAsync(schemaFileName);
                var json = JArray.FromObject(operations);
                
                var isValid = json.IsValid(schema, out IList<string> errorMessages);
                return new ValidationResult(isValid, errorMessages);
            }
            catch (Exception ex)
            {
                return new ValidationResult(false, new[] { $"Validation error: {ex.Message}" });
            }
        }

        /// <summary>
        /// Validates drive operations against their schema
        /// </summary>
        /// <param name="operations">The operations to validate</param>
        /// <param name="schemaFileName">The name of the schema file</param>
        /// <returns>A validation result</returns>
        public async Task<ValidationResult> ValidateDriveOperationsAsync(List<DriveOperation> operations, string schemaFileName = "DRIVE-OPS.schema.json")
        {
            try
            {
                var schema = await GetSchemaAsync(schemaFileName);
                var json = JArray.FromObject(operations);
                
                var isValid = json.IsValid(schema, out IList<string> errorMessages);
                return new ValidationResult(isValid, errorMessages);
            }
            catch (Exception ex)
            {
                return new ValidationResult(false, new[] { $"Validation error: {ex.Message}" });
            }
        }
    }

    /// <summary>
    /// Represents the result of a validation operation
    /// </summary>
    public class ValidationResult
    {
        /// <summary>
        /// Gets a value indicating whether the validation was successful
        /// </summary>
        public bool IsValid { get; }

        /// <summary>
        /// Gets the error messages if the validation failed
        /// </summary>
        public IEnumerable<string> ErrorMessages { get; }

        /// <summary>
        /// Initializes a new instance of the ValidationResult class
        /// </summary>
        /// <param name="isValid">Whether the validation was successful</param>
        /// <param name="errorMessages">The error messages if the validation failed</param>
        public ValidationResult(bool isValid, IEnumerable<string> errorMessages)
        {
            IsValid = isValid;
            ErrorMessages = errorMessages ?? Enumerable.Empty<string>();
        }
    }
}
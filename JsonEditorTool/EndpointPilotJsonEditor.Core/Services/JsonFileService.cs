using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using Newtonsoft.Json;
using EndpointPilotJsonEditor.Core.Models;

namespace EndpointPilotJsonEditor.Core.Services
{
    /// <summary>
    /// Service for reading and writing JSON files
    /// </summary>
    public class JsonFileService
    {
        private string _baseDirectory;
        private readonly CryptographicService _cryptographicService;

        /// <summary>
        /// Gets or sets the base directory for JSON files
        /// </summary>
        public string BaseDirectory
        {
            get => _baseDirectory;
            set => _baseDirectory = value;
        }

        /// <summary>
        /// Initializes a new instance of the JsonFileService class
        /// </summary>
        /// <param name="baseDirectory">The base directory for JSON files</param>
        public JsonFileService(string baseDirectory)
        {
            _baseDirectory = baseDirectory;
            _cryptographicService = new CryptographicService();
        }

        /// <summary>
        /// Reads a configuration file
        /// </summary>
        /// <param name="fileName">The name of the file to read</param>
        /// <returns>The configuration model</returns>
        public async Task<ConfigModel> ReadConfigAsync(string fileName = "CONFIG.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            if (!File.Exists(filePath))
            {
                return new ConfigModel();
            }

            var json = await File.ReadAllTextAsync(filePath);
            return JsonConvert.DeserializeObject<ConfigModel>(json) ?? new ConfigModel();
        }

        /// <summary>
        /// Writes a configuration file
        /// </summary>
        /// <param name="config">The configuration model to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteConfigAsync(ConfigModel config, string fileName = "CONFIG.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            var json = JsonConvert.SerializeObject(config, Formatting.Indented);
            
            // Create a backup before writing
            if (File.Exists(filePath))
            {
                var backupPath = $"{filePath}.bak";
                File.Copy(filePath, backupPath, true);
            }

            await File.WriteAllTextAsync(filePath, json);
        }

        /// <summary>
        /// Reads file operations
        /// </summary>
        /// <param name="fileName">The name of the file to read</param>
        /// <returns>The list of file operations</returns>
        public async Task<List<FileOperation>> ReadFileOperationsAsync(string fileName = "FILE-OPS.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            if (!File.Exists(filePath))
            {
                return new List<FileOperation>();
            }

            var json = await File.ReadAllTextAsync(filePath);
            return JsonConvert.DeserializeObject<List<FileOperation>>(json) ?? new List<FileOperation>();
        }

        /// <summary>
        /// Writes file operations
        /// </summary>
        /// <param name="operations">The list of file operations to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteFileOperationsAsync(List<FileOperation> operations, string fileName = "FILE-OPS.json")
        {
            await WriteFileOperationsAsync(operations, fileName, null);
        }

        /// <summary>
        /// Writes file operations with optional digital signing
        /// </summary>
        /// <param name="operations">The list of file operations to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <param name="signingCertificate">Certificate to use for signing operations (null for no signing)</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteFileOperationsAsync(List<FileOperation> operations, string fileName, X509Certificate2? signingCertificate)
        {
            // Sign operations if certificate is provided
            if (signingCertificate != null)
            {
                foreach (var operation in operations)
                {
                    _cryptographicService.SignOperation(operation, signingCertificate);
                }
            }

            var filePath = Path.Combine(_baseDirectory, fileName);
            var json = JsonConvert.SerializeObject(operations, Formatting.Indented);
            
            // Create a backup before writing
            if (File.Exists(filePath))
            {
                var backupPath = $"{filePath}.bak";
                File.Copy(filePath, backupPath, true);
            }

            await File.WriteAllTextAsync(filePath, json);
        }

        /// <summary>
        /// Reads registry operations
        /// </summary>
        /// <param name="fileName">The name of the file to read</param>
        /// <returns>The list of registry operations</returns>
        public async Task<List<RegOperation>> ReadRegOperationsAsync(string fileName = "REG-OPS.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            if (!File.Exists(filePath))
            {
                return new List<RegOperation>();
            }

            var json = await File.ReadAllTextAsync(filePath);
            return JsonConvert.DeserializeObject<List<RegOperation>>(json) ?? new List<RegOperation>();
        }

        /// <summary>
        /// Writes registry operations
        /// </summary>
        /// <param name="operations">The list of registry operations to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteRegOperationsAsync(List<RegOperation> operations, string fileName = "REG-OPS.json")
        {
            await WriteRegOperationsAsync(operations, fileName, null);
        }

        /// <summary>
        /// Writes registry operations with optional digital signing
        /// </summary>
        /// <param name="operations">The list of registry operations to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <param name="signingCertificate">Certificate to use for signing operations (null for no signing)</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteRegOperationsAsync(List<RegOperation> operations, string fileName, X509Certificate2? signingCertificate)
        {
            // Sign operations if certificate is provided
            if (signingCertificate != null)
            {
                foreach (var operation in operations)
                {
                    _cryptographicService.SignOperation(operation, signingCertificate);
                }
            }

            var filePath = Path.Combine(_baseDirectory, fileName);
            var json = JsonConvert.SerializeObject(operations, Formatting.Indented);
            
            // Create a backup before writing
            if (File.Exists(filePath))
            {
                var backupPath = $"{filePath}.bak";
                File.Copy(filePath, backupPath, true);
            }

            await File.WriteAllTextAsync(filePath, json);
        }

        /// <summary>
        /// Reads drive operations
        /// </summary>
        /// <param name="fileName">The name of the file to read</param>
        /// <returns>The list of drive operations</returns>
        public async Task<List<DriveOperation>> ReadDriveOperationsAsync(string fileName = "DRIVE-OPS.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            if (!File.Exists(filePath))
            {
                return new List<DriveOperation>();
            }

            var json = await File.ReadAllTextAsync(filePath);
            return JsonConvert.DeserializeObject<List<DriveOperation>>(json) ?? new List<DriveOperation>();
        }

        /// <summary>
        /// Writes drive operations
        /// </summary>
        /// <param name="operations">The list of drive operations to write</param>
        /// <param name="fileName">The name of the file to write</param>
        /// <returns>A task representing the asynchronous operation</returns>
        public async Task WriteDriveOperationsAsync(List<DriveOperation> operations, string fileName = "DRIVE-OPS.json")
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            var json = JsonConvert.SerializeObject(operations, Formatting.Indented);
            
            // Create a backup before writing
            if (File.Exists(filePath))
            {
                var backupPath = $"{filePath}.bak";
                File.Copy(filePath, backupPath, true);
            }

            await File.WriteAllTextAsync(filePath, json);
        }

        /// <summary>
        /// Restores a file from its backup
        /// </summary>
        /// <param name="fileName">The name of the file to restore</param>
        /// <returns>True if the restore was successful, false otherwise</returns>
        public bool RestoreFromBackup(string fileName)
        {
            var filePath = Path.Combine(_baseDirectory, fileName);
            var backupPath = $"{filePath}.bak";

            if (!File.Exists(backupPath))
            {
                return false;
            }

            File.Copy(backupPath, filePath, true);
            return true;
        }

        /// <summary>
        /// Gets the cryptographic service for signing and validation operations
        /// </summary>
        /// <returns>The cryptographic service instance</returns>
        public CryptographicService GetCryptographicService()
        {
            return _cryptographicService;
        }

        /// <summary>
        /// Validates signatures for a collection of operations
        /// </summary>
        /// <param name="operations">The operations to validate</param>
        /// <returns>Dictionary mapping operation IDs to their validation results</returns>
        public Dictionary<string, SignatureValidationResult> ValidateOperationSignatures<T>(List<T> operations) 
            where T : OperationBase
        {
            var results = new Dictionary<string, SignatureValidationResult>();
            
            foreach (var operation in operations)
            {
                var result = _cryptographicService.ValidateSignature(operation);
                results[operation.Id] = result;
            }

            return results;
        }
    }
}
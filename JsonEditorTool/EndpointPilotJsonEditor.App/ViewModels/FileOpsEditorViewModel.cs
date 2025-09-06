using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for editing FILE-OPS.json
    /// </summary>
    public class FileOpsEditorViewModel : OperationEditorViewModelBase<FileOperation>
    {
        private string _sourceFilename;
        private string _destinationFilename;
        private string _sourcePath;
        private string _destinationPath;
        private bool _overwrite;
        private bool _copyOnce;
        private string _existCheckLocation;
        private bool _existCheck;
        private bool _deleteFile;
        private string _targetingType;
        private string _target;
        private string _comment1;
        private string _comment2;
        private bool _requiresAdmin;
        private string _adminContext;

        /// <summary>
        /// Gets or sets the source filename
        /// </summary>
        public string SourceFilename
        {
            get => _sourceFilename;
            set
            {
                if (SetProperty(ref _sourceFilename, value) && SelectedOperation != null)
                {
                    SelectedOperation.SourceFilename = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the destination filename
        /// </summary>
        public string DestinationFilename
        {
            get => _destinationFilename;
            set
            {
                if (SetProperty(ref _destinationFilename, value) && SelectedOperation != null)
                {
                    SelectedOperation.DestinationFilename = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the source path
        /// </summary>
        public string SourcePath
        {
            get => _sourcePath;
            set
            {
                if (SetProperty(ref _sourcePath, value) && SelectedOperation != null)
                {
                    SelectedOperation.SourcePath = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the destination path
        /// </summary>
        public string DestinationPath
        {
            get => _destinationPath;
            set
            {
                if (SetProperty(ref _destinationPath, value) && SelectedOperation != null)
                {
                    SelectedOperation.DestinationPath = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to overwrite existing files
        /// </summary>
        public bool Overwrite
        {
            get => _overwrite;
            set
            {
                if (SetProperty(ref _overwrite, value) && SelectedOperation != null)
                {
                    SelectedOperation.Overwrite = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to copy the file only once
        /// </summary>
        public bool CopyOnce
        {
            get => _copyOnce;
            set
            {
                if (SetProperty(ref _copyOnce, value) && SelectedOperation != null)
                {
                    SelectedOperation.CopyOnce = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the location to check for existence
        /// </summary>
        public string ExistCheckLocation
        {
            get => _existCheckLocation;
            set
            {
                if (SetProperty(ref _existCheckLocation, value) && SelectedOperation != null)
                {
                    SelectedOperation.ExistCheckLocation = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to check if file exists
        /// </summary>
        public bool ExistCheck
        {
            get => _existCheck;
            set
            {
                if (SetProperty(ref _existCheck, value) && SelectedOperation != null)
                {
                    SelectedOperation.ExistCheck = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to delete the file
        /// </summary>
        public bool DeleteFile
        {
            get => _deleteFile;
            set
            {
                if (SetProperty(ref _deleteFile, value) && SelectedOperation != null)
                {
                    SelectedOperation.DeleteFile = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the targeting type
        /// </summary>
        public string TargetingType
        {
            get => _targetingType;
            set
            {
                if (SetProperty(ref _targetingType, value) && SelectedOperation != null)
                {
                    SelectedOperation.TargetingType = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the target
        /// </summary>
        public string Target
        {
            get => _target;
            set
            {
                if (SetProperty(ref _target, value) && SelectedOperation != null)
                {
                    SelectedOperation.Target = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the first comment
        /// </summary>
        public string Comment1
        {
            get => _comment1;
            set
            {
                if (SetProperty(ref _comment1, value) && SelectedOperation != null)
                {
                    SelectedOperation.Comment1 = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the second comment
        /// </summary>
        public string Comment2
        {
            get => _comment2;
            set
            {
                if (SetProperty(ref _comment2, value) && SelectedOperation != null)
                {
                    SelectedOperation.Comment2 = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets the available targeting types
        /// </summary>
        public string[] TargetingTypes => new[] { "none", "group", "computer", "user" };

        /// <summary>
        /// Gets or sets whether this operation requires administrative privileges
        /// </summary>
        public bool RequiresAdmin
        {
            get => _requiresAdmin;
            set
            {
                if (SetProperty(ref _requiresAdmin, value) && SelectedOperation != null)
                {
                    SelectedOperation.RequiresAdmin = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the admin context when admin is required
        /// </summary>
        public string AdminContext
        {
            get => _adminContext;
            set
            {
                if (SetProperty(ref _adminContext, value) && SelectedOperation != null)
                {
                    SelectedOperation.AdminContext = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets the available admin context options
        /// </summary>
        public string[] AdminContexts => FileOperation.AvailableAdminContexts;

        /// <summary>
        /// Initializes a new instance of the FileOpsEditorViewModel class
        /// </summary>
        /// <param name="operations">The file operations</param>
        /// <param name="jsonFileService">The JSON file service</param>
        /// <param name="schemaValidationService">The schema validation service</param>
        public FileOpsEditorViewModel(IEnumerable<FileOperation> operations, JsonFileService jsonFileService, SchemaValidationService schemaValidationService)
            : base(operations, jsonFileService, schemaValidationService)
        {
            // Set the selected operation if there are any operations
            if (Operations.Any())
            {
                SelectedOperation = Operations.First();
            }
            ValidateAsync(); // Call initial validation after full initialization
        }

        /// <summary>
        /// Updates the property values when the selected operation changes
        /// </summary>
        protected override void OnPropertyChanged(string propertyName = null)
        {
            base.OnPropertyChanged(propertyName);

            if (propertyName == nameof(SelectedOperation) && SelectedOperation != null)
            {
                _sourceFilename = SelectedOperation.SourceFilename;
                _destinationFilename = SelectedOperation.DestinationFilename;
                _sourcePath = SelectedOperation.SourcePath;
                _destinationPath = SelectedOperation.DestinationPath;
                _overwrite = SelectedOperation.Overwrite;
                _copyOnce = SelectedOperation.CopyOnce;
                _existCheckLocation = SelectedOperation.ExistCheckLocation;
                _existCheck = SelectedOperation.ExistCheck;
                _deleteFile = SelectedOperation.DeleteFile;
                _targetingType = SelectedOperation.TargetingType;
                _target = SelectedOperation.Target;
                _comment1 = SelectedOperation.Comment1;
                _comment2 = SelectedOperation.Comment2;
                _requiresAdmin = SelectedOperation.RequiresAdmin;
                _adminContext = SelectedOperation.AdminContext;

                base.OnPropertyChanged(nameof(SourceFilename));
                base.OnPropertyChanged(nameof(DestinationFilename));
                base.OnPropertyChanged(nameof(SourcePath));
                base.OnPropertyChanged(nameof(DestinationPath));
                base.OnPropertyChanged(nameof(Overwrite));
                base.OnPropertyChanged(nameof(CopyOnce));
                base.OnPropertyChanged(nameof(ExistCheckLocation));
                base.OnPropertyChanged(nameof(ExistCheck));
                base.OnPropertyChanged(nameof(DeleteFile));
                base.OnPropertyChanged(nameof(TargetingType));
                base.OnPropertyChanged(nameof(Target));
                base.OnPropertyChanged(nameof(Comment1));
                base.OnPropertyChanged(nameof(Comment2));
                base.OnPropertyChanged(nameof(RequiresAdmin));
                base.OnPropertyChanged(nameof(AdminContext));
            }
        }

        /// <summary>
        /// Adds a new file operation
        /// </summary>
        protected override void AddOperation()
        {
            var newId = Operations.Any() ? Operations.Max(o => int.Parse(o.Id)) + 1 : 1;
            var newOperation = new FileOperation
            {
                Id = newId.ToString("D3"),
                SourceFilename = "example.txt",
                DestinationFilename = "example.txt",
                SourcePath = "C:\\example\\source",
                DestinationPath = "C:\\example\\destination",
                TargetingType = "none",
                Target = "all",
                RequiresAdmin = false,
                AdminContext = "auto",
                Comment1 = "New file operation"
            };

            Operations.Add(newOperation);
            SelectedOperation = newOperation;
            IsModified = true;
            ValidateAsync();
        }

        /// <summary>
        /// Duplicates the selected operation
        /// </summary>
        protected override void DuplicateOperation()
        {
            if (SelectedOperation != null)
            {
                var newId = Operations.Max(o => int.Parse(o.Id)) + 1;
                var newOperation = new FileOperation
                {
                    Id = newId.ToString("D3"),
                    SourceFilename = SelectedOperation.SourceFilename,
                    DestinationFilename = SelectedOperation.DestinationFilename,
                    SourcePath = SelectedOperation.SourcePath,
                    DestinationPath = SelectedOperation.DestinationPath,
                    Overwrite = SelectedOperation.Overwrite,
                    CopyOnce = SelectedOperation.CopyOnce,
                    ExistCheckLocation = SelectedOperation.ExistCheckLocation,
                    ExistCheck = SelectedOperation.ExistCheck,
                    DeleteFile = SelectedOperation.DeleteFile,
                    TargetingType = SelectedOperation.TargetingType,
                    Target = SelectedOperation.Target,
                    RequiresAdmin = SelectedOperation.RequiresAdmin,
                    AdminContext = SelectedOperation.AdminContext,
                    Comment1 = SelectedOperation.Comment1,
                    Comment2 = SelectedOperation.Comment2
                };

                Operations.Add(newOperation);
                SelectedOperation = newOperation;
                IsModified = true;
                ValidateAsync();
            }
        }

        /// <summary>
        /// Validates the operations
        /// </summary>
        protected override async Task ValidateAsync()
        {
            // Skip validation during editing to prevent errors while typing
            // Only validate when saving
            IsValid = true;
            OnStatusChanged("Validation will be performed when saving", false);
        }

        /// <summary>
        /// Performs full validation against the schema
        /// </summary>
        private async Task PerformFullValidationAsync()
        {
            try
            {
                // Normalize paths if needed (similar to what we did for DriveOps)
                foreach (var operation in Operations)
                {
                    // Add any path normalization logic here if needed for FILE-OPS
                }

                var result = await _schemaValidationService.ValidateFileOperationsAsync(Operations.ToList());
                IsValid = result.IsValid;

                if (result.IsValid)
                {
                    OnStatusChanged("File operations are valid", false);
                }
                else
                {
                    var errorMessage = string.Join(Environment.NewLine, result.ErrorMessages);
                    OnStatusChanged($"File operations are invalid: {errorMessage}", true);
                }
            }
            catch (Exception ex)
            {
                IsValid = false;
                OnStatusChanged($"Validation error: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Saves the operations
        /// </summary>
        protected override async Task SaveAsync()
        {
            try
            {
                // Perform full validation before saving
                await PerformFullValidationAsync();
                
                // Only save if validation passes
                if (IsValid)
                {
                    await _jsonFileService.WriteFileOperationsAsync(Operations.ToList());
                    IsModified = false;
                    OnStatusChanged("File operations saved successfully", false);
                    
                    // Reload operations after saving to refresh the UI
                    await ReloadAsync();
                }
                else
                {
                    OnStatusChanged("Cannot save: File operations contain validation errors", true);
                }
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error saving file operations: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Reloads the operations
        /// </summary>
        protected override async Task ReloadAsync()
        {
            try
            {
                var operations = await _jsonFileService.ReadFileOperationsAsync();
                Operations.Clear();
                foreach (var operation in operations)
                {
                    Operations.Add(operation);
                }

                if (Operations.Any())
                {
                    SelectedOperation = Operations.First();
                }
                else
                {
                    SelectedOperation = null;
                }

                IsModified = false;
                ValidateAsync();
                OnStatusChanged("File operations reloaded successfully", false);
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error reloading file operations: {ex.Message}", true);
            }
        }
    }
}
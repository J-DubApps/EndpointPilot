using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;
using Newtonsoft.Json.Schema;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for editing DRIVE-OPS.json
    /// </summary>
    public class DriveOpsEditorViewModel : OperationEditorViewModelBase<DriveOperation>
    {
        private string _driveLetter;
        private string _drivePath;
        private bool _reconnect;
        private bool _delete;
        private bool _hidden;
        private string _targetingType;
        private string _target;
        private string _comment1;
        private string _comment2;

        /// <summary>
        /// Gets or sets the drive letter
        /// </summary>
        public string DriveLetter
        {
            get => _driveLetter;
            set
            {
                if (SetProperty(ref _driveLetter, value) && SelectedOperation != null)
                {
                    SelectedOperation.DriveLetter = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the drive path
        /// </summary>
        public string DrivePath
        {
            get => _drivePath;
            set
            {
                // Ensure UNC paths always start with double backslashes to meet schema requirements
                string normalizedValue = value;
                
                if (normalizedValue != null)
                {
                    // If it starts with a single backslash but not double, add another backslash
                    if (normalizedValue.StartsWith(@"\") && !normalizedValue.StartsWith(@"\\"))
                    {
                        normalizedValue = @"\" + normalizedValue;
                    }
                    // If it doesn't start with any backslash, add two backslashes
                    else if (!normalizedValue.StartsWith(@"\"))
                    {
                        normalizedValue = @"\\" + normalizedValue;
                    }
                }

                if (SetProperty(ref _drivePath, normalizedValue) && SelectedOperation != null)
                {
                    SelectedOperation.DrivePath = normalizedValue;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to reconnect the drive
        /// </summary>
        public bool Reconnect
        {
            get => _reconnect;
            set
            {
                if (SetProperty(ref _reconnect, value) && SelectedOperation != null)
                {
                    SelectedOperation.Reconnect = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to delete the drive mapping
        /// </summary>
        public bool Delete
        {
            get => _delete;
            set
            {
                if (SetProperty(ref _delete, value) && SelectedOperation != null)
                {
                    SelectedOperation.Delete = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to hide the drive
        /// </summary>
        public bool Hidden
        {
            get => _hidden;
            set
            {
                if (SetProperty(ref _hidden, value) && SelectedOperation != null)
                {
                    SelectedOperation.Hidden = value;
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
        /// Gets the available drive letters
        /// </summary>
        public string[] DriveLetters => DriveOperation.AvailableDriveLetters;

        /// <summary>
        /// Gets the available targeting types
        /// </summary>
        public string[] TargetingTypes => new[] { "none", "group", "computer", "user" };

        /// <summary>
        /// Initializes a new instance of the DriveOpsEditorViewModel class
        /// </summary>
        /// <param name="operations">The drive operations</param>
        /// <param name="jsonFileService">The JSON file service</param>
        /// <param name="schemaValidationService">The schema validation service</param>
        public DriveOpsEditorViewModel(IEnumerable<DriveOperation> operations, JsonFileService jsonFileService, SchemaValidationService schemaValidationService)
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
                _driveLetter = SelectedOperation.DriveLetter;
                
                // Normalize the drive path to ensure UNC paths have double backslashes
                string normalizedPath = SelectedOperation.DrivePath;
                if (normalizedPath != null)
                {
                    // If it starts with a single backslash but not double, add another backslash
                    if (normalizedPath.StartsWith(@"\") && !normalizedPath.StartsWith(@"\\"))
                    {
                        normalizedPath = @"\" + normalizedPath;
                        // Update the model with the normalized path
                        SelectedOperation.DrivePath = normalizedPath;
                    }
                    // If it doesn't start with any backslash, add two backslashes
                    else if (!normalizedPath.StartsWith(@"\"))
                    {
                        normalizedPath = @"\\" + normalizedPath;
                        // Update the model with the normalized path
                        SelectedOperation.DrivePath = normalizedPath;
                    }
                }
                _drivePath = normalizedPath;
                
                _reconnect = SelectedOperation.Reconnect;
                _delete = SelectedOperation.Delete;
                _hidden = SelectedOperation.Hidden;
                _targetingType = SelectedOperation.TargetingType;
                _target = SelectedOperation.Target;
                _comment1 = SelectedOperation.Comment1;
                _comment2 = SelectedOperation.Comment2;

                base.OnPropertyChanged(nameof(DriveLetter));
                base.OnPropertyChanged(nameof(DrivePath));
                base.OnPropertyChanged(nameof(Reconnect));
                base.OnPropertyChanged(nameof(Delete));
                base.OnPropertyChanged(nameof(Hidden));
                base.OnPropertyChanged(nameof(TargetingType));
                base.OnPropertyChanged(nameof(Target));
                base.OnPropertyChanged(nameof(Comment1));
                base.OnPropertyChanged(nameof(Comment2));
            }
        }

        /// <summary>
        /// Adds a new drive operation
        /// </summary>
        protected override void AddOperation()
        {
            var newId = Operations.Any() ? Operations.Max(o => int.Parse(o.Id)) + 1 : 1;
            var newOperation = new DriveOperation
            {
                Id = newId.ToString("D3"),
                DriveLetter = "F:",
                DrivePath = "\\\\server\\share", // This is correct: in C# string literals, \\ represents a single backslash
                TargetingType = "none",
                Target = "all",
                Comment1 = "New drive mapping"
            };

            // Ensure the path meets schema requirements
            string normalizedPath = newOperation.DrivePath;
            if (normalizedPath != null)
            {
                // If it starts with a single backslash but not double, add another backslash
                if (normalizedPath.StartsWith(@"\") && !normalizedPath.StartsWith(@"\\"))
                {
                    normalizedPath = @"\" + normalizedPath;
                    newOperation.DrivePath = normalizedPath;
                }
                // If it doesn't start with any backslash, add two backslashes
                else if (!normalizedPath.StartsWith(@"\"))
                {
                    normalizedPath = @"\\" + normalizedPath;
                    newOperation.DrivePath = normalizedPath;
                }
            }

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
                
                // Normalize the drive path before duplicating
                string normalizedPath = SelectedOperation.DrivePath;
                if (normalizedPath != null)
                {
                    // If it starts with a single backslash but not double, add another backslash
                    if (normalizedPath.StartsWith(@"\") && !normalizedPath.StartsWith(@"\\"))
                    {
                        normalizedPath = @"\" + normalizedPath;
                    }
                    // If it doesn't start with any backslash, add two backslashes
                    else if (!normalizedPath.StartsWith(@"\"))
                    {
                        normalizedPath = @"\\" + normalizedPath;
                    }
                }
                
                var newOperation = new DriveOperation
                {
                    Id = newId.ToString("D3"),
                    DriveLetter = SelectedOperation.DriveLetter,
                    DrivePath = normalizedPath,
                    Reconnect = SelectedOperation.Reconnect,
                    Delete = SelectedOperation.Delete,
                    Hidden = SelectedOperation.Hidden,
                    TargetingType = SelectedOperation.TargetingType,
                    Target = SelectedOperation.Target,
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
            // Skip validation during editing to prevent regex errors while typing
            // Only validate when saving
            IsValid = true;
            OnStatusChanged("Validation will be performed when saving", false);
        }

        /// <summary>
        /// Performs full validation against the schema
        /// </summary>
        private async Task PerformFullValidationAsync()
        {
            const string schemaFileName = "DRIVE-OPS.schema.json"; // Define schema name
            try
            {
                // Ensure all paths are normalized before validation
                foreach (var operation in Operations)
                {
                    if (operation.DrivePath != null)
                    {
                        // If it starts with a single backslash but not double, add another backslash
                        if (operation.DrivePath.StartsWith(@"\") && !operation.DrivePath.StartsWith(@"\\"))
                        {
                            operation.DrivePath = @"\" + operation.DrivePath;
                        }
                        // If it doesn't start with any backslash, add two backslashes
                        else if (!operation.DrivePath.StartsWith(@"\"))
                        {
                            operation.DrivePath = @"\\" + operation.DrivePath;
                        }
                    }
                }

                // 1. Serialize current operations to JSON string
                var operationsJson = Newtonsoft.Json.JsonConvert.SerializeObject(Operations.ToList(), Newtonsoft.Json.Formatting.None);

                // 2. Parse the string back into a JArray
                var jsonToValidate = Newtonsoft.Json.Linq.JArray.Parse(operationsJson);

                // 3. Get the schema
                var schema = await _schemaValidationService.GetSchemaAsync(schemaFileName);

                // 4. Validate the parsed JArray
                var isValid = jsonToValidate.IsValid(schema, out IList<string> errorMessages);
                var result = new ValidationResult(isValid, errorMessages); // Create result object
                IsValid = result.IsValid;

                if (result.IsValid)
                {
                    OnStatusChanged("Drive operations are valid", false);
                }
                else
                {
                    var errorMessage = string.Join(Environment.NewLine, result.ErrorMessages);
                    OnStatusChanged($"Drive operations are invalid: {errorMessage}", true);
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
                    await _jsonFileService.WriteDriveOperationsAsync(Operations.ToList());
                    IsModified = false;
                    OnStatusChanged("Drive operations saved successfully", false);
                    
                    // Reload operations after saving to refresh the UI with normalized paths
                    await ReloadAsync();
                }
                else
                {
                    OnStatusChanged("Cannot save: Drive operations contain validation errors", true);
                }
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error saving drive operations: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Reloads the operations
        /// </summary>
        protected override async Task ReloadAsync()
        {
            try
            {
                var operations = await _jsonFileService.ReadDriveOperationsAsync();
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
                OnStatusChanged("Drive operations reloaded successfully", false);
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error reloading drive operations: {ex.Message}", true);
            }
        }
    }
}
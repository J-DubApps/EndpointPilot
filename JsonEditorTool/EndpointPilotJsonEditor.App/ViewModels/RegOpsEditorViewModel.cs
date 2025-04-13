using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for editing REG-OPS.json
    /// </summary>
    public class RegOpsEditorViewModel : OperationEditorViewModelBase<RegOperation>
    {
        private string _name;
        private string _path;
        private string _selectedHive;
        private string _pathSuffix;
        private string _value;
        private string _regType;
        private bool _writeOnceAsBool;
        private bool _delete;
        private string _targetingType;
        private string _target;
        private string _comment1;
        private string _comment2;

        /// <summary>
        /// Gets or sets the registry value name
        /// </summary>
        public string Name
        {
            get => _name;
            set
            {
                if (SetProperty(ref _name, value) && SelectedOperation != null)
                {
                    SelectedOperation.Name = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets the registry key path
        /// </summary>
        public string Path
        {
            get => _path;
            set
            {
                if (SetProperty(ref _path, value) && SelectedOperation != null)
                {
                    SelectedOperation.Path = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets the selected registry hive
        /// </summary>
        public string SelectedHive
        {
            get => _selectedHive;
            set
            {
                if (SetProperty(ref _selectedHive, value) && SelectedOperation != null)
                {
                    UpdatePath();
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets the path suffix (after the hive)
        /// </summary>
        public string PathSuffix
        {
            get => _pathSuffix;
            set
            {
                if (SetProperty(ref _pathSuffix, value) && SelectedOperation != null)
                {
                    UpdatePath();
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets the registry value
        /// </summary>
        public string Value
        {
            get => _value;
            set
            {
                if (SetProperty(ref _value, value) && SelectedOperation != null)
                {
                    SelectedOperation.Value = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets the registry value type
        /// </summary>
        public string RegType
        {
            get => _regType;
            set
            {
                if (SetProperty(ref _regType, value) && SelectedOperation != null)
                {
                    SelectedOperation.RegType = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to write the registry value only once
        /// </summary>
        public bool WriteOnceAsBool
        {
            get => _writeOnceAsBool;
            set
            {
                if (SetProperty(ref _writeOnceAsBool, value) && SelectedOperation != null)
                {
                    SelectedOperation.WriteOnceAsBool = value;
                    OnPropertyChanged(nameof(SelectedOperation));
                    IsModified = true;
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to delete the registry value
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
                    Validate();
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
                    Validate();
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
                    Validate();
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
                    Validate();
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
                    Validate();
                }
            }
        }

        /// <summary>
        /// Gets the available registry value types
        /// </summary>
        public string[] RegTypes => RegOperation.AvailableRegTypes;

        /// <summary>
        /// Gets the available registry hives
        /// </summary>
        public string[] RegistryHives => RegOperation.AvailableHives;

        /// <summary>
        /// Gets the available targeting types
        /// </summary>
        public string[] TargetingTypes => new[] { "none", "group", "computer", "user" };

        /// <summary>
        /// Initializes a new instance of the RegOpsEditorViewModel class
        /// </summary>
        /// <param name="operations">The registry operations</param>
        /// <param name="jsonFileService">The JSON file service</param>
        /// <param name="schemaValidationService">The schema validation service</param>
        public RegOpsEditorViewModel(IEnumerable<RegOperation> operations, JsonFileService jsonFileService, SchemaValidationService schemaValidationService)
            : base(operations, jsonFileService, schemaValidationService)
        {
            // Initialize backing fields
            _name = string.Empty;
            _path = string.Empty;
            _selectedHive = string.Empty;
            _pathSuffix = string.Empty;
            _value = string.Empty;
            _regType = string.Empty;
            _targetingType = string.Empty;
            _target = string.Empty;
            _comment1 = string.Empty;
            _comment2 = string.Empty;

            // Set the selected operation if there are any operations
            if (Operations.Any())
            {
                SelectedOperation = Operations.FirstOrDefault(); // Use FirstOrDefault
            }
             // Trigger property updates if an item was selected
            if (SelectedOperation != null)
            {
                 OnPropertyChanged(nameof(SelectedOperation)); // Manually trigger update for initial selection
            }
            Validate(); // Call initial validation (now synchronous)
        }

        /// <summary>
        /// Updates the property values when the selected operation changes
        /// </summary>
        protected override void OnPropertyChanged(string? propertyName = null) // Make propertyName nullable
        {
            base.OnPropertyChanged(propertyName);

            if (propertyName == nameof(SelectedOperation) && SelectedOperation != null)
            {
                // Parse the path into hive and suffix
                ParsePath();
                
                // Use null-coalescing operator to provide default empty strings if properties are null
                _name = SelectedOperation.Name ?? string.Empty;
                _path = SelectedOperation.Path ?? string.Empty;
                _value = SelectedOperation.Value ?? string.Empty;
                _regType = SelectedOperation.RegType ?? string.Empty;
                _writeOnceAsBool = SelectedOperation.WriteOnceAsBool;
                _delete = SelectedOperation.Delete;
                _targetingType = SelectedOperation.TargetingType ?? string.Empty;
                _target = SelectedOperation.Target ?? string.Empty;
                _comment1 = SelectedOperation.Comment1 ?? string.Empty;
                _comment2 = SelectedOperation.Comment2 ?? string.Empty;

                base.OnPropertyChanged(nameof(Name));
                base.OnPropertyChanged(nameof(Path));
                base.OnPropertyChanged(nameof(SelectedHive));
                base.OnPropertyChanged(nameof(PathSuffix));
                base.OnPropertyChanged(nameof(Value));
                base.OnPropertyChanged(nameof(RegType));
                base.OnPropertyChanged(nameof(WriteOnceAsBool));
                base.OnPropertyChanged(nameof(Delete));
                base.OnPropertyChanged(nameof(TargetingType));
                base.OnPropertyChanged(nameof(Target));
                base.OnPropertyChanged(nameof(Comment1));
                base.OnPropertyChanged(nameof(Comment2));
            }
        }

        /// <summary>
        /// Adds a new registry operation
        /// </summary>
        protected override void AddOperation()
        {
            // Safely calculate the next ID
            int maxId = 0;
            if (Operations.Any())
            {
                maxId = Operations.Max(o => int.TryParse(o.Id, out int id) ? id : 0);
            }
            var newId = (maxId + 1).ToString("D3");
            var newOperation = new RegOperation
            {
                Id = newId,
                Name = "NewValue",
                Path = "HKEY_CURRENT_USER\\Software\\Example",
                Value = "1",
                RegType = "dword",
                WriteOnce = "false",
                TargetingType = "none",
                Target = "all",
                Comment1 = "New registry operation"
            };

            Operations.Add(newOperation);
            SelectedOperation = newOperation;
            IsModified = true;
            Validate();
        }

        /// <summary>
        /// Parses the path into hive and suffix
        /// </summary>
        private void ParsePath()
        {
            _path = SelectedOperation?.Path ?? string.Empty; // Use null conditional operator

            // Find the first backslash after the hive
            int index = _path.IndexOf('\\');
            if (index > 0 && index < _path.Length) // Ensure index is valid
            {
                _selectedHive = _path.Substring(0, index);
                _pathSuffix = _path.Substring(index); // Get the rest including the first backslash
            }
            else
            {
                // If no backslash or path is just the hive, assume it's the hive
                _selectedHive = RegistryHives.Contains(_path) ? _path : RegistryHives.FirstOrDefault() ?? string.Empty;
                _pathSuffix = string.Empty;
            }
        }

        /// <summary>
        /// Updates the path from the hive and suffix
        /// </summary>
        private void UpdatePath()
        {
            if (SelectedOperation != null) // Check if SelectedOperation is not null
            {
                 SelectedOperation.Path = $"{_selectedHive}{_pathSuffix}";
                 _path = SelectedOperation.Path; // Update local backing field as well
                 OnPropertyChanged(nameof(Path)); // Notify UI that Path might have changed
            }
            _path = SelectedOperation.Path;
            OnPropertyChanged(nameof(Path));
        }

        /// <summary>
        /// Duplicates the selected operation
        /// </summary>
        protected override void DuplicateOperation()
        {
            if (SelectedOperation != null)
            {
                // Safely calculate the next ID
                int maxId = 0;
                if (Operations.Any())
                {
                     maxId = Operations.Max(o => int.TryParse(o.Id, out int id) ? id : 0);
                }
                var newId = (maxId + 1).ToString("D3");
                var newOperation = new RegOperation
                {
                    Id = newId,
                    Name = SelectedOperation.Name,
                    Path = SelectedOperation.Path,
                    Value = SelectedOperation.Value,
                    RegType = SelectedOperation.RegType,
                    WriteOnce = SelectedOperation!.WriteOnce, // Use null-forgiving operator
                    Delete = SelectedOperation.Delete,
                    TargetingType = SelectedOperation.TargetingType,
                    Target = SelectedOperation.Target,
                    Comment1 = SelectedOperation.Comment1,
                    Comment2 = SelectedOperation.Comment2
                };

                Operations.Add(newOperation);
                SelectedOperation = newOperation;
                IsModified = true;
                Validate();
            }
        }

        /// <summary>
        /// Validates the operations
        /// </summary>
        protected override void Validate() // Change to void, remove async
        {
            // Skip validation during editing to prevent errors while typing
            // Only validate when saving
             // This validation is intentionally minimal during editing.
            // Full validation happens in PerformFullValidationAsync before saving.
            IsValid = true; // Assume valid during editing unless PerformFullValidationAsync fails
             // Optionally clear status or set a generic "Editing..." message
            // OnStatusChanged("Editing...", false);
        }

        /// <summary>
        /// Performs full validation against the schema
        /// </summary>
        private async Task PerformFullValidationAsync()
        {
            try
            {
                var result = await _schemaValidationService.ValidateRegOperationsAsync(Operations.ToList());
                IsValid = result.IsValid;

                if (result.IsValid)
                {
                    OnStatusChanged("Registry operations are valid", false);
                }
                else
                {
                    var errorMessage = string.Join(Environment.NewLine, result.ErrorMessages);
                    OnStatusChanged($"Registry operations are invalid: {errorMessage}", true);
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
                    await _jsonFileService.WriteRegOperationsAsync(Operations.ToList());
                    IsModified = false;
                    OnStatusChanged("Registry operations saved successfully", false);
                    
                    // Reload operations after saving to refresh the UI
                    await ReloadAsync();
                }
                else
                {
                    OnStatusChanged("Cannot save: Registry operations contain validation errors", true);
                }
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error saving registry operations: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Reloads the operations
        /// </summary>
        protected override async Task ReloadAsync()
        {
            try
            {
                var operations = await _jsonFileService.ReadRegOperationsAsync();
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
                Validate(); // Call synchronous version
                OnStatusChanged("Registry operations reloaded successfully", false);
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error reloading registry operations: {ex.Message}", true);
            }
        }
    }
}
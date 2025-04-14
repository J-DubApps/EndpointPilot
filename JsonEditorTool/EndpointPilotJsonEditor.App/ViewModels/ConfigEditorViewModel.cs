using System;
using System.Threading.Tasks;
using System.Windows.Input;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for editing CONFIG.json
    /// </summary>
    public class ConfigEditorViewModel : ViewModelBase
    {
        private readonly JsonFileService _jsonFileService;
        private readonly SchemaValidationService _schemaValidationService;
        private ConfigModel _config;
        private bool _isModified;
        private bool _isValid;

        /// <summary>
        /// Occurs when the status changes
        /// </summary>
        public event EventHandler<StatusChangedEventArgs> StatusChanged;

        /// <summary>
        /// Gets or sets the organization name
        /// </summary>
        public string OrgName
        {
            get => _config.OrgName;
            set
            {
                if (_config.OrgName != value)
                {
                    _config.OrgName = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the refresh interval in minutes
        /// </summary>
        public int RefreshInterval
        {
            get => _config.RefreshInterval;
            set
            {
                if (_config.RefreshInterval != value)
                {
                    _config.RefreshInterval = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the network script root path
        /// </summary>
        public string NetworkScriptRootPath
        {
            get => _config.NetworkScriptRootPath;
            set
            {
                if (_config.NetworkScriptRootPath != value)
                {
                    _config.NetworkScriptRootPath = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether the network script root is enabled
        /// </summary>
        public bool NetworkScriptRootEnabled
        {
            get => _config.NetworkScriptRootEnabled;
            set
            {
                if (_config.NetworkScriptRootEnabled != value)
                {
                    _config.NetworkScriptRootEnabled = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync(); // Note: We might need to adjust async/await later
                }
            }

        /// <summary>
        /// Gets or sets whether the HTTPS script root is enabled
        /// </summary>
        public bool HttpsScriptRootEnabled
        {
            get => _config.HttpsScriptRootEnabled;
            set
            {
                if (_config.HttpsScriptRootEnabled != value)
                {
                    _config.HttpsScriptRootEnabled = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync(); // Note: We might need to adjust async/await later
                }
            }
        }

        /// <summary>
        /// Gets or sets the HTTPS script root path
        /// </summary>
        public string HttpsScriptRootPath
        {
            get => _config.HttpsScriptRootPath;
            set
            {
                if (_config.HttpsScriptRootPath != value)
                {
                    _config.HttpsScriptRootPath = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync(); // Note: We might need to adjust async/await later
                }
            }
        }

        // Removed extra closing brace


        /// <summary>
        /// Gets or sets whether to copy log files to network location
        /// </summary>
        public bool CopyLogFileToNetwork
        {
            get => _config.CopyLogFileToNetwork;
            set
            {
                if (_config.CopyLogFileToNetwork != value)
                {
                    _config.CopyLogFileToNetwork = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to enable file roaming
        /// </summary>
        public bool RoamFiles
        {
            get => _config.RoamFiles;
            set
            {
                if (_config.RoamFiles != value)
                {
                    _config.RoamFiles = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the network path for log files
        /// </summary>
        public string NetworkLogFile
        {
            get => _config.NetworkLogFile;
            set
            {
                if (_config.NetworkLogFile != value)
                {
                    _config.NetworkLogFile = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets the network path for roaming files
        /// </summary>
        public string NetworkRoamFolder
        {
            get => _config.NetworkRoamFolder;
            set
            {
                if (_config.NetworkRoamFolder != value)
                {
                    _config.NetworkRoamFolder = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to skip file operations
        /// </summary>
        public bool SkipFileOps
        {
            get => _config.SkipFileOps;
            set
            {
                if (_config.SkipFileOps != value)
                {
                    _config.SkipFileOps = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to skip drive operations
        /// </summary>
        public bool SkipDriveOps
        {
            get => _config.SkipDriveOps;
            set
            {
                if (_config.SkipDriveOps != value)
                {
                    _config.SkipDriveOps = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to skip registry operations
        /// </summary>
        public bool SkipRegOps
        {
            get => _config.SkipRegOps;
            set
            {
                if (_config.SkipRegOps != value)
                {
                    _config.SkipRegOps = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to skip roaming operations
        /// </summary>
        public bool SkipRoamOps
        {
            get => _config.SkipRoamOps;
            set
            {
                if (_config.SkipRoamOps != value)
                {
                    _config.SkipRoamOps = value;
                    OnPropertyChanged();
                    IsModified = true;
                    ValidateAsync();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether the configuration has been modified
        /// </summary>
        public bool IsModified
        {
            get => _isModified;
            set => SetProperty(ref _isModified, value);
        }

        /// <summary>
        /// Gets or sets whether the configuration is valid
        /// </summary>
        public bool IsValid
        {
            get => _isValid;
            set => SetProperty(ref _isValid, value);
        }

        /// <summary>
        /// Gets the command to save the configuration
        /// </summary>
        public ICommand SaveCommand { get; }

        /// <summary>
        /// Gets the command to reload the configuration
        /// </summary>
        public ICommand ReloadCommand { get; }

        /// <summary>
        /// Initializes a new instance of the ConfigEditorViewModel class
        /// </summary>
        /// <param name="config">The configuration model</param>
        /// <param name="jsonFileService">The JSON file service</param>
        /// <param name="schemaValidationService">The schema validation service</param>
        public ConfigEditorViewModel(ConfigModel config, JsonFileService jsonFileService, SchemaValidationService schemaValidationService)
        {
            _config = config ?? new ConfigModel();
            _jsonFileService = jsonFileService;
            _schemaValidationService = schemaValidationService;

            SaveCommand = new RelayCommand(_ => SaveAsync(), _ => IsModified && IsValid);
            ReloadCommand = new RelayCommand(_ => ReloadAsync());

            ValidateAsync();
        }

        /// <summary>
        /// Validates the configuration
        /// </summary>
        private async void ValidateAsync()
        {
            try
            {
                var result = await _schemaValidationService.ValidateConfigAsync(_config);
                IsValid = result.IsValid;

                if (result.IsValid)
                {
                    OnStatusChanged("Configuration is valid", false);
                }
                else
                {
                    var errorMessage = string.Join(Environment.NewLine, result.ErrorMessages);
                    OnStatusChanged($"Configuration is invalid: {errorMessage}", true);
                }
            }
            catch (Exception ex)
            {
                IsValid = false;
                OnStatusChanged($"Validation error: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Saves the configuration
        /// </summary>
        private async void SaveAsync()
        {
            try
            {
                await _jsonFileService.WriteConfigAsync(_config);
                IsModified = false;
                OnStatusChanged("Configuration saved successfully", false);
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error saving configuration: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Reloads the configuration
        /// </summary>
        private async void ReloadAsync()
        {
            try
            {
                _config = await _jsonFileService.ReadConfigAsync();
                OnPropertyChanged(string.Empty); // Refresh all properties
                IsModified = false;
                ValidateAsync();
                OnStatusChanged("Configuration reloaded successfully", false);
            }
            catch (Exception ex)
            {
                OnStatusChanged($"Error reloading configuration: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Raises the StatusChanged event
        /// </summary>
        /// <param name="message">The status message</param>
        /// <param name="isError">Whether the status is an error</param>
        private void OnStatusChanged(string message, bool isError)
        {
            StatusChanged?.Invoke(this, new StatusChangedEventArgs(message, isError));
        }
    }
}
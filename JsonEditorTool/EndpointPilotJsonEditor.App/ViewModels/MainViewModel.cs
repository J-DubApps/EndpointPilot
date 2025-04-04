using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Input;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for the main window
    /// </summary>
    public class MainViewModel : ViewModelBase
    {
        private readonly JsonFileService _jsonFileService;
        private readonly SchemaValidationService _schemaValidationService;
        private ViewModelBase _currentEditor;
        private string _statusMessage;
        private bool _isStatusError;
        private string _workingDirectory;

        /// <summary>
        /// Gets or sets the current editor ViewModel
        /// </summary>
        public ViewModelBase CurrentEditor
        {
            get => _currentEditor;
            set => SetProperty(ref _currentEditor, value);
        }

        /// <summary>
        /// Gets or sets the status message
        /// </summary>
        public string StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        /// <summary>
        /// Gets or sets a value indicating whether the status is an error
        /// </summary>
        public bool IsStatusError
        {
            get => _isStatusError;
            set => SetProperty(ref _isStatusError, value);
        }

        /// <summary>
        /// Gets or sets the working directory
        /// </summary>
        public string WorkingDirectory
        {
            get => _workingDirectory;
            set
            {
                if (SetProperty(ref _workingDirectory, value))
                {
                    OnWorkingDirectoryChanged();
                }
            }
        }

        /// <summary>
        /// Gets the command to open the CONFIG editor
        /// </summary>
        public ICommand OpenConfigEditorCommand { get; }

        /// <summary>
        /// Gets the command to open the FILE-OPS editor
        /// </summary>
        public ICommand OpenFileOpsEditorCommand { get; }

        /// <summary>
        /// Gets the command to open the REG-OPS editor
        /// </summary>
        public ICommand OpenRegOpsEditorCommand { get; }

        /// <summary>
        /// Gets the command to open the DRIVE-OPS editor
        /// </summary>
        public ICommand OpenDriveOpsEditorCommand { get; }

        /// <summary>
        /// Gets the command to browse for a working directory
        /// </summary>
        public ICommand BrowseWorkingDirectoryCommand { get; }

        /// <summary>
        /// Event raised when the user wants to browse for a directory
        /// </summary>
        public event Action BrowseDirectoryRequested;

        /// <summary>
        /// Initializes a new instance of the MainViewModel class
        /// </summary>
        public MainViewModel()
        {
            // Default to the current directory
            _workingDirectory = Directory.GetCurrentDirectory();
            
            _jsonFileService = new JsonFileService(_workingDirectory);
            _schemaValidationService = new SchemaValidationService(_workingDirectory);

            OpenConfigEditorCommand = new RelayCommand(_ => OpenConfigEditor());
            OpenFileOpsEditorCommand = new RelayCommand(_ => OpenFileOpsEditor());
            OpenRegOpsEditorCommand = new RelayCommand(_ => OpenRegOpsEditor());
            OpenDriveOpsEditorCommand = new RelayCommand(_ => OpenDriveOpsEditor());
            BrowseWorkingDirectoryCommand = new RelayCommand(_ => BrowseWorkingDirectory());

            // Start with the CONFIG editor
            OpenConfigEditor();
        }

        /// <summary>
        /// Opens the CONFIG editor
        /// </summary>
        private async void OpenConfigEditor()
        {
            try
            {
                var config = await _jsonFileService.ReadConfigAsync();
                var configEditor = new ConfigEditorViewModel(config, _jsonFileService, _schemaValidationService);
                configEditor.StatusChanged += OnEditorStatusChanged;
                CurrentEditor = configEditor;
                SetStatus("CONFIG.json loaded successfully", false);
            }
            catch (Exception ex)
            {
                SetStatus($"Error loading CONFIG.json: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Opens the FILE-OPS editor
        /// </summary>
        private async void OpenFileOpsEditor()
        {
            try
            {
                var operations = await _jsonFileService.ReadFileOperationsAsync();
                var fileOpsEditor = new FileOpsEditorViewModel(operations, _jsonFileService, _schemaValidationService);
                fileOpsEditor.StatusChanged += OnEditorStatusChanged;
                CurrentEditor = fileOpsEditor;
                SetStatus("FILE-OPS.json loaded successfully", false);
            }
            catch (Exception ex)
            {
                SetStatus($"Error loading FILE-OPS.json: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Opens the REG-OPS editor
        /// </summary>
        private async void OpenRegOpsEditor()
        {
            try
            {
                var operations = await _jsonFileService.ReadRegOperationsAsync();
                var regOpsEditor = new RegOpsEditorViewModel(operations, _jsonFileService, _schemaValidationService);
                regOpsEditor.StatusChanged += OnEditorStatusChanged;
                CurrentEditor = regOpsEditor;
                SetStatus("REG-OPS.json loaded successfully", false);
            }
            catch (Exception ex)
            {
                SetStatus($"Error loading REG-OPS.json: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Opens the DRIVE-OPS editor
        /// </summary>
        private async void OpenDriveOpsEditor()
        {
            try
            {
                var operations = await _jsonFileService.ReadDriveOperationsAsync();
                var driveOpsEditor = new DriveOpsEditorViewModel(operations, _jsonFileService, _schemaValidationService);
                driveOpsEditor.StatusChanged += OnEditorStatusChanged;
                CurrentEditor = driveOpsEditor;
                SetStatus("DRIVE-OPS.json loaded successfully", false);
            }
            catch (Exception ex)
            {
                SetStatus($"Error loading DRIVE-OPS.json: {ex.Message}", true);
            }
        }

        /// <summary>
        /// Browses for a working directory
        /// </summary>
        private void BrowseWorkingDirectory()
        {
            // Raise the event to let the view handle the directory browsing
            BrowseDirectoryRequested?.Invoke();
        }

        /// <summary>
        /// Sets the status message
        /// </summary>
        /// <param name="message">The message to set</param>
        /// <param name="isError">Whether the message is an error</param>
        private void SetStatus(string message, bool isError)
        {
            StatusMessage = message;
            IsStatusError = isError;
        }

        /// <summary>
        /// Handles status changes from editors
        /// </summary>
        /// <param name="sender">The sender</param>
        /// <param name="e">The event args</param>
        private void OnEditorStatusChanged(object sender, StatusChangedEventArgs e)
        {
            SetStatus(e.Message, e.IsError);
        }

        /// <summary>
        /// Handles changes to the working directory
        /// </summary>
        private void OnWorkingDirectoryChanged()
        {
            // Update the services with the new working directory
            _jsonFileService.BaseDirectory = _workingDirectory;
            _schemaValidationService.BaseDirectory = _workingDirectory;

            // Reload the current editor
            if (CurrentEditor is ConfigEditorViewModel)
            {
                OpenConfigEditor();
            }
            else if (CurrentEditor is FileOpsEditorViewModel)
            {
                OpenFileOpsEditor();
            }
            else if (CurrentEditor is RegOpsEditorViewModel)
            {
                OpenRegOpsEditor();
            }
            else if (CurrentEditor is DriveOpsEditorViewModel)
            {
                OpenDriveOpsEditor();
            }
        }
    }

    /// <summary>
    /// Event args for status changes
    /// </summary>
    public class StatusChangedEventArgs : EventArgs
    {
        /// <summary>
        /// Gets the status message
        /// </summary>
        public string Message { get; }

        /// <summary>
        /// Gets a value indicating whether the status is an error
        /// </summary>
        public bool IsError { get; }

        /// <summary>
        /// Initializes a new instance of the StatusChangedEventArgs class
        /// </summary>
        /// <param name="message">The status message</param>
        /// <param name="isError">Whether the status is an error</param>
        public StatusChangedEventArgs(string message, bool isError)
        {
            Message = message;
            IsError = isError;
        }
    }
}
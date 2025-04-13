using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// Base class for operation editor ViewModels
    /// </summary>
    /// <typeparam name="T">The type of operation</typeparam>
    public abstract class OperationEditorViewModelBase<T> : ViewModelBase where T : OperationBase
    {
        protected readonly JsonFileService _jsonFileService;
        protected readonly SchemaValidationService _schemaValidationService;
        protected ObservableCollection<T> _operations;
        protected T? _selectedOperation; // Make nullable
        protected bool _isModified;
        protected bool _isValid;

        /// <summary>
        /// Occurs when the status changes
        /// </summary>
        public event EventHandler<StatusChangedEventArgs>? StatusChanged; // Make nullable

        /// <summary>
        /// Gets or sets the operations
        /// </summary>
        public ObservableCollection<T> Operations
        {
            get => _operations;
            set => SetProperty(ref _operations, value);
        }

        /// <summary>
        /// Gets or sets the selected operation
        /// </summary>
        public T? SelectedOperation // Return nullable type
        {
            get => _selectedOperation;
            set => SetProperty(ref _selectedOperation, value); // Set nullable type
        }

        /// <summary>
        /// Gets or sets whether the operations have been modified
        /// </summary>
        public bool IsModified
        {
            get => _isModified;
            set => SetProperty(ref _isModified, value);
        }

        /// <summary>
        /// Gets or sets whether the operations are valid
        /// </summary>
        public bool IsValid
        {
            get => _isValid;
            set => SetProperty(ref _isValid, value);
        }

        /// <summary>
        /// Gets the command to add a new operation
        /// </summary>
        public ICommand AddOperationCommand { get; }

        /// <summary>
        /// Gets the command to remove the selected operation
        /// </summary>
        public ICommand RemoveOperationCommand { get; }

        /// <summary>
        /// Gets the command to duplicate the selected operation
        /// </summary>
        public ICommand DuplicateOperationCommand { get; }

        /// <summary>
        /// Gets the command to move the selected operation up
        /// </summary>
        public ICommand MoveUpCommand { get; }

        /// <summary>
        /// Gets the command to move the selected operation down
        /// </summary>
        public ICommand MoveDownCommand { get; }

        /// <summary>
        /// Gets the command to save the operations
        /// </summary>
        public ICommand SaveCommand { get; }

        /// <summary>
        /// Gets the command to reload the operations
        /// </summary>
        public ICommand ReloadCommand { get; }

        /// <summary>
        /// Initializes a new instance of the OperationEditorViewModelBase class
        /// </summary>
        /// <param name="operations">The operations</param>
        /// <param name="jsonFileService">The JSON file service</param>
        /// <param name="schemaValidationService">The schema validation service</param>
        protected OperationEditorViewModelBase(IEnumerable<T> operations, JsonFileService jsonFileService, SchemaValidationService schemaValidationService)
        {
            _operations = new ObservableCollection<T>(operations ?? Enumerable.Empty<T>());
            _jsonFileService = jsonFileService;
            _schemaValidationService = schemaValidationService;

            AddOperationCommand = new RelayCommand(_ => AddOperation());
            // Pass null check predicate directly
            RemoveOperationCommand = new RelayCommand(_ => RemoveOperation(), _ => SelectedOperation is not null);
            DuplicateOperationCommand = new RelayCommand(_ => DuplicateOperation(), _ => SelectedOperation is not null);
            MoveUpCommand = new RelayCommand(_ => MoveUp(), _ => CanMoveUp()); // CanMoveUp already checks for null
            MoveDownCommand = new RelayCommand(_ => MoveDown(), _ => CanMoveDown()); // CanMoveDown already checks for null
            SaveCommand = new RelayCommand(_ => SaveAsync(), _ => IsModified && IsValid);
            ReloadCommand = new RelayCommand(_ => ReloadAsync());
            // ValidateAsync(); // Removed from base constructor
        }

        /// <summary>
        /// Adds a new operation
        /// </summary>
        protected abstract void AddOperation();

        /// <summary>
        /// Removes the selected operation
        /// </summary>
        protected virtual void RemoveOperation()
        {
            if (SelectedOperation != null)
            {
                var index = Operations.IndexOf(SelectedOperation);
                Operations.Remove(SelectedOperation);
                IsModified = true;
                ValidateAsync();

                // Select the next operation, or the last one if we removed the last operation
                if (Operations.Count > 0)
                {
                    SelectedOperation = Operations[Math.Min(index, Operations.Count - 1)];
                }
                else
                {
                    SelectedOperation = null;
                }
            }
        }

        /// <summary>
        /// Duplicates the selected operation
        /// </summary>
        protected abstract void DuplicateOperation();

        /// <summary>
        /// Moves the selected operation up
        /// </summary>
        protected virtual void MoveUp()
        {
            if (CanMoveUp())
            {
                var index = Operations.IndexOf(SelectedOperation);
                Operations.Move(index, index - 1);
                IsModified = true;
                ValidateAsync();
            }
        }

        /// <summary>
        /// Moves the selected operation down
        /// </summary>
        protected virtual void MoveDown()
        {
            if (CanMoveDown())
            {
                var index = Operations.IndexOf(SelectedOperation);
                Operations.Move(index, index + 1);
                IsModified = true;
                ValidateAsync();
            }
        }

        /// <summary>
        /// Determines whether the selected operation can be moved up
        /// </summary>
        /// <returns>True if the operation can be moved up, false otherwise</returns>
        protected virtual bool CanMoveUp()
        {
            if (SelectedOperation == null)
            {
                return false;
            }

            var index = Operations.IndexOf(SelectedOperation);
            return index > 0;
        }

        /// <summary>
        /// Determines whether the selected operation can be moved down
        /// </summary>
        /// <returns>True if the operation can be moved down, false otherwise</returns>
        protected virtual bool CanMoveDown()
        {
            if (SelectedOperation == null)
            {
                return false;
            }

            var index = Operations.IndexOf(SelectedOperation);
            return index < Operations.Count - 1;
        }

        /// <summary>
        /// Validates the operations
        /// </summary>
        protected abstract void Validate(); // Change to void to match derived classes

        /// <summary>
        /// Saves the operations
        /// </summary>
        protected abstract Task SaveAsync();

        /// <summary>
        /// Reloads the operations
        /// </summary>
        protected abstract Task ReloadAsync();

        /// <summary>
        /// Raises the StatusChanged event
        /// </summary>
        /// <param name="message">The status message</param>
        /// <param name="isError">Whether the status is an error</param>
        protected void OnStatusChanged(string message, bool isError)
        {
            StatusChanged?.Invoke(this, new StatusChangedEventArgs(message, isError));
        }
    }
}
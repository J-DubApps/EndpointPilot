using System;
using System.Windows.Input;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// A command whose sole purpose is to relay its functionality to other
    /// objects by invoking delegates
    /// </summary>
    public class RelayCommand : ICommand
    {
        private readonly Action<object> _execute;
        private readonly Predicate<object?>? _canExecute; // Make predicate nullable and accept nullable object

        /// <summary>
        /// Initializes a new instance of the RelayCommand class
        /// </summary>
        /// <param name="execute">The execution logic</param>
        /// <param name="canExecute">The execution status logic</param>
        public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null) // Accept nullable parameter and predicate
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute; // Assign nullable predicate
        }

        /// <summary>
        /// Occurs when changes occur that affect whether the command should execute
        /// </summary>
        public event EventHandler? CanExecuteChanged // Make event nullable
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }

        /// <summary>
        /// Defines the method that determines whether the command can execute in its current state
        /// </summary>
        /// <param name="parameter">Data used by the command</param>
        /// <returns>True if this command can be executed; otherwise, false</returns>
        public bool CanExecute(object? parameter) // Accept nullable parameter
        {
            return _canExecute == null || _canExecute(parameter); // Pass nullable parameter to predicate
        }

        /// <summary>
        /// Defines the method to be called when the command is invoked
        /// </summary>
        /// <param name="parameter">Data used by the command</param>
        public void Execute(object? parameter) // Accept nullable parameter
        {
#pragma warning disable CS8604 // Possible null reference argument. - Delegate type Action<object?> explicitly allows null.
            _execute(parameter); // Pass nullable parameter to action
#pragma warning restore CS8604 // Possible null reference argument.
        }

        /// <summary>
        /// Raises the CanExecuteChanged event
        /// </summary>
        public void RaiseCanExecuteChanged()
        {
            CommandManager.InvalidateRequerySuggested();
        }
    }
}
using System;
using System.Windows;
using Microsoft.Win32;
using EndpointPilotJsonEditor.App.ViewModels;

namespace EndpointPilotJsonEditor.App
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly MainViewModel _viewModel;

        /// <summary>
        /// Initializes a new instance of the MainWindow class
        /// </summary>
        public MainWindow()
        {
            InitializeComponent();

            _viewModel = new MainViewModel();
            _viewModel.BrowseDirectoryRequested += BrowseWorkingDirectory;
            DataContext = _viewModel;
        }

        /// <summary>
        /// Browses for a working directory
        /// </summary>
        private void BrowseWorkingDirectory()
        {
            var dialog = new OpenFileDialog
            {
                Title = "Select the directory containing EndpointPilot JSON files",
                CheckFileExists = false,
                CheckPathExists = true,
                FileName = "Select Folder",
                ValidateNames = false
            };

            if (dialog.ShowDialog() == true)
            {
                // Get the directory path from the selected file path
                string? directoryPath = System.IO.Path.GetDirectoryName(dialog.FileName); // Make directoryPath nullable
                if (directoryPath != null) // Check for null before assigning
                {
                    _viewModel.WorkingDirectory = directoryPath;
                }
                // Optional: Add an else block here to handle the case where directoryPath is null (e.g., show an error message)
            }
        }
    }
}
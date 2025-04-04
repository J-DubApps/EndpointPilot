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
            DataContext = _viewModel;

            // Hook up the browse working directory command
            _viewModel.BrowseWorkingDirectoryCommand = new RelayCommand(_ => BrowseWorkingDirectory());
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
                string directoryPath = System.IO.Path.GetDirectoryName(dialog.FileName);
                _viewModel.WorkingDirectory = directoryPath;
            }
        }
    }
}
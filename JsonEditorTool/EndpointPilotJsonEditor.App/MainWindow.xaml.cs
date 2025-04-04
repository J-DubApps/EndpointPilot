using System;
using System.Windows;
using System.Windows.Forms;
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
            var dialog = new FolderBrowserDialog
            {
                Description = "Select the directory containing EndpointPilot JSON files",
                ShowNewFolderButton = false
            };

            if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                _viewModel.WorkingDirectory = dialog.SelectedPath;
            }
        }
    }
}
using System.Windows;
using EndpointPilotJsonEditor.App.ViewModels;

namespace EndpointPilotJsonEditor.App.Views
{
    /// <summary>
    /// Interaction logic for CertificateSelectionDialog.xaml
    /// </summary>
    public partial class CertificateSelectionDialog : Window
    {
        public CertificateSelectionDialog()
        {
            InitializeComponent();
            DataContext = new CertificateSelectionViewModel();
            
            // Set up event handlers from ViewModel
            if (DataContext is CertificateSelectionViewModel viewModel)
            {
                viewModel.CloseDialog += (sender, result) => DialogResult = result;
            }
        }
    }
}
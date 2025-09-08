using System;
using System.Collections.ObjectModel;
using System.Security.Cryptography.X509Certificates;
using System.Windows.Input;
using EndpointPilotJsonEditor.Core.Services;

namespace EndpointPilotJsonEditor.App.ViewModels
{
    /// <summary>
    /// ViewModel for the certificate selection dialog
    /// </summary>
    public class CertificateSelectionViewModel : ViewModelBase
    {
        private readonly CryptographicService _cryptographicService;
        private X509Certificate2? _selectedCertificate;
        private bool _rememberSelection;
        private string _certificateStatusMessage;

        public CertificateSelectionViewModel()
        {
            _cryptographicService = new CryptographicService();
            _certificateStatusMessage = "Loading certificates...";
            
            // Initialize commands
            SelectCommand = new RelayCommand(ExecuteSelect, CanExecuteSelect);
            CancelCommand = new RelayCommand(ExecuteCancel);
            
            // Load available certificates
            LoadCertificates();
        }

        /// <summary>
        /// Event raised when the dialog should be closed
        /// </summary>
        public event EventHandler<bool>? CloseDialog;

        /// <summary>
        /// Gets the collection of available certificates
        /// </summary>
        public ObservableCollection<X509Certificate2> AvailableCertificates { get; } = new();

        /// <summary>
        /// Gets or sets the selected certificate
        /// </summary>
        public X509Certificate2? SelectedCertificate
        {
            get => _selectedCertificate;
            set
            {
                if (SetProperty(ref _selectedCertificate, value))
                {
                    ((RelayCommand)SelectCommand).RaiseCanExecuteChanged();
                }
            }
        }

        /// <summary>
        /// Gets or sets whether to remember the selection
        /// </summary>
        public bool RememberSelection
        {
            get => _rememberSelection;
            set => SetProperty(ref _rememberSelection, value);
        }

        /// <summary>
        /// Gets the status message for certificates
        /// </summary>
        public string CertificateStatusMessage
        {
            get => _certificateStatusMessage;
            private set => SetProperty(ref _certificateStatusMessage, value);
        }

        /// <summary>
        /// Gets the command to select a certificate
        /// </summary>
        public ICommand SelectCommand { get; }

        /// <summary>
        /// Gets the command to cancel the dialog
        /// </summary>
        public ICommand CancelCommand { get; }

        /// <summary>
        /// Loads available signing certificates
        /// </summary>
        private void LoadCertificates()
        {
            try
            {
                var certificates = _cryptographicService.GetAvailableSigningCertificates();
                
                AvailableCertificates.Clear();
                foreach (var cert in certificates)
                {
                    AvailableCertificates.Add(cert);
                }

                if (certificates.Count == 0)
                {
                    CertificateStatusMessage = "No code signing certificates found. Please install a code signing certificate.";
                }
                else
                {
                    CertificateStatusMessage = $"Found {certificates.Count} code signing certificate(s). Select one to sign your operations.";
                    
                    // Auto-select the first certificate if only one is available
                    if (certificates.Count == 1)
                    {
                        SelectedCertificate = certificates[0];
                    }
                }
            }
            catch (Exception ex)
            {
                CertificateStatusMessage = $"Error loading certificates: {ex.Message}";
            }
        }

        /// <summary>
        /// Determines if the select command can be executed
        /// </summary>
        /// <param name="parameter">Command parameter</param>
        /// <returns>True if a certificate is selected</returns>
        private bool CanExecuteSelect(object? parameter)
        {
            return SelectedCertificate != null;
        }

        /// <summary>
        /// Executes the select command
        /// </summary>
        /// <param name="parameter">Command parameter</param>
        private void ExecuteSelect(object? parameter)
        {
            if (SelectedCertificate != null)
            {
                // Store the selection preference if requested
                if (RememberSelection)
                {
                    // In a real application, you might store this in user settings
                    // For now, we'll just raise the event
                }

                CloseDialog?.Invoke(this, true);
            }
        }

        /// <summary>
        /// Executes the cancel command
        /// </summary>
        /// <param name="parameter">Command parameter</param>
        private void ExecuteCancel(object? parameter)
        {
            SelectedCertificate = null;
            CloseDialog?.Invoke(this, false);
        }
    }
}
using System.Windows.Controls;

namespace EndpointPilotJsonEditor.App.Views
{
    /// <summary>
    /// Interaction logic for DriveOpsEditorView.xaml
    /// </summary>
    public partial class DriveOpsEditorView : UserControl
    {
        /// <summary>
        /// Initializes a new instance of the DriveOpsEditorView class
        /// </summary>
        public DriveOpsEditorView()
        {
            InitializeComponent();
            
            // Set the header and subheader text
            BaseView.Header = "DRIVE-OPS.json Editor";
            BaseView.SubHeader = "Edit drive mapping operations for EndpointPilot";
        }
    }
}
using System.Windows.Controls;

namespace EndpointPilotJsonEditor.App.Views
{
    /// <summary>
    /// Interaction logic for FileOpsEditorView.xaml
    /// </summary>
    public partial class FileOpsEditorView : UserControl
    {
        /// <summary>
        /// Initializes a new instance of the FileOpsEditorView class
        /// </summary>
        public FileOpsEditorView()
        {
            InitializeComponent();
            
            // Set the header and subheader text
            BaseView.Header = "FILE-OPS.json Editor";
            BaseView.SubHeader = "Edit file operations for EndpointPilot";
        }
    }
}
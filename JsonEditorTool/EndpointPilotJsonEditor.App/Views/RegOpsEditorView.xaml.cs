using System.Windows.Controls;

namespace EndpointPilotJsonEditor.App.Views
{
    /// <summary>
    /// Interaction logic for RegOpsEditorView.xaml
    /// </summary>
    public partial class RegOpsEditorView : UserControl
    {
        /// <summary>
        /// Initializes a new instance of the RegOpsEditorView class
        /// </summary>
        public RegOpsEditorView()
        {
            InitializeComponent();
            
            // Set the header and subheader text
            BaseView.Header = "REG-OPS.json Editor";
            BaseView.SubHeader = "Edit registry operations for EndpointPilot";
        }
    }
}
using System.Windows;
using System.Windows.Controls;

namespace EndpointPilotJsonEditor.App.Views
{
    /// <summary>
    /// Interaction logic for OperationEditorViewBase.xaml
    /// </summary>
    public partial class OperationEditorViewBase : UserControl
    {
        /// <summary>
        /// Gets or sets the header text
        /// </summary>
        public string Header
        {
            get => HeaderText.Text;
            set => HeaderText.Text = value;
        }

        /// <summary>
        /// Gets or sets the subheader text
        /// </summary>
        public string SubHeader
        {
            get => SubHeaderText.Text;
            set => SubHeaderText.Text = value;
        }

        /// <summary>
        /// Gets or sets the details content
        /// </summary>
        public UIElement Details
        {
            get => DetailsContent.Content as UIElement;
            set => DetailsContent.Content = value;
        }

        /// <summary>
        /// Initializes a new instance of the OperationEditorViewBase class
        /// </summary>
        public OperationEditorViewBase()
        {
            InitializeComponent();
        }
    }
}
using System;
using System.Windows;

namespace EndpointPilotJsonEditor.App
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        /// <summary>
        /// Initializes a new instance of the App class
        /// </summary>
        public App()
        {
            // Set up global exception handling
            AppDomain.CurrentDomain.UnhandledException += (sender, args) =>
            {
                var exception = args.ExceptionObject as Exception;
                MessageBox.Show(
                    $"An unhandled exception occurred: {exception?.Message}\n\n{exception?.StackTrace}",
                    "Error",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            };

            // Set up UI exception handling
            DispatcherUnhandledException += (sender, args) =>
            {
                MessageBox.Show(
                    $"An unhandled exception occurred: {args.Exception.Message}\n\n{args.Exception.StackTrace}",
                    "Error",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                args.Handled = true;
            };
        }


        /// <summary>
        /// Raises the Startup event.
        /// </summary>
        /// <param name="e">A StartupEventArgs that contains the event data.</param>
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // Programmatically load Material Design resources
            try
            {
                var themeDictionary = new ResourceDictionary
                {
                    Source = new Uri("pack://application:,,,/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.xaml", UriKind.RelativeOrAbsolute)
                };
                var primaryColorDictionary = new ResourceDictionary
                {
                    Source = new Uri("pack://application:,,,/MaterialDesignColors;component/Themes/Recommended/Primary/MaterialDesignColor.DeepPurple.xaml", UriKind.RelativeOrAbsolute)
                };
                var accentColorDictionary = new ResourceDictionary
                {
                    Source = new Uri("pack://application:,,,/MaterialDesignColors;component/Themes/Recommended/Accent/MaterialDesignColor.Lime.xaml", UriKind.RelativeOrAbsolute)
                };

                // Ensure Application.Current.Resources is initialized if it's null
                if (Application.Current.Resources == null)
                {
                    Application.Current.Resources = new ResourceDictionary();
                }
                
                // Ensure MergedDictionaries is initialized
                if (Application.Current.Resources.MergedDictionaries == null)
                {
                    // This case is less likely but good to handle
                    // If Resources exists but MergedDictionaries is null, we might need to replace Resources
                    // or handle it based on specific application structure.
                    // For simplicity here, we assume if Resources exists, MergedDictionaries should too, 
                    // or we initialize Resources which includes MergedDictionaries.
                }

                Application.Current.Resources.MergedDictionaries.Add(themeDictionary);
                Application.Current.Resources.MergedDictionaries.Add(primaryColorDictionary);
                Application.Current.Resources.MergedDictionaries.Add(accentColorDictionary);
            }
            catch (Exception ex)
            {
                // Log or display the error if resource loading fails
                MessageBox.Show($"Failed to load Material Design resources: {ex.Message}", "Resource Loading Error", MessageBoxButton.OK, MessageBoxImage.Error);
                // Optionally shut down the application if resources are critical
                // Shutdown(); 
            }
        }
    }
}

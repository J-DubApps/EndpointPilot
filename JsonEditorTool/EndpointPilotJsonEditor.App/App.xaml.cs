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

            // Programmatically load Material Design resources using Application.LoadComponent
            try
            {
                 // Define URIs using the component path syntax
                Uri themeUri = new Uri("/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.xaml", UriKind.Relative);
                Uri primaryColorUri = new Uri("/MaterialDesignColors;component/Themes/Recommended/Primary/MaterialDesignColor.DeepPurple.xaml", UriKind.Relative);
                Uri accentColorUri = new Uri("/MaterialDesignColors;component/Themes/Recommended/Accent/MaterialDesignColor.Lime.xaml", UriKind.Relative);

                // Load dictionaries using Application.LoadComponent
                var themeDictionary = (ResourceDictionary)Application.LoadComponent(themeUri);
                var primaryColorDictionary = (ResourceDictionary)Application.LoadComponent(primaryColorUri);
                var accentColorDictionary = (ResourceDictionary)Application.LoadComponent(accentColorUri);


                // Ensure Application.Current.Resources is initialized if it's null
                if (Application.Current.Resources == null)
                {
                    Application.Current.Resources = new ResourceDictionary();
                }
                
                // Ensure MergedDictionaries is available (it should be if Resources was just initialized)
                if (Application.Current.Resources.MergedDictionaries == null)
                {
                     // If Resources existed but MergedDictionaries was somehow null, re-initialize Resources
                     // This is defensive coding for an unlikely scenario.
                     Application.Current.Resources = new ResourceDictionary();
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

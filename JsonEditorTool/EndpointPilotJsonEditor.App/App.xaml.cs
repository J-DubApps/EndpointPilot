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


        // Removed OnStartup override - resources will be loaded via App.xaml
    }
}

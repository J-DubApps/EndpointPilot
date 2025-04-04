using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace EndpointPilotJsonEditor.App.Converters
{
    /// <summary>
    /// Converts a boolean value to a color (red for true, black for false)
    /// </summary>
    public class BoolToColorConverter : IValueConverter
    {
        /// <summary>
        /// Converts a boolean value to a color
        /// </summary>
        /// <param name="value">The boolean value</param>
        /// <param name="targetType">The target type</param>
        /// <param name="parameter">The converter parameter</param>
        /// <param name="culture">The culture</param>
        /// <returns>Red for true, black for false</returns>
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isError)
            {
                return isError ? new SolidColorBrush(Colors.Red) : new SolidColorBrush(Colors.Black);
            }

            return new SolidColorBrush(Colors.Black);
        }

        /// <summary>
        /// Converts a color back to a boolean value (not implemented)
        /// </summary>
        /// <param name="value">The color value</param>
        /// <param name="targetType">The target type</param>
        /// <param name="parameter">The converter parameter</param>
        /// <param name="culture">The culture</param>
        /// <returns>Not implemented</returns>
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
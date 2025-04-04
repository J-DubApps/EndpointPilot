using System;
using System.Globalization;
using System.Windows.Data;

namespace EndpointPilotJsonEditor.App.Converters
{
    /// <summary>
    /// Converts a boolean value to its inverse (true to false, false to true)
    /// </summary>
    public class BoolToInvertedBoolConverter : IValueConverter
    {
        /// <summary>
        /// Converts a boolean value to its inverse
        /// </summary>
        /// <param name="value">The boolean value</param>
        /// <param name="targetType">The target type</param>
        /// <param name="parameter">The converter parameter</param>
        /// <param name="culture">The culture</param>
        /// <returns>The inverse of the boolean value</returns>
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return !boolValue;
            }

            return true;
        }

        /// <summary>
        /// Converts an inverted boolean value back to its original value
        /// </summary>
        /// <param name="value">The inverted boolean value</param>
        /// <param name="targetType">The target type</param>
        /// <param name="parameter">The converter parameter</param>
        /// <param name="culture">The culture</param>
        /// <returns>The original boolean value</returns>
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return !boolValue;
            }

            return false;
        }
    }
}
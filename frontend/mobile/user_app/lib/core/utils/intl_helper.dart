import 'package:intl/intl.dart';

// Helper function to format the ISO string
String formatIsoDate(String isoString) {
  if (isoString.isEmpty) return 'N/A';
  try {
    DateTime dateTime = DateTime.parse(isoString).toLocal();
    // Use 'dd MMM yyyy' for 07 May 2026
    // Use 'jm' for 12:00 PM
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  } catch (e) {
    return isoString; // Return raw string if parsing fails
  }
}
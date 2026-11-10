/// Formats city labels while keeping the original API values intact.
String formatCityName(String name) {
  return name.trim().toLowerCase().replaceAllMapped(
    RegExp(r'(^|[\s-])([^\s-])'),
    (match) => '${match[1]}${match[2]!.toUpperCase()}',
  );
}

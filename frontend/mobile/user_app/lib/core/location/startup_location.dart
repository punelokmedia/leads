import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StartupLocation {
  final Position? position;
  final String? locationName;
  final String? message;
  final bool needsSettings;
  const StartupLocation({
    this.position,
    this.locationName,
    this.message,
    this.needsSettings = false,
  });
}

// Kept for the app session: navigation never repeatedly asks for permission.
final startupLocationProvider = FutureProvider<StartupLocation>((ref) async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const StartupLocation(
        message: 'Allow location in app settings, or choose a city manually.',
        needsSettings: true,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return const StartupLocation(
        message:
            'Location access was declined. You can choose a city manually.',
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const StartupLocation(
        message:
            'Turn on device location, then retry, or choose a city manually.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    String? locationName;
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));
      if (places.isNotEmpty) {
        final place = places.first;
        final city = place.locality?.trim();
        final parts = [
          place.subLocality,
          city != null && city.isNotEmpty ? city : place.subAdministrativeArea,
          place.administrativeArea,
        ];
        final labels = <String>[];
        final seen = <String>{};
        for (final part in parts) {
          final label = part?.trim() ?? '';
          if (label.isNotEmpty && seen.add(label.toLowerCase())) {
            labels.add(label);
          }
        }
        if (labels.isEmpty && (place.country?.trim().isNotEmpty ?? false)) {
          labels.add(place.country!.trim());
        }
        if (labels.isNotEmpty) locationName = labels.join(', ');
      }
    } catch (_) {
      // A name lookup failure must not prevent GPS-based nearby searches.
    }
    return StartupLocation(position: position, locationName: locationName);
  } catch (_) {
    return const StartupLocation(
      message: 'Could not get your location. Retry or choose a city manually.',
    );
  }
});

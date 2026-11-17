import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/location/startup_location.dart';

class FakeGps extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission answer = LocationPermission.whileInUse;
  bool enabled = true;
  bool fail = false;
  int requests = 0;
  int captures = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return answer;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    captures++;
    if (fail) throw StateError('GPS unavailable');
    return Position(
      latitude: 18.5,
      longitude: 73.8,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

class FakeGeocoding extends GeocodingPlatform {
  bool fail = false;
  double? latitude;
  double? longitude;
  List<Placemark> places = const [
    Placemark(subLocality: 'Baner', locality: 'Pune', administrativeArea: 'Maharashtra'),
  ];

  @override
  Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude) async {
    this.latitude = latitude;
    this.longitude = longitude;
    if (fail) throw StateError('Geocoder unavailable');
    return places;
  }
}

void main() {
  late GeolocatorPlatform original;
  late FakeGps gps;
  late ProviderContainer container;
  GeocodingPlatform? originalGeocoding;
  late FakeGeocoding geocoding;
  setUp(() {
    original = GeolocatorPlatform.instance;
    gps = FakeGps();
    originalGeocoding = GeocodingPlatform.instance ?? FakeGeocoding();
    geocoding = FakeGeocoding();
    GeocodingPlatform.instance = geocoding;
    GeolocatorPlatform.instance = gps;
    container = ProviderContainer();
  });
  tearDown(() {
    container.dispose();
    GeolocatorPlatform.instance = original;
    GeocodingPlatform.instance = originalGeocoding;
  });

  test(
    'startup requests consent, captures GPS, and caches it during navigation',
    () async {
      final result = await container.read(startupLocationProvider.future);
      expect(result.position?.latitude, 18.5);
      expect(result.position?.longitude, 73.8);
      expect(result.locationName, 'Baner, Pune, Maharashtra');
      expect(geocoding.latitude, 18.5);
      expect(geocoding.longitude, 73.8);
      await container.read(startupLocationProvider.future);
      expect(gps.requests, 1);
      expect(gps.captures, 1);
    },
  );
  test('denied consent never captures coordinates', () async {
    gps.answer = LocationPermission.denied;
    final result = await container.read(startupLocationProvider.future);
    expect(result.position, isNull);
    expect(result.message, contains('declined'));
    expect(gps.captures, 0);
  });
  test('name lookup failure preserves coordinates and nearby search', () async {
    geocoding.fail = true;
    final result = await container.read(startupLocationProvider.future);
    expect(result.position, isNotNull);
    expect(result.locationName, isNull);
    expect(result.message, isNull);
  });
  test('empty address results preserve coordinates', () async {
    geocoding.places = [];
    final result = await container.read(startupLocationProvider.future);
    expect(result.position, isNotNull);
    expect(result.locationName, isNull);
  });
  test('address labels omit blanks and repeated names', () async {
    geocoding.places = const [Placemark(subLocality: ' Pune ', locality: 'Pune', administrativeArea: '')];
    expect((await container.read(startupLocationProvider.future)).locationName, 'Pune');
  });
  test('rural address falls back to district and state', () async {
    geocoding.places = const [Placemark(locality: '', subAdministrativeArea: 'Pune', administrativeArea: 'Maharashtra')];
    expect((await container.read(startupLocationProvider.future)).locationName, 'Pune, Maharashtra');
  });
  test(
    'permanently denied permission offers settings without another prompt',
    () async {
      gps.permission = LocationPermission.deniedForever;
      final result = await container.read(startupLocationProvider.future);
      expect(result.needsSettings, isTrue);
      expect(gps.requests, 0);
      expect(gps.captures, 0);
    },
  );
  test('disabled GPS allows manual city selection without capture', () async {
    gps.permission = LocationPermission.whileInUse;
    gps.enabled = false;
    final result = await container.read(startupLocationProvider.future);
    expect(result.message, contains('Turn on device location'));
    expect(gps.captures, 0);
  });
  test('capture failure remains recoverable through retry', () async {
    gps.fail = true;
    expect(
      (await container.read(startupLocationProvider.future)).position,
      isNull,
    );
    gps.fail = false;
    container.invalidate(startupLocationProvider);
    expect(
      (await container.read(startupLocationProvider.future)).position,
      isNotNull,
    );
  });
}

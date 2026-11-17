import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/location/startup_location.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/address/shared/address_providers.dart';

void main() {
  test('GPS fills missing address details and preserves typed fields', () async {
    final location = Completer<StartupLocation>();
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(Dio()),
      startupLocationProvider.overrideWith((ref) => location.future),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(addressControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(addressControllerProvider.notifier);
    controller.updateField(controller.data.copyWith(flatStreet: 'My flat'));
    location.complete(const StartupLocation(placemark: Placemark(
      street: 'Baner Road', subLocality: 'Baner', locality: 'Pune',
      administrativeArea: 'Maharashtra', postalCode: '411045',
    )));
    await container.read(startupLocationProvider.future);
    await Future<void>.delayed(Duration.zero);
    final address = container.read(addressDataProvider);
    expect(address.flatStreet, 'My flat');
    expect(address.landmark, 'Baner');
    expect(address.city, 'Pune');
    expect(address.state, 'Maharashtra');
    expect(address.zipcode, '411045');
  });
}

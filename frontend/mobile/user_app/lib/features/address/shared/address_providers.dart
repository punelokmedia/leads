// address/shared/address_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../domain/address_model.dart';
import '../infra/address_repository.dart';
import '../infra/address_controller.dart';
import '../../../core/location/startup_location.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(dioProvider)),
);

final addressControllerProvider =
    StateNotifierProvider.autoDispose<AddressController, AddressState>((ref) {
      final controller = AddressController(
        ref.watch(addressRepositoryProvider),
      );
      void fill(StartupLocation? location) {
        final place = location?.placemark;
        if (place == null) return;
        final current = controller.data;
        controller.updateField(
          current.copyWith(
            flatStreet: current.flatStreet.isEmpty
                ? place.street?.trim()
                : null,
            landmark: current.landmark.isEmpty
                ? place.subLocality?.trim()
                : null,
            city: current.city.isEmpty ? location!.cityName : null,
            state: current.state.isEmpty
                ? place.administrativeArea?.trim()
                : null,
            zipcode: current.zipcode.isEmpty ? place.postalCode?.trim() : null,
          ),
        );
      }

      fill(ref.read(startupLocationProvider).asData?.value);
      ref.listen(
        startupLocationProvider,
        (_, next) => fill(next.asData?.value),
      );
      return controller;
    });

// Convenience selectors
final addressDataProvider = Provider.autoDispose<AddressModel>(
  (ref) => ref.watch(addressControllerProvider).data,
);
final addressIsLoadingProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(addressControllerProvider).isLoading,
);
final addressErrorProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(addressControllerProvider).error,
);

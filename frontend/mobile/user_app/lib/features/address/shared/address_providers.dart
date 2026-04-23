// address/shared/address_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../domain/address_model.dart';
import '../infra/address_repository.dart';
import '../infra/address_controller.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(dioProvider)),
);

final addressControllerProvider =
    StateNotifierProvider.autoDispose<AddressController, AddressState>(
  (ref) => AddressController(ref.watch(addressRepositoryProvider)),
);

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
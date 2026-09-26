import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/infra/home_controller.dart';
import 'package:user_app/features/home/infra/home_repository.dart';

class _Repository implements IHomeRepository {
  final requests = <({String? city, String? categoryId})>[];
  final pending = <Completer<List<LeadModel>>>[];

  @override
  Future<List<LeadModel>> fetchLeads({String? city, String? categoryId}) {
    requests.add((city: city, categoryId: categoryId));
    final result = Completer<List<LeadModel>>();
    pending.add(result);
    return result.future;
  }

  @override
  Future<List<LeadModel>> searchLeads(String query) => fetchLeads();
}

void main() {
  test('category selection and clearing preserve the city filter', () async {
    final repository = _Repository();
    final controller = HomeController(repository);
    addTearDown(controller.dispose);
    var loading = controller.loadLeads(city: 'pune', categoryId: 'painting-id');
    repository.pending.last.complete([]);
    await loading;
    loading = controller.loadLeads(categoryId: '');
    expect(repository.requests.last, (city: 'pune', categoryId: ''));
    repository.pending.last.complete([]);
    await loading;
    expect(controller.state.selectedCategoryId, '');
    expect(controller.state.selectedCity, 'pune');
  });

  test('an earlier failed request cannot replace a newer selection', () async {
    final repository = _Repository();
    final controller = HomeController(repository);
    addTearDown(controller.dispose);
    final first = controller.loadLeads(categoryId: 'first');
    final second = controller.loadLeads(categoryId: 'second');
    repository.pending[1].complete([]);
    await second;
    repository.pending[0].completeError(Exception('old request failed'));
    await first;
    expect(controller.state.selectedCategoryId, 'second');
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.isLoading, isFalse);
  });
}

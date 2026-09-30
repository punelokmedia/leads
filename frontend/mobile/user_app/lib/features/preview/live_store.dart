import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_endpoints.dart';
import 'preview_data.dart';

/// API-backed state for the shared design. Never seeds preview fixtures.
class LiveStore extends PreviewStore {
  final Dio dio;
  final bool signedIn;
  LiveStore(this.dio, {required this.signedIn}) : super.empty();
  @override
  bool get isLive => true;
  @override
  List<PreviewCategory> get categories => _categories;
  List<PreviewCategory> _categories = [];
  @override
  List<String> get cities => _cities;
  List<String> _cities = [];
  bool loading = false;
  bool openingCheckout = false;
  String? error;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await dio.get(path, queryParameters: query);
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['success'] != true) throw StateError('Request failed');
    return data;
  }

  @override
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait([
        _get(ApiEndpoints.getAllCategories),
        _get(ApiEndpoints.getAllCities),
        if (signedIn) _get(ApiEndpoints.fetchProfile),
        if (signedIn) _get(ApiEndpoints.history),
      ]);
      final rawCategories = List<Map<String, dynamic>>.from(results[0]['data']);
      final rows = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final result = await _get(
          ApiEndpoints.getAllLeads,
          query: {'page': page, 'limit': 50},
        );
        rows.addAll(List<Map<String, dynamic>>.from(result['data']));
        final pages =
            (result['pagination']?['totalPages'] as num?)?.toInt() ?? 1;
        if (page++ >= pages) break;
      }
      // Fetch purchased contacts only through the server's ownership check.
      for (var i = 0; i < rows.length; i++) {
        if (rows[i]['isPurchased'] == true) {
          rows[i] = Map<String, dynamic>.from(
            (await _get('api/v1/leads/get-lead/${rows[i]['_id']}'))['data'],
          );
        }
      }
      if (_disposed) return;
      final ids = rawCategories.map((c) => c['_id'].toString()).toList();
      for (final row in rows) {
        final category = row['category'];
        final id = category is Map ? '${category['_id']}' : '$category';
        if (!ids.contains(id)) {
          ids.add(id);
          rawCategories.add({
            '_id': id,
            'name': category is Map ? category['name'] : 'Other',
          });
        }
      }
      final saved = leads.where((l) => l.saved).map((l) => l.backendId).toSet();
      final nextLeads = rows.map((row) {
        final category = row['category'];
        final id = category is Map ? '${category['_id']}' : '$category';
        final budget = row['budget'];
        final budgetMax = budget is Map
            ? (budget['max'] as num?)?.toInt() ?? 0
            : 0;
        final limit = (row['maxBuyers'] as num?)?.toInt() ?? 3;
        final expires = DateTime.tryParse('${row['expiresAt']}');
        final contact = [
          row['customerName'],
          row['primaryPhone'] ?? row['phone'],
          row['alternatePhone'],
          row['email'],
          row['address'],
        ].where((v) => v != null && v.toString().isNotEmpty).join('\n');
        return PreviewLead(
          id: '${row['leadDisplayId'] ?? row['_id']}',
          backendId: '${row['_id']}',
          title: '${row['title'] ?? ''}',
          category: ids.indexOf(id),
          city: '${row['city'] ?? ''}',
          state: '${row['state'] ?? ''}',
          budget: budgetMax,
          budgetLabel: '${row['budgetRange'] ?? ''}'.isNotEmpty
              ? row['budgetRange'].toString()
              : budgetMax == 0
              ? 'Not specified'
              : null,
          fee: row['price'] as num,
          description: '${row['description'] ?? ''}',
          buyers: (row['buyersCount'] as num?)?.toInt() ?? 0,
          maxBuyers: limit > 0 ? limit : 1,
          joined: row['isPurchased'] == true,
          saved: saved.contains('${row['_id']}'),
          backendStatus: expires != null && expires.isBefore(DateTime.now())
              ? 'EXPIRED'
              : '${row['status'] ?? 'ACTIVE'}',
          clientType: '${row['clientType'] ?? ''}',
          propertyType: '${row['propertyType'] ?? ''}',
          area: '${row['areaSize'] ?? ''}',
          timeline: '${row['timeline'] ?? ''}',
          start: '${row['preferredStartingDate'] ?? 'Not specified'}',
          contact: contact.isEmpty ? 'No contact details provided.' : contact,
        );
      }).toList();
      _categories = List.generate(rawCategories.length, (i) {
        final name = '${rawCategories[i]['name']}';
        final design = previewCategories
            .where((c) => c.name.toLowerCase() == name.toLowerCase())
            .firstOrNull;
        final fees =
            nextLeads.where((l) => l.category == i).map((l) => l.fee).toList()
              ..sort();
        return PreviewCategory(
          name,
          'See lead',
          fees.isEmpty ? 'No leads' : '₹${fees.first} – ₹${fees.last}',
          design?.icon ?? Icons.work_outline,
          design?.color ?? Colors.deepPurple,
        );
      });
      _cities = <String>{
        for (final city in results[1]['data'] as List)
          if (city['name'] != null) '${city['name']}',
        for (final lead in nextLeads) lead.city,
      }.where((s) => s.isNotEmpty).toList()..sort();
      leads = nextLeads;
      receipts.clear();
      if (signedIn) {
        _setProfile(Map<String, dynamic>.from(results[2]['data']));
        for (final order in results[3]['data'] as List) {
          receipts.add(
            PreviewReceipt(
              '${order['orderId']}',
              '${(order['items'] as List).length} lead(s)',
              order['totalAmount'] as num,
            ),
          );
        }
      }
    } catch (_) {
      if (!_disposed) {
        error =
            'Could not load data. Check your connection or sign in again, then retry.';
      }
    } finally {
      loading = false;
      _notify();
    }
  }

  void _setProfile(Map<String, dynamic> user) {
    profile = {
      'Full name': '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'
          .trim(),
      'Email': '${user['email'] ?? ''}',
      'Phone': '${user['phoneNumber'] ?? ''}',
      'Business name': '${user['businessName'] ?? ''}',
      'Service category': '${user['workType'] ?? ''}',
      'City': '${user['city'] ?? ''}',
      'State': '${user['state'] ?? user['address']?['state'] ?? ''}',
    };
  }

  @override
  Future<void> saveProfile(Map<String, String> details) async {
    final names = details['Full name']!.trim().split(RegExp(r'\s+'));
    final response = await dio.put(
      ApiEndpoints.editProfile,
      data: {
        'firstname': names.first,
        'lastname': names.skip(1).join(' '),
        'email': details['Email'],
        'phoneNumber': details['Phone'],
        'businessName': details['Business name'],
        'workType': details['Service category'],
        'city': details['City'],
        'state': details['State'],
      },
    );
    if (response.data['success'] != true) {
      throw StateError('Profile update failed');
    }
    if (_disposed) return;
    _setProfile(Map<String, dynamic>.from(response.data['data']));
    _notify();
  }

  @override
  bool purchase(PreviewLead lead) =>
      throw StateError('Live purchases require verified checkout');
  @override
  void reset() => throw StateError('Cannot seed a live store');
}

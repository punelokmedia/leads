import 'lead_filters_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/errors/error_handler.dart';
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
  List<PreviewLead>? filteredLeads;
  bool filtering = false;
  int _filterRequest = 0;
  final Set<String> _savedLeadIds = {};
  LeadFilters? _activeFilters;
  List<String> _categoryIds = [];
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
        _get(ApiEndpoints.getAllLeads, query: {'page': 1, 'limit': 50}),
      ]);
      final rawCategories = List<Map<String, dynamic>>.from(results[0]['data']);
      final rows = <Map<String, dynamic>>[];
      var page = 1;
      var result = results.last;
      while (true) {
        rows.addAll(List<Map<String, dynamic>>.from(result['data']));
        final pages =
            (result['pagination']?['totalPages'] as num?)?.toInt() ?? 1;
        if (page++ >= pages) break;
        if (_disposed) return;
        result = await _get(
          ApiEndpoints.getAllLeads,
          query: {'page': page, 'limit': 50},
        );
      }
      await _loadPurchased(rows);
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
      _categoryIds = ids;
      final nextLeads = rows.map((row) => _mapLead(row, ids, saved)).toList();
      _categories = List.generate(rawCategories.length, (i) {
        final name =
            '${rawCategories[i]['displayName'] ?? rawCategories[i]['name']}';
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
      if (_activeFilters != null) await applyFilters(_activeFilters!);
      receipts.clear();
      if (signedIn) {
        _setProfile(Map<String, dynamic>.from(results[2]['data']));
        for (final order in results[3]['data'] as List) {
          receipts.add(
            PreviewReceipt(
              '${order['orderId']}',
              '${(order['items'] as List).length} lead(s)',
              order['totalAmount'] as num,
              status: order['status'] == 'REFUND_PENDING'
                  ? 'Refund pending'
                  : order['status'] == 'REFUNDED'
                  ? 'Refunded'
                  : 'Paid',
            ),
          );
        }
      }
    } catch (failure) {
      if (!_disposed) {
        error = ErrorHandler.handle(failure).message;
      }
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _loadPurchased(
    List<Map<String, dynamic>> rows, {
    bool Function()? isCurrent,
  }) async {
    final indexes = [
      for (var i = 0; i < rows.length; i++)
        if (rows[i]['isPurchased'] == true) i,
    ];
    for (var start = 0; start < indexes.length; start += 4) {
      if (_disposed || (isCurrent != null && !isCurrent())) return;
      await Future.wait(
        indexes.skip(start).take(4).map((i) async {
          rows[i] = Map<String, dynamic>.from(
            (await _get('api/v1/leads/get-lead/${rows[i]['_id']}'))['data'],
          );
        }),
      );
    }
  }

  PreviewLead _mapLead(
    Map<String, dynamic> row,
    List<String> ids,
    Set<String> saved,
  ) {
    final category = row['category'];
    final id = category is Map ? '${category['_id']}' : '$category';
    final budget = row['budget'];
    final budgetMax = budget is Map ? (budget['max'] as num?)?.toInt() ?? 0 : 0;
    final limit = (row['maxBuyers'] as num?)?.toInt() ?? 2;
    final expires = DateTime.tryParse('${row['expiresAt']}');
    final contact = [
      row['customerName'],
      row['primaryPhone'] ?? row['phone'],
      row['alternatePhone'],
      row['email'],
      row['address'],
    ].where((v) => v != null && v.toString().isNotEmpty).join('\n');
    return PreviewLead(
      postedAt: DateTime.tryParse('${row['createdAt'] ?? ''}'),
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
      reservedSlots: (row['reservedSlots'] as num?)?.toInt() ?? 0,
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
  }

  Future<void> applyFilters(LeadFilters filters) async {
    final request = ++_filterRequest;
    filtering = true;
    _notify();
    final query = <String, dynamic>{
      if (filters.city != 'All Cities') 'city': filters.city,
      if (filters.category != null && filters.category! < _categoryIds.length)
        'category': _categoryIds[filters.category!],
      if (filters.minBudget != null) 'budgetMin': filters.minBudget,
      if (filters.maxBudget != null) 'budgetMax': filters.maxBudget,
      if (filters.minArea != null) 'areaMin': filters.minArea,
      if (filters.maxArea != null) 'areaMax': filters.maxArea,
      if (filters.timeline != null) 'timeline': filters.timeline,
      if (filters.postedDays != null)
        'postedSince': DateTime.now()
            .subtract(Duration(days: filters.postedDays!))
            .toUtc()
            .toIso8601String(),
    };
    try {
      _savedLeadIds.addAll(
        leads.where((lead) => lead.saved).map((lead) => lead.backendId),
      );
      final rows = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final result = await _get(
          ApiEndpoints.getAllLeads,
          query: {...query, 'page': page, 'limit': 50},
        );
        if (_disposed || request != _filterRequest) return;
        rows.addAll(List<Map<String, dynamic>>.from(result['data']));
        final pages =
            (result['pagination']?['totalPages'] as num?)?.toInt() ?? 1;
        if (page++ >= pages) break;
      }
      await _loadPurchased(rows, isCurrent: () => request == _filterRequest);
      if (_disposed || request != _filterRequest) return;
      _activeFilters = filters;
      filteredLeads = rows
          .map((row) => _mapLead(row, _categoryIds, _savedLeadIds))
          .toList();
    } finally {
      if (!_disposed && request == _filterRequest) {
        filtering = false;
        _notify();
      }
    }
  }

  @override
  void toggleSaved(PreviewLead lead) {
    lead.saved = !lead.saved;
    if (lead.saved) {
      _savedLeadIds.add(lead.backendId);
    } else {
      _savedLeadIds.remove(lead.backendId);
    }
    for (final item in leads) {
      if (item.backendId == lead.backendId) item.saved = lead.saved;
    }
    _notify();
  }

  void clearServerFilters() {
    _activeFilters = null;
    filteredLeads = null;
    ++_filterRequest;
    filtering = false;
  }

  void _setProfile(Map<String, dynamic> user) {
    serviceRadiusKm = (user['serviceRadiusKm'] as num?)?.toInt() ?? 25;
    additionalAreas = (user['additionalAreas'] as List? ?? [])
        .whereType<String>()
        .toList();
    final ids = (user['categories'] as List? ?? [])
        .map((value) => value is Map ? '${value['_id']}' : '$value')
        .toSet();
    serviceCategories = {
      for (var i = 0; i < _categoryIds.length; i++)
        if (ids.contains(_categoryIds[i])) _categories[i].name,
    };
    isProMember = user['registrationFeePaid'] == true;
    profile = {
      'Full name': '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'
          .trim(),
      'Email': '${user['email'] ?? ''}',
      'Phone': '${user['phoneNumber'] ?? ''}',
      'Business name': '${user['businessName'] ?? ''}',
      'Business type': '${user['businessType'] ?? ''}',
      'GST number': '${user['gstNumber'] ?? ''}',
      'Business address': '${user['businessAddress'] ?? ''}',
      'Service area': '${user['serviceArea'] ?? ''}',
      'Years in business': '${user['yearsInBusiness'] ?? ''}',
      'Website': '${user['website'] ?? ''}',
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
        if (details.containsKey('Business type'))
          'businessType': details['Business type'],
        if (details.containsKey('GST number'))
          'gstNumber': details['GST number'],
        if (details.containsKey('Business address'))
          'businessAddress': details['Business address'],
        if (details.containsKey('Service area'))
          'serviceArea': details['Service area'],
        if (details.containsKey('Years in business'))
          'yearsInBusiness': details['Years in business'],
        if (details.containsKey('Website')) 'website': details['Website'],
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
  Future<void> saveServiceCategories(Set<String> names) async {
    final indexes = names
        .map((name) => _categories.indexWhere((c) => c.name == name))
        .toList();
    if (indexes.any((i) => i < 0)) {
      throw StateError('Refresh the available categories and retry.');
    }
    final response = await dio.put(
      ApiEndpoints.editProfile,
      data: {'categories': indexes.map((i) => _categoryIds[i]).toList()},
    );
    if (response.data['success'] != true) {
      throw StateError('Category update failed');
    }
    if (_disposed) return;
    _setProfile(Map<String, dynamic>.from(response.data['data']));
    _notify();
  }

  @override
  Future<void> saveLocation(String city, int radius, List<String> areas) async {
    final response = await dio.put(
      ApiEndpoints.editProfile,
      data: {
        'city': city,
        if (city != profile['City']) 'state': '',
        'serviceRadiusKm': radius,
        'additionalAreas': areas,
      },
    );
    if (response.data['success'] != true) {
      throw StateError('Location update failed');
    }
    if (_disposed) return;
    _setProfile(Map<String, dynamic>.from(response.data['data']));
    _notify();
  }

  @override
  void send(String message) =>
      throw StateError('Live support requires the support API');
  @override
  bool purchase(PreviewLead lead) =>
      throw StateError('Live purchases require verified checkout');
  @override
  void reset() => throw StateError('Cannot seed a live store');
}

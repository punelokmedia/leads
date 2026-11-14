import 'package:flutter/material.dart';
import 'figma_widgets.dart';
import 'preview_data.dart';

class LeadFilters {
  final String city;
  final int? category;
  final int? minBudget, maxBudget, minArea, maxArea, postedDays;
  final String? timeline;
  final bool savedOnly;
  const LeadFilters({
    this.city = 'All Cities',
    this.category,
    this.minBudget,
    this.maxBudget,
    this.minArea,
    this.maxArea,
    this.timeline,
    this.postedDays,
    this.savedOnly = false,
  });

  bool matches(PreviewLead lead) {
    final area = num.tryParse(
      RegExp(r'[\d,]+').firstMatch(lead.area)?.group(0)?.replaceAll(',', '') ??
          '',
    );
    return (city == 'All Cities' ||
            lead.city.toLowerCase() == city.toLowerCase()) &&
        (category == null || lead.category == category) &&
        (!savedOnly || lead.saved) &&
        (minBudget == null || lead.budget >= minBudget!) &&
        (maxBudget == null || lead.budget <= maxBudget!) &&
        (minArea == null || area != null && area >= minArea!) &&
        (maxArea == null || area != null && area <= maxArea!) &&
        (timeline == null || lead.timeline == timeline) &&
        (postedDays == null ||
            lead.postedAt != null &&
                !lead.postedAt!.isBefore(
                  DateTime.now().subtract(Duration(days: postedDays!)),
                ));
  }
}

class LeadFiltersSheet extends StatefulWidget {
  final PreviewStore store;
  final LeadFilters initial;
  const LeadFiltersSheet({
    super.key,
    required this.store,
    required this.initial,
  });
  @override
  State<LeadFiltersSheet> createState() => _LeadFiltersSheetState();
}

class _LeadFiltersSheetState extends State<LeadFiltersSheet> {
  late String city = widget.initial.city;
  late int? category = widget.initial.category;
  late String? timeline = widget.initial.timeline;
  late int? postedDays = widget.initial.postedDays;
  late bool savedOnly = widget.initial.savedOnly;
  late final minBudget = TextEditingController(
    text: widget.initial.minBudget?.toString(),
  );
  late final maxBudget = TextEditingController(
    text: widget.initial.maxBudget?.toString(),
  );
  late final minArea = TextEditingController(
    text: widget.initial.minArea?.toString(),
  );
  late final maxArea = TextEditingController(
    text: widget.initial.maxArea?.toString(),
  );
  final location = TextEditingController();
  final categorySearch = TextEditingController();
  String? error;
  LeadFilters get value => LeadFilters(
    city: city,
    category: category,
    minBudget: int.tryParse(minBudget.text),
    maxBudget: int.tryParse(maxBudget.text),
    minArea: int.tryParse(minArea.text),
    maxArea: int.tryParse(maxArea.text),
    timeline: timeline,
    postedDays: postedDays,
    savedOnly: savedOnly,
  );

  List<String> get _visibleCities {
    final unique = <String, String>{};
    for (final name in widget.store.cities) {
      final label = name.trim();
      if (label.isNotEmpty && label.toLowerCase() != 'all cities') {
        unique.putIfAbsent(label.toLowerCase(), () => label);
      }
    }
    final query = location.text.trim().toLowerCase();
    final matches = unique.values
        .where((name) => name.toLowerCase().contains(query))
        .toList();
    if (query.isNotEmpty) return matches.take(3).toList();
    final selected = matches.where(
      (name) => name.toLowerCase() == city.toLowerCase(),
    );
    return {...selected, ...matches}.take(2).toList();
  }

  List<int> get _visibleCategories {
    final query = categorySearch.text.trim().toLowerCase();
    final unique = <String, int>{};
    for (var i = 0; i < widget.store.categories.length; i++) {
      final name = widget.store.categories[i].name.trim().toLowerCase();
      if (name.contains(query)) unique.putIfAbsent(name, () => i);
    }
    final matches = unique.values.toList();
    if (query.isNotEmpty) return matches.take(3).toList();
    return {
      if (category != null && matches.contains(category)) category!,
      ...matches,
    }.take(2).toList();
  }

  void reset() => setState(() {
    city = 'All Cities';
    category = null;
    timeline = null;
    postedDays = null;
    savedOnly = false;
    error = null;
    for (final c in [
      minBudget,
      maxBudget,
      minArea,
      maxArea,
      location,
      categorySearch,
    ]) {
      c.clear();
    }
  });
  @override
  void dispose() {
    for (final c in [
      minBudget,
      maxBudget,
      minArea,
      maxArea,
      location,
      categorySearch,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void apply() {
    final v = value;
    if ([minBudget, maxBudget, minArea, maxArea].any(
          (c) =>
              c.text.isNotEmpty &&
              (int.tryParse(c.text) == null || int.parse(c.text) < 0),
        ) ||
        (v.minBudget != null &&
            v.maxBudget != null &&
            v.minBudget! > v.maxBudget!) ||
        (v.minArea != null && v.maxArea != null && v.minArea! > v.maxArea!)) {
      setState(
        () => error = 'Enter valid ranges: minimum must not exceed maximum.',
      );
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: Material(
      color: figmaNavy,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: reset,
                    child: const Text(
                      '↻ Reset All',
                      style: TextStyle(color: Color(0xFF58A6FF)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close filters',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Service Category'),
                    TextField(
                      key: const ValueKey('category-search'),
                      controller: categorySearch,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: figmaInk, fontSize: 14),
                      decoration: _decoration('Search category...').copyWith(
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (categorySearch.text.trim().isEmpty)
                          _pill(
                            'All Categories',
                            category == null,
                            () => setState(() => category = null),
                          ),
                        for (final i in _visibleCategories)
                          _pill(
                            widget.store.categories[i].name,
                            category == i,
                            () => setState(() => category = i),
                          ),
                      ],
                    ),
                    if (_visibleCategories.isEmpty)
                      const Text(
                        'No matching categories',
                        style: TextStyle(color: Colors.white70),
                      ),
                    _title('Location'),
                    TextField(
                      key: const ValueKey('city-search'),
                      controller: location,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: figmaInk, fontSize: 14),
                      decoration: _decoration('Search city or area...')
                          .copyWith(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (location.text.trim().isEmpty)
                          _pill(
                            'All Cities',
                            city == 'All Cities',
                            () => setState(() => city = 'All Cities'),
                          ),
                        for (final c in _visibleCities)
                          _pill(
                            c,
                            city.toLowerCase() == c.toLowerCase(),
                            () => setState(() => city = c),
                          ),
                      ],
                    ),
                    if (_visibleCities.isEmpty)
                      const Text(
                        'No matching cities or locations',
                        style: TextStyle(color: Colors.white70),
                      ),
                    _title('Budget Range'),
                    _range(
                      minBudget,
                      maxBudget,
                      '₹ Min Budget',
                      '₹ Max Budget',
                    ),
                    _title('Project Area'),
                    _range(
                      minArea,
                      maxArea,
                      'Min Area (sq ft)',
                      'Max Area (sq ft)',
                    ),
                    _title('Project Timeline'),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _pill(
                          'Any',
                          timeline == null,
                          () => setState(() => timeline = null),
                        ),
                        ...widget.store.leads
                            .map((l) => l.timeline)
                            .where((t) => t.isNotEmpty)
                            .toSet()
                            .map(
                              (t) => _pill(
                                t,
                                timeline == t,
                                () => setState(() => timeline = t),
                              ),
                            ),
                      ],
                    ),
                    _title('Lead Posted Date'),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final entry in {
                          0: 'Any',
                          1: 'Last 24 Hours',
                          7: 'Last 7 Days',
                          30: 'Last 30 Days',
                        }.entries)
                          _pill(
                            entry.value,
                            (postedDays ?? 0) == entry.key,
                            () => setState(
                              () => postedDays = entry.key == 0
                                  ? null
                                  : entry.key,
                            ),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Saved leads only',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: savedOnly,
                      onChanged: (v) => setState(() => savedOnly = v),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFFFBBBB)),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: figmaBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        widget.store.isLive
                            ? 'Show Leads'
                            : 'Show Leads (${widget.store.leads.where(value.matches).length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: reset,
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(fontSize: 14, color: figmaBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  );
  Widget _pill(String text, bool selected, VoidCallback action) => ActionChip(
    label: Text(
      text,
      style: TextStyle(color: selected ? figmaBlue : figmaInk, fontSize: 14),
    ),
    onPressed: action,
    backgroundColor: selected ? const Color(0xFFE9F3FF) : Colors.white,
    side: BorderSide(color: selected ? figmaBlue : Colors.white),
    shape: const StadiumBorder(),
  );
  InputDecoration _decoration(String hint) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    isDense: true,
    hintStyle: const TextStyle(color: Color(0xFF9EB2DB), fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFF9EB2DB)),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
  );
  Widget _range(
    TextEditingController min,
    TextEditingController max,
    String a,
    String b,
  ) => Row(
    children: [
      for (final item in [(min, a), (max, b)])
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 7),
            child: TextField(
              controller: item.$1,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: figmaInk, fontSize: 14),
              cursorColor: figmaBlue,
              decoration: _decoration(item.$2),
            ),
          ),
        ),
    ],
  );
}
